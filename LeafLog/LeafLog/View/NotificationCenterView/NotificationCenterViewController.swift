//
//  NotificationCenterViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/23/26.
//

import UIKit
import ReactorKit
import RxCocoa

final class NotificationCenterViewController: BaseViewController, View {
    private let notificationCenterView = NotificationCenterView()
    
    override func loadView() {
        view = notificationCenterView
    }
    
    func bind(reactor: NotificationCenterReactor) {
        bindAction(reactor: reactor)
    }
    
    private func bindAction(reactor: NotificationCenterReactor) {
        self.rx.viewWillAppear
            .map { _ in NotificationCenterReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: NotificationCenterReactor) {
        reactor.state
            .map(\.alarmItem)
            .subscribe(onNext: { [weak self] items in
                self?.notificationCenterView.setSnapshot(items)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("에러", message))
            })
            .disposed(by: disposeBag)
    }
}
