//
//  AlarmSettingViewController.swift
//  LeafLog
//
//  Created by 변예린 on 10/7/26.
//

import Dependencies
import OSLog
import ReactorKit
import RxCocoa
import RxSwift
import UIKit

final class AlarmSettingViewController: BaseViewController, View {
    private let settingView = AlarmSettingView()
    
    override func loadView() {
        view = settingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    func bind(reactor: AlarmSettingReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: AlarmSettingReactor) {
        rx.viewWillAppear
            .map { _ in AlarmSettingReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .filter { [weak self] _ in self?.isViewLoaded == true && self?.view.window != nil }
            .map { _ in AlarmSettingReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        settingView.settingChanged
            .map { AlarmSettingReactor.Action.settingChanged($0.0, $0.1) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        settingView.titleView.backButton.rx.tap
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: AlarmSettingReactor) {
        reactor.state
            .map(\.settings)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] settings in
                self?.settingView.setSnapshot(settings)
            })
            .disposed(by: disposeBag)

        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("오류", message))
            })
            .disposed(by: disposeBag)
    }
}
