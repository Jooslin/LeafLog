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
    func fetchMyNotifications(limit: Int = 100) async throws -> [AppNotification] {
        let user = try await supabaseManager.client.auth.user()

        do {
            return try await supabaseManager.client
                .from("notifications")
                .select()
                .eq("user_id", value: user.id)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
        } catch {
            throw AuthError.notificationFailed("알림 목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요.")
        }
    }

    func markAsRead(notificationID: UUID) async throws {
        do {
            try await supabaseManager.client
                .from("notifications")
                .update(["read_at": dateFormatter.string(from: Date())])
                .eq("id", value: notificationID)
                .execute()
        } catch {
            throw AuthError.notificationFailed("알림 상태를 업데이트하지 못했어요. 잠시 후 다시 시도해주세요.")
        }
    }

    func markAllAsRead() async throws {
        let user = try await supabaseManager.client.auth.user()

        do {
            try await supabaseManager.client
                .from("notifications")
                .update(["read_at": dateFormatter.string(from: Date())])
                .eq("user_id", value: user.id)
                .is("read_at", value: nil)
                .execute()
        } catch {
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
