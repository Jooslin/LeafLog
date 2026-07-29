//
//  CommunityPostDBManager.swift
//  LeafLog
//
//  Created by OpenAI Codex on 7/29/26.
//

import Dependencies
import Foundation
import Supabase

final class CommunityPostDBManager {
    @Dependency(\.supabaseManager) private var supabaseManager

    private init() {}

    func createPost(input: CommunityPostSaveInput) async throws -> CommunityPost {
        try await savePost(function: "create_community_post", input: input)
    }

    func updatePost(input: CommunityPostSaveInput) async throws -> CommunityPost {
        try await savePost(function: "update_community_post", input: input)
    }

    private func savePost(
        function: String,
        input: CommunityPostSaveInput
    ) async throws -> CommunityPost {
        let parameters = try makeParameters(input: input)

        do {
            let response: CommunityPostRPCResponse = try await supabaseManager.client
                .rpc(function, params: parameters)
                .execute()
                .value

            return try makeCommunityPost(response: response)
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
        let title = input.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let isContentEmpty = input.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        guard !title.isEmpty else {
            throw AuthError.communityFailed("제목을 입력해주세요.")
        }

        guard title.count <= 50 else {
            throw AuthError.communityFailed("제목은 최대 50자까지 입력할 수 있어요.")
        }

        guard !isContentEmpty else {
            throw AuthError.communityFailed("내용을 입력해주세요.")
        }

        guard input.content.count <= 1_000 else {
            throw AuthError.communityFailed("내용은 최대 1,000자까지 입력할 수 있어요.")
        }

        guard input.images.count <= 3 else {
            throw AuthError.communityFailed("사진은 최대 3장까지 첨부할 수 있어요.")
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
            title: title,
            content: input.content,
            images: imagePayloads
        )
    }

    private func makeCommunityPost(
        response: CommunityPostRPCResponse
    ) throws -> CommunityPost {
        guard let category = PostCategory(
            databaseValue: response.post.category
        ) else {
            throw AuthError.communityFailed(
                "게시글 카테고리 정보를 확인해주세요."
            )
        }

        return CommunityPost(
            id: response.post.id,
            authorID: response.post.authorID,
            category: category,
            title: response.post.title,
            content: response.post.content,
            legacyImagePath: response.post.legacyImagePath,
            createdAt: response.post.createdAt,
            updatedAt: response.post.updatedAt,
            deletedAt: response.post.deletedAt,
            likeCount: response.post.likeCount,
            images: response.images
        )
    }

}

nonisolated private struct CommunityPostRPCResponse: Decodable, Sendable {
    let post: StoredCommunityPost
    let images: [CommunityPostImage]
}

nonisolated private struct StoredCommunityPost: Decodable, Sendable {
    let id: UUID
    let authorID: UUID
    let category: String
    let title: String
    let content: String
    let legacyImagePath: String?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let likeCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case authorID = "author_id"
        case category
        case title
        case content
        case legacyImagePath = "image_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case likeCount = "like_count"
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
