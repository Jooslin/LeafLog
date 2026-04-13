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

final class SupabaseManager {
    private init() {}
    
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

    // 프로필 이미지를 private bucket에 업로드하고, DB에는 storage path만 저장
    func uploadProfileImage(_ image: UIImage, userID: UUID) async throws -> String {
        let objectPath = "users/\(userID.uuidString)/profile.jpg"
        return try await uploadImage(
            image,
            bucket: StorageBucket.profileImages,
            objectPath: objectPath,
            conversionError: .profileFailed("프로필 이미지를 변환하지 못했어요.")
        )
    }

    // 식물 이미지를 private bucket에 업로드하고, DB에는 storage path만 저장
    func uploadPlantImage(_ image: UIImage, userID: UUID, plantID: UUID) async throws -> String {
        let objectPath = "users/\(userID.uuidString)/plants/\(plantID.uuidString)/main.jpg"
        return try await uploadImage(
            image,
            bucket: StorageBucket.plantImages,
            objectPath: objectPath,
            conversionError: .plantFailed("식물 이미지를 변환하지 못했어요.")
        )
    }

    // DB에 저장된 프로필 이미지 값을 실제 접근 가능한 URL로 변환
    // private bucket path면 signed URL을 만들고, 기존 외부 URL은 그대로 사용
    func resolveProfileImageURL(from storedValue: String?) async throws -> URL? {
        try await resolveStoredImageURL(from: storedValue, bucket: StorageBucket.profileImages)
    }

    // DB에 저장된 식물 이미지 값을 실제 접근 가능한 URL로 변환
    func resolvePlantImageURL(from storedValue: String?) async throws -> URL? {
        try await resolveStoredImageURL(from: storedValue, bucket: StorageBucket.plantImages)
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

    private func resolveStoredImageURL(from storedValue: String?, bucket: String) async throws -> URL? {
        guard let storedValue, !storedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        if let directURL = URL(string: storedValue), directURL.scheme != nil {
            return directURL
        }

        return try await client.storage
            .from(bucket)
            .createSignedURL(path: storedValue, expiresIn: 60 * 60)
    }

    // 유저 fcm 토큰 업데이트
    func updateFCMToken(_ validToken: String) {
        // Supabase 서버로 토큰 쏴주기
        Task {
            do {
                // 현재 로그인된 유저의 정보 가져오기
                guard let currentUserId = client.auth.currentUser?.id else { return } // nil값인 경우 빠른 종료
                
                // profiles 테이블에서 현재 유저의 행을 찾아 fcm_token 값을 덮어씌움
                try await client
                    .from("profiles")
                    .update(["fcm_token": validToken])
                    .eq("id", value: currentUserId)
                    .execute()
                
                print("✅ Supabase DB에 FCM 토큰이 성공적으로 저장되었습니다.")
                
            } catch {
                // 앱을 처음 켜서 아직 로그인이 안 된 경우 - 앱을 멈추거나 유저에게 에러를 알릴 필요가 없으므로 print문으로만 출력
                print("⚠️ FCM 토큰 저장 보류 (로그인 전이거나 네트워크 에러): \(error.localizedDescription)")
            }
        }
    }
    
    // 유저 알림 허용 여부 업데이트
    func updateIsNotificationEnabled(_ isEnabled: Bool) {
        Task {
            do {
                // 현재 로그인된 유저의 정보(세션)를 가져옴
                guard let currentUserId = client.auth.currentUser?.id else { return } // nil값인 경우 빠른 종료
                
                // profiles 테이블에서 현재 유저의 행을 찾아 알림 허용 여부(is_notification_enabled) 값을 덮어씌움
                try await client
                    .from("profiles")
                    .update(["is_notification_enabled": isEnabled])
                    .eq("id", value: currentUserId)
                    .execute()
                
                print("✅ Supabase DB에 알림 허용 여부가 성공적으로 저장되었습니다.")
                
            } catch {
                // 앱을 처음 켜서 아직 로그인이 안 된 경우 - 앱을 멈추거나 유저에게 에러를 알릴 필요가 없으므로 print문으로만 출력
                print("⚠️ 알림 허용 여부 저장 보류 (로그인 전이거나 네트워크 에러): \(error.localizedDescription)")
            }
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
