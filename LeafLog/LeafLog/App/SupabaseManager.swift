//
//  SupabaseManager.swift
//  LeafLog
//
//  Created by 김주희 on 4/6/26.
//

import Foundation
import UIKit
import Supabase
import Dependencies
import OSLog

// 생성된 Signed URL을 메모리에 임시로 저장
private actor SignedImageURLMemoryCache {
    private struct Entry {
        let url: URL
        let expiresAt: Date // 만료시간
    }

    private var entries: [String: Entry] = [:]

    func url(for key: String) -> URL? {
        guard let entry = entries[key] else {
            return nil
        }

        guard entry.expiresAt > Date() else {
            entries[key] = nil
            return nil
        }

        return entry.url
    }

    func store(_ url: URL, for key: String, expiresAt: Date) {
        entries[key] = Entry(url: url, expiresAt: expiresAt)
    }
}

final class SupabaseManager {
    private let logger = Logger(subsystem: "LeafLog", category: "SupabaseManager")
    
    private init() {}
    private let signedImageURLCache = SignedImageURLMemoryCache()
    
    let client: SupabaseClient = {
        guard let supabaseURL = URL(string: "https://\(AppSecrets.supabaseURL)") else {
            fatalError("유효하지 않은 Supabase URL입니다.")
        }
        
        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: AppSecrets.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }()
}

extension SupabaseManager {
    private enum StorageBucket {
        static let profileImages = "profile-images"
        static let plantImages = "plant-images"
    }

    // 엣지케이스 방지
    private enum SignedURLCache {
        static let expiration = 60 * 60 // 서버에 요청할 유효기간
        static let lifetime: TimeInterval = 50 * 60 // 캐시에서 URL 유지하는 시간
    }

    // 프로필 이미지를 private bucket에 업로드하고, DB에는 storage path만 저장
    func uploadProfileImage(_ image: UIImage, userID: UUID) async throws -> String {
        let normalizedUserID = userID.uuidString.lowercased()
        let objectPath = "users/\(normalizedUserID)/profile.jpg"
        return try await uploadImage(
            image,
            bucket: StorageBucket.profileImages,
            objectPath: objectPath,
            conversionError: .profileFailed("프로필 이미지를 변환하지 못했어요.")
        )
    }
    
    // 식물 이미지를 private bucket에 업로드하고, DB에는 storage path만 저장
    func uploadPlantImage(_ image: UIImage, userID: UUID, plantID: UUID) async throws -> String {
        let normalizedUserID = userID.uuidString.lowercased()
        let normalizedPlantID = plantID.uuidString.lowercased()
        let objectPath = "users/\(normalizedUserID)/plants/\(normalizedPlantID)/main.jpg"
        return try await uploadImage(
            image,
            bucket: StorageBucket.plantImages,
            objectPath: objectPath,
            conversionError: .plantFailed("식물 이미지를 변환하지 못했어요.")
        )
    }
    
    // 일기 사진을 private bucket에 업로드하고, DB에는 storage path만 저장
    func uploadDiaryImage(_ image: UIImage, userID: UUID, plantID: UUID, recordDate: LocalDate) async throws -> String {
        let normalizedUserID = userID.uuidString.lowercased()
        let normalizedPlantID = plantID.uuidString.lowercased()
        let objectPath = "users/\(normalizedUserID)/plants/\(normalizedPlantID)/diaries/\(recordDate.rawValue).jpg"
        return try await uploadImage(
            image,
            bucket: StorageBucket.plantImages,
            objectPath: objectPath,
            conversionError: .careFailed("일기 사진을 변환하지 못했어요.")
        )
    }
    
    // DB에 저장된 프로필 이미지 값을 실제 접근 가능한 URL로 변환
    // private bucket path면 signed URL을 만들고, 기존 외부 URL은 그대로 사용
    func resolveProfileImageURL(from storedValue: String?, cacheKey: String? = nil) async throws -> URL? {
        try await resolveStoredImageURL(
            from: storedValue,
            bucket: StorageBucket.profileImages,
            cacheKey: cacheKey
        )
    }
    
    // DB에 저장된 식물 이미지 값을 실제 접근 가능한 URL로 변환
    func resolvePlantImageURL(from storedValue: String?, cacheKey: String? = nil) async throws -> URL? {
        try await resolveStoredImageURL(
            from: storedValue,
            bucket: StorageBucket.plantImages,
            cacheKey: cacheKey
        )
    }

