//
//  CommunityComment.swift
//  LeafLog
//
//  Created by Yeseul Jang on 9/13/26.
//

import Foundation

nonisolated struct CommunityComment: Codable, Hashable, Sendable {
    let id: UUID
    let postID: UUID
    let authorID: UUID
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case postID = "post_id"
        case authorID = "author_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}
