//
//  profileDBManager.swift
//  LeafLog
//
//  Created by 김주희 on 4/9/26.
//

import Foundation
import Supabase
import Dependencies

// MARK: - profiles 테이블 전용 DB 매니저
final class ProfileDBManager {

    @Dependency(\.supabaseManager) private var supabaseManager
    
    private static let defaultNickname = "익명의 식물 집사"

    private lazy var client = supabaseManager.client

    private init() {}

    
    // MARK: - DB에서 프로필 조회
    func fetchMyProfile() async throws -> UserProfileModel? {
        let user = try await client.auth.user() // 현재 로그인 한 유저
        return try await fetchMyProfile(user: user)
    }

    private func fetchMyProfile(user: User) async throws -> UserProfileModel? {
        let profiles: [StoredUserProfile] = try await client
            .from("profiles")
            .select() // 조회
            .eq("id", value: user.id)
            .limit(1)
            .execute()
            .value

        guard let profile = profiles.first else { return nil }

        // 앱 모델로 변환
        return try makeProfile(from: profile, user: user)
    }

    
    // MARK: - 프로필 없으면 만들고, 있으면 fetch
    func createProfileIfNeeded() async throws -> UserProfileModel {
        let user = try await client.auth.user()

        // 프로필 없음과 조회 실패를 구분하여 프로필이 존재할때는 그대로 return
        if let profile = try await fetchMyProfile(user: user) {
            return profile
        }
        
        // 없으므로 생성
        let payload = UserProfilePayload(
            id: user.id,
            nickname: Self.defaultNickname,
            email: user.email,
            provider: provider(from: user),
            profileImageURL: nil
        )

        let profile: StoredUserProfile = try await client
            .from("profiles")
            .upsert(payload)
            .select()
            .single()
            .execute()
            .value

        return try makeProfile(from: profile, user: user)
    }
    
    
    // MARK: - 프로필 업데이트(닉네임, 프사)
    func updateMyProfile(
        nickname: String,
        profileImageURL: String?
    ) async throws -> UserProfileModel {
        let user = try await client.auth.user()

        let payload = UserProfileUpdatePayload(
            // 닉네임이 공백이면 default값
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? Self.defaultNickname
                : nickname,
            profileImageURL: profileImageURL
        )

        // 서버에 수정 요청
        let profile: StoredUserProfile = try await client
            .from("profiles")
            .update(payload)
            .eq("id", value: user.id)
            .select()
            .single()
            .execute()
            .value

        return try makeProfile(from: profile, user: user)
    }

    // MARK: - 프로필 이미지 삭제
    func deleteMyProfileImage() async throws -> UserProfileModel {
        let user = try await client.auth.user()
        let payload = UserProfileImageDeletePayload()

        let profile: StoredUserProfile = try await client
            .from("profiles")
            .update(payload)
            .eq("id", value: user.id)
            .select()
            .single()
            .execute()
            .value

        return try makeProfile(from: profile, user: user)
    }

    
    // DB에서 부른 raw 데이터를 앱 Model로 변환
    private func makeProfile(from stored: StoredUserProfile, user: User) throws -> UserProfileModel {
        guard let provider = stored.provider ?? provider(from: user) else {
            throw AuthError.profileFailed("로그인 제공자 정보를 가져올 수 없어요.")
        }

        return UserProfileModel(
            id: stored.id,
            nickname: stored.nickname ?? Self.defaultNickname,
            email: stored.email ?? user.email,
            provider: provider,
            profileImageURL: stored.profileImageURL,
            createdAt: stored.createdAt,
            updatedAt: stored.updatedAt,
            isNotificationEnabled: stored.isNotificationEnabled
        )
    }

    // provider 추출
    private func provider(from user: User) -> String? {
        user.appMetadata["provider"]?.stringValue
    }
}


// DB 원본 응답 데이터
private struct StoredUserProfile: Codable {
    let id: UUID
    let nickname: String?
    let email: String?
    let provider: String?
    let profileImageURL: String?
    let createdAt: Date?
    let updatedAt: Date?
    let isNotificationEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id, nickname, email, provider
        case profileImageURL = "profile_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isNotificationEnabled = "is_notification_enabled"
    }
}

// 서버로 보내는 데이터 (생성)
private struct UserProfilePayload: Encodable {
    let id: UUID
    let nickname: String
    let email: String?
    let provider: String?
    let profileImageURL: String?

    enum CodingKeys: String, CodingKey {
        case id, nickname, email, provider
        case profileImageURL = "profile_image_url"
    }
}

// 서버로 보내는 데이터 (수정)
private struct UserProfileUpdatePayload: Encodable {
    let nickname: String
    let profileImageURL: String?

    enum CodingKeys: String, CodingKey {
        case nickname
        case profileImageURL = "profile_image_url"
    }
}

// 서버로 보내는 데이터 (프로필 이미지 삭제)
private struct UserProfileImageDeletePayload: Encodable {
    enum CodingKeys: String, CodingKey {
        case profileImageURL = "profile_image_url"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeNil(forKey: .profileImageURL)
    }
}

//MARK: Dependencies
extension ProfileDBManager: DependencyKey {
    static var liveValue: ProfileDBManager {
        ProfileDBManager()
    }
}

extension DependencyValues {
    var profileDBManager: ProfileDBManager {
        get { self[ProfileDBManager.self] }
        set { self[ProfileDBManager.self] = newValue }
    }
}
