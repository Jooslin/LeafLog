//
//  NotificationManager.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/9/26.
//

import UserNotifications
import Dependencies

final class NotificationManager {
    let center = UNUserNotificationCenter.current()
    
    // 앱 알림 권한 요청 함수
    func requestNotificationAuthorization() {
        // 앱 실행 시 사용자에게 알림 허용 권한 받기
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        center.requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
    }
    
    // 앱 알림 허용 여부 확인 함수
    func checkNotificationEnabled() async -> Bool {
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        default:
            return false
        }
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
