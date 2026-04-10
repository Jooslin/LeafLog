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
            try await Messaging.messaging().token()
        }
    }
}
