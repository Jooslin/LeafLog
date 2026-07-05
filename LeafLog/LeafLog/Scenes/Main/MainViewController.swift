//
//  MainViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/10/26.
//

import UIKit
import Dependencies
import FirebaseMessaging
import OSLog

final class MainViewController: UITabBarController {
    @Dependency(\.notificationManager) private var notificationManager
    private let logger = Logger(subsystem: "LeafLog", category: "MainViewController")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationManager.requestNotificationAuthorization()
        
        Task {
            do {
                try await Messaging.messaging().token()
            } catch {
                logger.error("FCM 토큰 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }
}
