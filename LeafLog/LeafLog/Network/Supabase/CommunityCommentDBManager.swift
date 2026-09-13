//
//  CommunityCommentDBManager.swift
//  LeafLog
//
//  Created by Yeseul Jang on 9/13/26.
//

import Dependencies
import Foundation
import Supabase

final class CommunityCommentDBManager {
    @Dependency(\.supabaseManager) private var supabaseManager
    
    func fetchComments(postID: UUID) async throws -> [CommunityComment] {
        do {
            return try await supabaseManager.client
                .from("community_comments")
                .select()
                .eq("post_id", value: postID)
                .is("deleted_at", value: nil)
                .order("created_at", ascending: true)
                .execute()
                .value
        } catch {
            throw AuthError.communityFailed(
                "댓글을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            )
        }
    }
    
    func createComment(
        postID: UUID,
        content: String
    ) async throws -> CommunityComment {
        do {
            let user = try await supabaseManager.client.auth.user()
            let payload = CommunityCommentCreatePayload(
                postID: postID,
                authorID: user.id,
                content: content
            )
            
            return try await supabaseManager.client
                .from("community_comments")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.communityFailed(
                "댓글을 작성하지 못했어요. 잠시 후 다시 시도해주세요."
            )
        }
    }
}

nonisolated private struct CommunityCommentCreatePayload: Encodable, Sendable {
    let postID: UUID
    let authorID: UUID
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case authorID = "author_id"
        case content
    }
}

extension CommunityCommentDBManager: DependencyKey {
    static var liveValue: CommunityCommentDBManager {
        CommunityCommentDBManager()
    }
}

extension DependencyValues {
    var communityCommentDBManager: CommunityCommentDBManager {
        get { self[CommunityCommentDBManager.self] }
        set { self[CommunityCommentDBManager.self] = newValue }
    }
}
