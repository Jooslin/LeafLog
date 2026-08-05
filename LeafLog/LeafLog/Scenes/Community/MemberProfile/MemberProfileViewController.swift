//
//  MemberProfileViewController.swift
//  LeafLog
//
//  Created by Yeseul Jang on 8/5/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

final class MemberProfileViewController: BaseViewController, View {
    private let profileView = MemberProfileView()
    private var profile: MemberProfileReactor.Profile?
    private var posts: [MemberProfileReactor.Post] = []
    
    override func loadView() {
        view = profileView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = MemberProfileReactor()
        navigationController?.navigationBar.isHidden = true
        profileView.postCollectionView.dataSource = self
        profileView.postCollectionView.delegate = self
    }
    
    func bind(reactor: MemberProfileReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: MemberProfileReactor) {
        Observable.just(MemberProfileReactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        profileView.titleView.rx.backButtonTap
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.pageBack)
            })
            .disposed(by: disposeBag)
        
        profileView.rx.moreButtonTap
            .map { MemberProfileReactor.Action.moreButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
    }
    
    private func bindState(reactor: MemberProfileReactor) {
        reactor.state
            .map(\.profile)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] profile in
                self?.profile = profile
                self?.profileView.postCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.posts)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] posts in
                self?.posts = posts
                self?.profileView.postCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

extension MemberProfileViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        posts.isEmpty ? 1 : posts.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if posts.isEmpty {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: MemberProfileEmptyCell.reuseIdentifier,
                for: indexPath
            )
        }
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MemberProfilePostCell.reuseIdentifier,
            for: indexPath
        ) as? MemberProfilePostCell else {
            return UICollectionViewCell()
        }
        cell.configure(posts[indexPath.item])
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: MemberProfileHeaderView.reuseIdentifier,
                for: indexPath
              ) as? MemberProfileHeaderView else {
            return UICollectionReusableView()
        }
        
        if let profile {
            headerView.configure(profile: profile)
        }
        
        if let reactor {
            headerView.rx.sortButtonTap
                .map { MemberProfileReactor.Action.sortButtonTapped }
                .bind(to: reactor.action)
                .disposed(by: headerView.disposeBag)
        }
        
        return headerView
    }
}

extension MemberProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: posts.isEmpty ? 120 : 150)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 285)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let threshold: CGFloat = 300
        let visibleBottom = scrollView.contentOffset.y + scrollView.bounds.height
        let triggerOffset = scrollView.contentSize.height - threshold
        
        guard visibleBottom >= triggerOffset else { return }
        reactor?.action.onNext(.reachedBottom)
    }
}
