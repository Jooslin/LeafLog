//
//  CommunityPostDBManager.swift
//  LeafLog
//
//  Created by OpenAI Codex on 7/29/26.
//

import Dependencies
import Foundation
import OSLog
import Supabase

final class CommunityPostDBManager {
    @Dependency(\.supabaseManager) private var supabaseManager
    private let logger = Logger(subsystem: "LeafLog", category: "CommunityPostDBManager")

    func createPost(input: CommunityPostSaveInput) async throws -> CommunityPost {
        try await savePost(function: "create_community_post", input: input)
    }

    func updatePost(input: CommunityPostSaveInput) async throws -> CommunityPost {
        try await savePost(function: "update_community_post", input: input)
    }

    func fetchPosts(
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [CommunityPost] {
        guard limit > 0, offset >= 0 else {
            throw AuthError.communityFailed("게시글 조회 범위를 확인해주세요.")
        }

        do {
            return try await supabaseManager.client
                .from("community_posts")
                .select("*, images:community_post_images(*)")
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .order(
                    "sort_order",
                    ascending: true,
                    referencedTable: "images"
                )
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
        } catch {
            throw AuthError.communityFailed(
                "게시글을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            )
        }
    }
    
    func fetchPost(id: UUID) async throws -> CommunityPost {
        do {
            return try await supabaseManager.client
                .from("community_posts")
                .select("*, images:community_post_images(*)")
                .eq("id", value: id)
                .is("deleted_at", value: nil)
                .order(
                    "sort_order",
                    ascending: true,
                    referencedTable: "images"
                )
                .single()
                .execute()
                .value
        } catch {
            throw AuthError.communityFailed(
                "게시글을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            )
        }
    }

    func fetchPublicProfiles(
        authorIDs: [UUID]
    ) async throws -> [UUID: CommunityPublicProfile] {
        let uniqueAuthorIDs = Array(Set(authorIDs))
        guard !uniqueAuthorIDs.isEmpty else { return [:] }

        do {
            let profiles: [CommunityPublicProfile] = try await supabaseManager.client
                .rpc(
                    "get_community_public_profiles",
                    params: CommunityPublicProfilesRPCParameters(
                        userIDs: uniqueAuthorIDs
                    )
                )
                .execute()
                .value

            return Dictionary(
                uniqueKeysWithValues: profiles.map { ($0.id, $0) }
            )
        } catch {
            logger.error(
                "Community public profile RPC failed: \(String(describing: error), privacy: .private)"
            )
            throw AuthError.communityFailed(
                "작성자 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            )
        }
    }

    func resolvePublicProfileImageURLs(
        profiles: [UUID: CommunityPublicProfile]
    ) async -> [UUID: URL] {
        var imageURLs: [UUID: URL] = [:]

        for profile in profiles.values {
            guard let storedValue = profile.profileImageURL else { continue }

            do {
                if let imageURL = try await supabaseManager.resolveProfileImageURL(
                    from: storedValue,
                    cacheKey: profile.id.uuidString
                ) {
                    imageURLs[profile.id] = imageURL
                }
            } catch {
                logger.error(
                    "Profile image URL resolution failed. userID: \(profile.id.uuidString, privacy: .public), error: \(String(describing: error), privacy: .private)"
                )
            }
        }

        return imageURLs
    }

    func fetchMyPosts(
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [CommunityPost] {
        guard limit > 0, offset >= 0 else {
            throw AuthError.communityFailed("게시글 조회 범위를 확인해주세요.")
        }

        do {
            let user = try await supabaseManager.client.auth.user()

            return try await supabaseManager.client
                .from("community_posts")
                .select("*, images:community_post_images(*)")
                .eq("author_id", value: user.id)
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .order(
                    "sort_order",
                    ascending: true,
                    referencedTable: "images"
                )
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.communityFailed(
                "작성한 게시글을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            )
        }
    }

    private func savePost(
        function: String,
        input: CommunityPostSaveInput
    ) async throws -> CommunityPost {
        let parameters = try makeParameters(input: input)

        do {
            return try await supabaseManager.client
                .rpc(function, params: parameters)
                .execute()
                .value
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.communityFailed(
                "게시글을 저장하지 못했어요. 잠시 후 다시 시도해주세요."
            )
        }
    }

    private func makeParameters(
        input: CommunityPostSaveInput
    ) throws -> CommunityPostRPCParameters {
        let validatedText: (title: String, content: String)
        switch CommunityPostValidation.validate(
            title: input.title,
            content: input.content
        ) {
        case let .valid(title, content):
            validatedText = (title, content)
        case let .invalid(message):
            throw AuthError.communityFailed(message)
        }

        let uniqueImageIDs = Set(input.images.map(\.id))
        let uniqueImagePaths = Set(input.images.map(\.imagePath))
        guard
            uniqueImageIDs.count == input.images.count,
            uniqueImagePaths.count == input.images.count,
            input.images.allSatisfy({ !$0.imagePath.isEmpty })
        else {
            throw AuthError.communityFailed("첨부한 사진 정보를 확인해주세요.")
        }

        let imagePayloads = input.images.enumerated().map { index, image in
            CommunityPostImagePayload(
                id: image.id,
                imagePath: image.imagePath,
                sortOrder: index
            )
        }

        return CommunityPostRPCParameters(
            postID: input.id,
            category: input.category.databaseValue,
            title: validatedText.title,
            content: validatedText.content,
            images: imagePayloads
        )
    }

}

nonisolated struct CommunityPublicProfile: Decodable, Sendable {
    let id: UUID
    let nickname: String?
    let profileImageURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case profileImageURL = "profile_image_url"
    }
}

nonisolated private struct CommunityPublicProfilesRPCParameters: Encodable, Sendable {
    let userIDs: [UUID]

    enum CodingKeys: String, CodingKey {
        case userIDs = "p_user_ids"
    }
}

nonisolated private struct CommunityPostRPCParameters: Encodable, Sendable {
    let postID: UUID
    let category: String
    let title: String
    let content: String
    let images: [CommunityPostImagePayload]

    enum CodingKeys: String, CodingKey {
        case postID = "p_post_id"
        case category = "p_category"
        case title = "p_title"
        case content = "p_content"
        case images = "p_images"
    }
}

nonisolated private struct CommunityPostImagePayload: Encodable, Sendable {
    let id: UUID
    let imagePath: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case imagePath = "image_path"
        case sortOrder = "sort_order"
    }
}

extension CommunityPostDBManager: DependencyKey {
    static var liveValue: CommunityPostDBManager {
        CommunityPostDBManager()
    }
}

extension DependencyValues {
    var communityPostDBManager: CommunityPostDBManager {
        get { self[CommunityPostDBManager.self] }
        set { self[CommunityPostDBManager.self] = newValue }
    }
}
