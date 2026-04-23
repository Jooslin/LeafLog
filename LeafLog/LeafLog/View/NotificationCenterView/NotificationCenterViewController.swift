//
//  NotificationCenterViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/23/26.
//

import UIKit
import ReactorKit

final class NotificationCenterViewController: BaseViewController, View {
    private let notificationCenterView = NotificationCenterView()
    
    override func loadView() {
        view = notificationCenterView
    }
    
    func bind(reactor: NotificationCenterReactor) {
        bindAction(reactor: reactor)
    }
    
    private func bindAction(reactor: NotificationCenterReactor) {
        
    }
    
    private func bindState(reactor: NotificationCenterReactor) {
        
    }
}
