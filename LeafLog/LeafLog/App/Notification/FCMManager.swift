//
//  FCMManager.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/9/26.
//

import Dependencies
import UserNotifications
import FirebaseMessaging
import Auth
import Supabase

final class FCMManager: NSObject {

    @Dependency(\.notificationManager) private var notificationManager
    @Dependency(\.supabaseManager) private var supabaseManager
    
    func setConfigs() {
        notificationManager.center.delegate = self
        Messaging.messaging().delegate = self
    }
}

extension FCMManager: UNUserNotificationCenterDelegate {
    // Foreground에서 알림이 오는 설정
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner])
    }

    // 사용자가 푸시를 탭했을 때 payload를 앱 내부에서 재사용할 수 있는 모델로 보관한다.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let content = response.notification.request.content
        notificationManager.handleOpenedRemoteNotification(
            userInfo: content.userInfo,
            fallbackTitle: content.title,
            fallbackBody: content.body
        )
    }
}

extension FCMManager: MessagingDelegate {
    // 파이어베이스 MessagingDelegate 설정 - 앱 시작 시, 혹은 토큰이 갱신되었을 때 호출되는 함수
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // 전달받은 토큰이 정상적으로 있는지 확인
        guard let validToken = fcmToken else { return }
        supabaseManager.updateFCMToken(validToken)
    }
}

//MARK: Dependencies
extension FCMManager: DependencyKey {
    static var liveValue: FCMManager {
        FCMManager()
    }
}

extension DependencyValues {
    var fcmManager: FCMManager {
        get { self[FCMManager.self] }
        set { self[FCMManager.self] = newValue }
    }
}
