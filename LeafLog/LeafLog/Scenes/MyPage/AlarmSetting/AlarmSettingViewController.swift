//
//  AlarmSettingViewController.swift
//  LeafLog
//
//  Created by 변예린 on 10/7/26.
//

import Dependencies
import OSLog
import RxCocoa
import RxSwift
import UIKit

final class AlarmSettingViewController: BaseViewController {
    private let settingView = AlarmSettingDetailView()
    
    override func loadView() {
        view = settingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    func bind(reactor: MyPageReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: MyPageReactor) {
        settingView.titleView.backButton.rx.tap
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: MyPageReactor) {
        
    }
}
