//
//  CommunityViewController.swift
//  LeafLog
//
//  Created by 김주희 on 8/19/26.
//

import ReactorKit
import RxCocoa
import UIKit

final class CommunityViewController: BaseViewController, View {
    private let communityView = CommunityView()

    override func loadView() {
        view = communityView
    }

    override func viewDidLoad() {
        maximumDynamicTypeCategory = .accessibilityLarge
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    func bind(reactor: CommunityReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }

    private func bindAction(reactor: CommunityReactor) {
        rx.viewWillAppear
            .map { _ in CommunityReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(.leafLogRemoteNotificationReceived)
            .map { _ in CommunityReactor.Action.remoteNotificationReceived }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(.leafLogNotificationReadStateChanged)
            .map { _ in CommunityReactor.Action.refreshUnreadNotificationState }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        communityView.rx.categorySelected
            .map(CommunityReactor.Action.selectCategory)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        communityView.rx.refresh
            .map { CommunityReactor.Action.refresh }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        communityView.rx.writeButtonTap
            .map { AppStep.communityComposeCreate }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }

    private func bindState(reactor: CommunityReactor) {
        reactor.state
            .map {
                (
                    $0.posts,
                    $0.authorNicknames,
                    $0.authorProfileImageURLs,
                    $0.postImageURLs
                )
            }
            .asDriver(onErrorDriveWith: .empty())
            .drive {
                [weak self] posts,
                authorNicknames,
                authorProfileImageURLs,
                postImageURLs in
                self?.communityView.render(
                    posts: posts,
                    authorNicknames: authorNicknames,
                    authorProfileImageURLs: authorProfileImageURLs,
                    postImageURLs: postImageURLs
                )
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.selectedCategory)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] category in
                self?.communityView.selectCategory(category)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.hasUnreadNotification)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] hasUnreadNotification in
                self?.communityView.configureAlarmButton(
                    hasUnreadNotification: hasUnreadNotification
                )
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.isRefreshing)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] isRefreshing in
                self?.communityView.setRefreshing(isRefreshing)
            }
            .disposed(by: disposeBag)

        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] message in
                self?.steps.accept(AppStep.alert("오류", message))
            }
            .disposed(by: disposeBag)
    }
}
