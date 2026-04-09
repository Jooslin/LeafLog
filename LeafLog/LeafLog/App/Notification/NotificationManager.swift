//
//  NotificationManager.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/9/26.
//

import UserNotifications
import Dependencies

final class NotificationManager {
    @Dependency(\.supabaseManager)private var supabaseManager
    let center = UNUserNotificationCenter.current()
    
    // 앱 알림 권한 요청 함수
    func requestNotificationAuthorization() {
        // 앱 실행 시 사용자에게 알림 허용 권한 받기
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        center.requestAuthorization(options: authOptions) { [weak self] granted, error in
            //TODO: 에러 처리 함수 필요
            
            // 앱 알림 권한 요청 결과에 따라 supabase에 알림 허용 여부 업데이트
            self?.supabaseManager.updateIsNotificationEnabled(granted)
        }
    }
    
    // 앱 알림 권한 허용 여부 확인 함수
    private func checkNotificationEnabled() async -> Bool {
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        default:
            return false
        }
    }
    
    //TODO: 마이페이지 알림 허용 여부와 비교하여 업데이트하는 로직 필요
    func updateIsNotificationEnabled() {
        Task {
            let isEnabled = await checkNotificationEnabled()
            supabaseManager.updateIsNotificationEnabled(isEnabled)
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