    func resolveDiaryImageURL(from storedValue: String?, cacheKey: String? = nil) async throws -> URL? {
        try await resolveStoredImageURL(
            from: storedValue,
            bucket: StorageBucket.plantImages,
            cacheKey: cacheKey
        )
    }
    
    private func uploadImage(
        _ image: UIImage,
        bucket: String,
        objectPath: String,
        conversionError: AuthError
    ) async throws -> String {
        guard let fileData = image.jpegData(compressionQuality: 0.8) else {
            throw conversionError
        }
        
        _ = try await client.storage
            .from(bucket)
            .upload(
                path: objectPath,
                file: fileData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        return objectPath
    }

    // URL 변환 로직
    private func resolveStoredImageURL(from storedValue: String?, bucket: String, cacheKey: String?) async throws -> URL? {
        guard let storedValue = storedValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !storedValue.isEmpty else {
            return nil
        }
        
        if let directURL = URL(string: storedValue), directURL.scheme != nil {
            return directURL
        }

        // 유효한 URL이 존재하면 네트워크 요청없이 즉시 반환
        let resolvedCacheKey = "\(bucket):\(cacheKey ?? storedValue)"
        if let cachedURL = await signedImageURLCache.url(for: resolvedCacheKey) {
            return cachedURL
        }

        // 캐시 실패
        let signedURL = try await client.storage
            .from(bucket)
            .createSignedURL(path: storedValue, expiresIn: SignedURLCache.expiration)

        await signedImageURLCache.store(
            signedURL,
            for: resolvedCacheKey,
            expiresAt: Date().addingTimeInterval(SignedURLCache.lifetime)
        )

        return signedURL
    }
    
    // Storage에서 식물 이미지 삭제
    func deletePlantImage(path: String) async throws {
        try await client.storage
            .from(StorageBucket.plantImages)
            .remove(paths: [path])
    }
    
    // Storage에서 프로필 이미지 삭제
    func deleteProfileImage(path: String) async throws {
        try await client.storage
            .from(StorageBucket.profileImages)
            .remove(paths: [path])
    }
    
    // Storage에서 일기 사진 삭제
    func deleteDiaryImage(path: String) async throws {
        try await client.storage
            .from(StorageBucket.plantImages)
            .remove(paths: [path])
    }
}

//MARK: FCM 관련
extension SupabaseManager {
    // 현재 기기의 FCM 토큰을 user/device 단위로 저장
    func updateFCMToken(_ validToken: String) {
        Task {
            do {
                guard let currentUserId = client.auth.currentUser?.id else { return } // 현재 로그인 된 유저 정보
                guard let deviceID = UIDevice.current.identifierForVendor?.uuidString.lowercased() else { return } // 기기 정보
                
                let payload = DeviceTokenPayload(
                    userID: currentUserId,
                    fcmToken: validToken,
                    deviceID: deviceID,
                    lastSeenAt: Date(),
                    isActive: true
                )
                
                try await client
                    .from("device_tokens")
                    .upsert(payload, onConflict: "user_id,device_id")
                    .execute()
            } catch {
                logger.error("⚠️ 디바이스 토큰 저장 보류(로그인 전이거나 네트워크 에러)\nerror: \(error.localizedDescription, privacy: .private)")
            }
        }
    }
    
    // 유저 알림 허용 여부 업데이트
    func updateIsNotificationEnabled(_ isEnabled: Bool) async throws {
        // 현재 로그인된 유저의 정보(세션)를 가져옴
        guard let currentUserId = client.auth.currentUser?.id else { return } // nil값인 경우 빠른 종료
        
        // profiles 테이블에서 현재 유저의 행을 찾아 알림 허용 여부(is_notification_enabled) 값을 덮어씌움
        try await client
            .from("profiles")
            .update(["is_notification_enabled": isEnabled])
            .eq("id", value: currentUserId)
            .execute()
    }
    
    private struct DeviceTokenPayload: Encodable {
        let userID: UUID
        let fcmToken: String
        let deviceID: String
        let lastSeenAt: Date
        let isActive: Bool
        
        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case fcmToken = "fcm_token"
            case deviceID = "device_id"
            case lastSeenAt = "last_seen_at"
            case isActive = "is_active"
        }
    }
}



//MARK: Dependencies
extension SupabaseManager: DependencyKey {
    static var liveValue: SupabaseManager {
        SupabaseManager()
    }
}

extension DependencyValues {
    var supabaseManager: SupabaseManager {
        get { self[SupabaseManager.self] }
        set { self[SupabaseManager.self] = newValue }
    }
}
