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
    
    func requestNotificationAuthorization() {
        // 앱 실행 시 사용자에게 알림 허용 권한 받기
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        center.requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
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
