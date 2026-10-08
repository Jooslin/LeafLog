//
//  NotificationManager.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/9/26.
//

import UserNotifications
import Dependencies
import OSLog
import Supabase

final class NotificationManager {
    @Dependency(\.supabaseManager)private var supabaseManager
    let center = UNUserNotificationCenter.current()
    private let logger = Logger.init(subsystem: "LeafLog", category: "NotificationManager")
    
    // 앱 알림 권한 요청 함수
    func requestNotificationAuthorization() {
        
        // 앱 실행 시 사용자에게 알림 허용 권한 받기
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        center.requestAuthorization(options: authOptions) { [weak self] _, error in
            if let error {
                self?.logger.error("알림 권한 요청 시 오류 발생: \(error.localizedDescription, privacy: .private)")
                return
            }
            
            // 알림 권한 허용 여부에 따라 저장
            Task {
                do {
                    try await self?.syncCurrentDeviceNotificationAuthorization()
                } catch {
                    self?.logger.error("알림 허용 여부 저장 시 오류 발생: \(error.localizedDescription, privacy: .private)")
                }
            }
        }
    }
    
    // 앱 알림 권한 허용 여부 확인 함수
    func checkNotificationEnabled() async -> Bool {
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        default:
            return false
        }
    }
    
    // 알림 허용 여부 업데이트
    // 변예린: 앱 활성화와 권한 요청에서는 현재 로그인한 사용자의 기기 설정을 동기화한다.
    @discardableResult
    func syncCurrentDeviceNotificationAuthorization() async throws -> Bool? {
        guard let userId = self.supabaseManager.client.auth.currentUser?.id else {
            throw NotificationError.userIDNotFound
        }

        return try await syncCurrentDeviceNotificationAuthorization(for: userId)
    }

    // 변예린: 토큰 등록을 기다리는 동안 계정이 바뀌어도 등록을 시작한 사용자 ID로 확인해 다른 계정에 저장하지 않는다.
    func syncCurrentDeviceNotificationAuthorization(for userId: UUID) async throws -> Bool? {
        var isAuthorized = await checkNotificationEnabled()
        while true {
            let didSync = try await supabaseManager.syncCurrentDeviceNotificationAuthorization(isAuthorized, for: userId)
            guard didSync else { return nil }

            let latestAuthorization = await checkNotificationEnabled()
            if latestAuthorization == isAuthorized { return isAuthorized }
            isAuthorized = latestAuthorization
        }
    }
}

extension NotificationManager {
    enum NotificationError: Error {
        case userIDNotFound
        case authorizationDenied
    }
}

//MARK: Dependencies
extension NotificationManager: DependencyKey {
    static var liveValue: NotificationManager {
        NotificationManager()
    }
}

extension DependencyValues {
    var notificationManager: NotificationManager {
        get { self[NotificationManager.self] }
        set { self[NotificationManager.self] = newValue }
    }
}
