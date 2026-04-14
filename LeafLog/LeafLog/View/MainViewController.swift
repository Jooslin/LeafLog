//
//  MainViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/10/26.
//

import UIKit
import Dependencies
import FirebaseMessaging

final class MainViewController: UITabBarController {
    @Dependency(\.notificationManager) private var notificationManager
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationManager.requestNotificationAuthorization()
        
        Task {
            do {
                try await Messaging.messaging().token()
            } catch {
                print("FCM 토큰 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }
}
