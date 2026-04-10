//
//  profileDBManager.swift
//  LeafLog
//
//  Created by 김주희 on 4/9/26.
//

import Foundation
import Supabase

// MARK: - profiles 테이블 전용 DB 매니저
final class ProfileDBManager {
    static let shared = ProfileDBManager()
    private static let defaultNickname = "익명의 식물 집사"

    private let client = SupabaseManager.shared.client

    private init() {}

    
    // MARK: - DB에서 프로필 조회
    func fetchMyProfile() async throws -> UserProfileModel {
        let user = try await client.auth.user() // 현재 로그인 한 유저
        let profile: StoredUserProfile = try await client
            .from("profiles")
            .select() // 조회
            .eq("id", value: user.id)
            .single()
            .execute()
            .value

        // 앱 모델로 변환
        return try makeProfile(from: profile, user: user)
    }

    
    // MARK: - 프로필 없으면 만들고, 있으면 fetch
    func createProfileIfNeeded() async throws -> UserProfileModel {
        let user = try await client.auth.user()

        // 프로필이 존재하면 fetch
        if let profile = try? await fetchMyProfile() {
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
            updatedAt: stored.updatedAt
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

    enum CodingKeys: String, CodingKey {
        case id, nickname, email, provider
        case profileImageURL = "profile_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
