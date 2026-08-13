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
    
    override func viewDidLoad() {
        maximumDynamicTypeCategory = .accessibilityLarge // 다이나믹 폰트 최대 크기 설정
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true             
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func bind(reactor: NotificationCenterReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: NotificationCenterReactor) {
        self.rx.viewWillAppear
            .map { _ in NotificationCenterReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        Observable.merge(
            // 앱이 백그라운드 상태에서 다시 foreground로 진입했을 경우
            NotificationCenter.default.rx.notification(
                UIApplication.didBecomeActiveNotification
            )
            .map { _ in },
            // FCM을 통해 푸시 알림을 받았을 경우
            NotificationCenter.default.rx.notification(
                .leafLogRemoteNotificationReceived
            )
            .map { _ in }
        )
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { NotificationCenterReactor.Action.refresh }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        notificationCenterView.categorySegment.rx.selectedSegmentIndex
            .skip(1)
            .distinctUntilChanged()
            .map {
                NotificationCenterReactor.Action.categorySelected($0)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        notificationCenterView.rx.backButtonTap
            .map { _ in AppStep.alarmPageBack(reactor.currentState.category) }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: NotificationCenterReactor) {
        reactor.state
            .skip(1)
            .map { state -> (category: AppNotificationCategory, items: [NotificationCenterView.Item]) in
                (category: state.category, items: state.alarmItem)
            }
            .withUnretained(notificationCenterView)
            .subscribe(onNext: { view, value in
                let category = value.category
                let items = value.items

                switch category {
                case .management:
                    view.managementEmptyView.isHidden = !items.isEmpty
                case .community:
                    view.communityEmptyView.isHidden = !items.isEmpty
                }

                view.setSnapshot(items)
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.category.rawValue)
            .distinctUntilChanged()
            .bind(to: notificationCenterView.categorySegment.rx.selectedSegmentIndex)
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] message in
                self?.notificationCenterView.categorySegment.selectedSegmentIndex = reactor.currentState.category.rawValue // 기존 선택 카테고리로 변경
                self?.steps.accept(AppStep.alert("에러", message))
            })
            .disposed(by: disposeBag)
    }
}

//MARK: Preview
@available(iOS 17.0, *)
#Preview {
  NotificationCenterViewController()
}
