//
//  NotificationManager.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/9/26.
//

import UserNotifications
import Dependencies
import OSLog

final class NotificationManager {
    @Dependency(\.supabaseManager)private var supabaseManager
    let center = UNUserNotificationCenter.current()
    private let logger = Logger.init(subsystem: "LeafLog", category: "NotificationManager")
    
    // 앱 알림 권한 요청 함수
    func requestNotificationAuthorization() {
        
        // 앱 실행 시 사용자에게 알림 허용 권한 받기
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        center.requestAuthorization(options: authOptions) { [weak self] granted, error in
            if let error {
                self?.logger.error("알림 권한 요청 시 오류 발생: \(error.localizedDescription, privacy: .private)")
                return
            }
            
            // 알림 권한 허용 여부에 따라 저장
            if granted {
                self?.updateIsNotificationEnabled(to: true)
            } else {
                self?.updateIsNotificationEnabled(to: false)
            }
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
    
    // 알림 허용 여부 업데이트
    func updateIsNotificationEnabled(to isEnabled: Bool?) {
        Task { [weak self] in
            guard let self else { return }
            
            var target: Bool = false
            
            if let isEnabled {
                target = isEnabled
            } else {
                target = await self.checkNotificationEnabled()
            }
            
            let isChanged = updateUserDefaultsIsNotificationEnabled(to: target)
            
            guard isChanged else { return } // UserDefaults가 업데이트 되었을 경우에만 DB 업데이트
            
            do {
                try await supabaseManager.updateIsNotificationEnabled(target)
            } catch {
                self.logger.error("알림 허용 여부 저장 시 오류 발생: \(error.localizedDescription, privacy: .private)")
                return
            }
        }
    }
    
    private func updateUserDefaultsIsNotificationEnabled(to isEnabled: Bool) -> Bool {
        let userDefaults = UserDefaults.standard
        let key = "isNotificationEnabled"
        
        // 저장된 값이 없을 경우 값 저장 후 리턴
        if userDefaults.object(forKey: key) == nil {
            UserDefaults.standard.set(isEnabled, forKey: key)
            return true
        }
        
        let current = UserDefaults.standard.bool(forKey: key)
        
        // 현재 값이 저장된 값과 다를 경우에만 업데이트
        if current != isEnabled {
            UserDefaults.standard.set(isEnabled, forKey: key)
            return true
        } else {
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
