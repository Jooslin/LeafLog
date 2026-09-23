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
    
    func fetchComments(
        postID: UUID,
        limit: Int = 20,
        cursor: CommunityCommentCursor? = nil
    ) async throws -> [CommunityComment] {
        guard limit > 0 else {
            throw AuthError.communityFailed("댓글 조회 범위를 확인해주세요.")
        }
        
        do {
            var query = supabaseManager.client
                .from("community_comments")
                .select()
                .eq("post_id", value: postID)
                .is("deleted_at", value: nil)
            
            if let cursor {
                let createdAt = Self.cursorDateFormatter.string(from: cursor.createdAt)
                query = query.or(
                    "created_at.lt.\(createdAt),and(created_at.eq.\(createdAt),id.lt.\(cursor.id.uuidString))"
                )
            }
            
            return try await query
                .order("created_at", ascending: false)
                .order("id", ascending: false)
                .limit(limit)
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
    
    func softDeleteComment(id: UUID) async throws {
        do {
            try await supabaseManager.client
                .rpc(
                    "soft_delete_community_comment",
                    params: CommunityCommentDeleteParameters(commentID: id)
                )
                .execute()
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.communityFailed(
                "댓글을 삭제하지 못했어요. 잠시 후 다시 시도해주세요."
            )
        }
    }
    
    func updateComment(
        id: UUID,
        content: String
    ) async throws {
        do {
            try await supabaseManager.client
                .rpc(
                    "update_community_comment",
                    params: CommunityCommentUpdateParameters(
                        commentID: id,
                        content: content
                    )
                )
                .execute()
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.communityFailed(
                "댓글을 수정하지 못했어요. 잠시 후 다시 시도해주세요."
            )
        }
    }
}

private extension CommunityCommentDBManager {
    static let cursorDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        return formatter
    }()
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

nonisolated private struct CommunityCommentDeleteParameters: Encodable, Sendable {
    let commentID: UUID
    
    enum CodingKeys: String, CodingKey {
        case commentID = "p_comment_id"
    }
}

nonisolated private struct CommunityCommentUpdateParameters: Encodable, Sendable {
    let commentID: UUID
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case commentID = "p_comment_id"
        case content = "p_content"
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
