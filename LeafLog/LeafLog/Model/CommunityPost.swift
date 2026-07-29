//
//  CommunityPost.swift
//  LeafLog
//
//  Created by OpenAI Codex on 7/29/26.
//

import Foundation

struct CommunityPost: Hashable {
    let id: UUID
    let authorID: UUID
    let category: PostCategory
    let title: String
    let content: String
    let legacyImagePath: String?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let likeCount: Int
    let images: [CommunityPostImage]

}

struct CommunityPostImage: Codable, Hashable {
    let id: UUID
    let postID: UUID
    let imagePath: String
    let sortOrder: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case postID = "post_id"
        case imagePath = "image_path"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}

struct CommunityPostImageInput: Hashable {
    let id: UUID
    let imagePath: String
}

struct CommunityPostSaveInput {
    let id: UUID
    let category: PostCategory
    let title: String
    let content: String
    let images: [CommunityPostImageInput]
}
