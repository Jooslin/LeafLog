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
    }
}
