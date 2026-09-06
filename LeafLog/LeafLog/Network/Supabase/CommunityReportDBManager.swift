//
//  CommunityReportDBManager.swift
//  LeafLog
//
//  Created by Yeseul Jang on 9/6/26.
//

import Dependencies
import Foundation
import Supabase

final class CommunityReportDBManager {
    @Dependency(\.supabaseManager) private var supabaseManager
    
    func reportPost(
        postID: UUID,
        reportedUserID: UUID,
        reason: CommunityReportReason
    ) async throws {
        do {
            let user = try await supabaseManager.client.auth.user()
            let payload = CommunityReportPostPayload(
                reporterID: user.id,
                postID: postID,
                reportedUserID: reportedUserID,
                reason: reason.rawValue
            )
            
            try await supabaseManager.client
                .from("community_reports")
                .insert(payload)
                .execute()
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.communityFailed(
                "신고를 접수하지 못했어요. 잠시 후 다시 시도해주세요."
            )
        }
    }
    
    func reportMember(
        reportedUserID: UUID,
        reason: CommunityReportReason
    ) async throws {
        do {
            let user = try await supabaseManager.client.auth.user()
            let payload = CommunityReportMemberPayload(
                reporterID: user.id,
                reportedUserID: reportedUserID,
                reason: reason.rawValue
            )
            
            try await supabaseManager.client
                .from("community_reports")
                .insert(payload)
                .execute()
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.communityFailed(
                "신고를 접수하지 못했어요. 잠시 후 다시 시도해주세요."
            )
        }
    }
}

nonisolated private struct CommunityReportPostPayload: Encodable, Sendable {
    let reporterID: UUID
    let postID: UUID
    let reportedUserID: UUID
    let reason: String
    let targetType = "post"
    
    enum CodingKeys: String, CodingKey {
        case reporterID = "reporter_id"
        case postID = "post_id"
        case reportedUserID = "reported_user_id"
        case reason
        case targetType = "target_type"
    }
}

nonisolated private struct CommunityReportMemberPayload: Encodable, Sendable {
    let reporterID: UUID
    let reportedUserID: UUID
    let reason: String
    let targetType = "member"
    
    enum CodingKeys: String, CodingKey {
        case reporterID = "reporter_id"
        case reportedUserID = "reported_user_id"
        case reason
        case targetType = "target_type"
    }
}

extension CommunityReportDBManager: DependencyKey {
    static var liveValue: CommunityReportDBManager {
        CommunityReportDBManager()
    }
}

extension DependencyValues {
    var communityReportDBManager: CommunityReportDBManager {
        get { self[CommunityReportDBManager.self] }
        set { self[CommunityReportDBManager.self] = newValue }
    }
}
