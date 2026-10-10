//
//  NotificationDBManager.swift
//  LeafLog
//
//  Created by OpenAI Codex on 4/23/26.
//

import Foundation
import Supabase
import Dependencies

final class NotificationDBManager {
    @Dependency(\.supabaseManager) private var supabaseManager
    private let dateFormatter = ISO8601DateFormatter()
    
    private init() {}

    // 알림센터 진입 시 최신 알림부터 목록을 가져온다.
    func fetchMyNotifications(limit: Int = 100, category: AppNotificationCategory) async throws -> [AppNotification] {
        let user = try await supabaseManager.client.auth.user()

        do {
            var query = supabaseManager.client
                .from("notifications")
                .select()
                .eq("user_id", value: user.id)
                .eq("category", value: category.rawValue)

            if category == .management {
                query = query.not("sent_at", operator: .is, value: "null")
            }

            return try await query
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            }

            throw AuthError.notificationFailed("알림 목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요.")
        }
    }

    func fetchCommunityNotificationGroups(notificationIDs: [UUID]) async throws -> [UUID: CommunityNotificationGroup] {
        let uniqueIDs = Array(Set(notificationIDs))
        guard !uniqueIDs.isEmpty else { return [:] }

        do {
            let groups: [CommunityNotificationGroup] = try await supabaseManager.client
                .from("community_notification_groups")
                .select("notification_id, first_actor_nickname, participant_ids")
                .in("notification_id", values: uniqueIDs)
                .execute()
                .value

            return Dictionary(uniqueKeysWithValues: groups.map { ($0.notificationID, $0) })
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            }

            throw AuthError.notificationFailed("알림 목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요.")
        }
    }

    func hasUnreadNotifications() async throws -> Bool {
        struct NotificationID: Decodable {
            let id: UUID
        }

        let user = try await supabaseManager.client.auth.user()

        do {
            let notifications: [NotificationID] = try await supabaseManager.client
                .from("notifications")
                .select("id")
                .eq("user_id", value: user.id)
                .or("category.eq.community,sent_at.not.is.null")
                .is("read_at", value: nil)
                .limit(1)
                .execute()
                .value

            return !notifications.isEmpty
        } catch {
            throw AuthError.notificationFailed("미확인 알림 상태를 불러오지 못했어요. 잠시 후 다시 시도해주세요.")
        }
    }

    func markAsRead(notificationID: UUID) async throws {
        let user = try await supabaseManager.client.auth.user()

        do {
            try await supabaseManager.client
                .from("notifications")
                .update(["read_at": dateFormatter.string(from: Date())])
                .eq("id", value: notificationID)
                .eq("user_id", value: user.id)
                .execute()
        } catch {
            throw AuthError.notificationFailed("알림 상태를 업데이트하지 못했어요. 잠시 후 다시 시도해주세요.")
        }
    }

    func markAllAsRead(category: AppNotificationCategory) async throws {
        let user = try await supabaseManager.client.auth.user()

        do {
            var query = try supabaseManager.client
                .from("notifications")
                .update(["read_at": dateFormatter.string(from: Date())])
                .eq("user_id", value: user.id)
                .eq("category", value: category.rawValue)
                .is("read_at", value: nil)

            if category == .management {
                query = query.not("sent_at", operator: .is, value: "null")
            }

            try await query.execute()
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            }
            
            throw AuthError.notificationFailed("알림 전체 읽음 처리를 완료하지 못했어요. 잠시 후 다시 시도해주세요.")
        }
    }
}

// MARK: - Dependencies
extension NotificationDBManager: DependencyKey {
    static var liveValue: NotificationDBManager { NotificationDBManager() }
}

extension DependencyValues {
    var notificationDBManager: NotificationDBManager {
        get { self[NotificationDBManager.self] }
        set { self[NotificationDBManager.self] = newValue }
    }
}
