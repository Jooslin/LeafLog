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
    private let userDefaultsBaseKey = "isNotificationEnabled"
    
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
            Task {
                do {
                    if granted {
                        try await self?.updateIsNotificationEnabled(to: true)
                    } else {
                        try await self?.updateIsNotificationEnabled(to: false)
                    }
                } catch {
                    self?.logger.error("알림 허용 여부 저장 시 오류 발생: \(error.localizedDescription, privacy: .private)")
                }
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
    func updateIsNotificationEnabled(to isEnabled: Bool?) async throws {
        guard let userId = self.supabaseManager.client.auth.currentUser?.id else { return }
        
        var target: Bool = false
        
        if let isEnabled {
            target = isEnabled
        } else {
            target = await self.checkNotificationEnabled()
        }
        
        let willUpdate = checkUserDefaultsWouldUpdate(to: target, user: userId)
        guard willUpdate else { return } // UserDefaults가 업데이트될 경우
        
        try await supabaseManager.updateIsNotificationEnabled(target) // DB 업데이트
        updateUserDefaultsIsNotificationEnabled(to: target, user: userId) // UserDefaults 업데이트
    }
    
    // UserDefaults 업데이트 여부
    private func checkUserDefaultsWouldUpdate(to isEnabled: Bool, user: UUID) -> Bool {
        let userDefaults = UserDefaults.standard
        let key = userDefaultsBaseKey + user.uuidString
        // 기존에 저장된 값이 없을 경우
        if userDefaults.object(forKey: key) == nil {
            return true
        }
        
        let current = userDefaults.bool(forKey: key)
        
        return current != isEnabled
    }
    
    // UserDefaults 업데이트
    private func updateUserDefaultsIsNotificationEnabled(to isEnabled: Bool, user: UUID) {
        let userDefaults = UserDefaults.standard
        let key = userDefaultsBaseKey + user.uuidString
        
        userDefaults.set(isEnabled, forKey: key)
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
