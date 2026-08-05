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
        
        profileView.rx.sortButtonTap
            .map { MemberProfileReactor.Action.sortButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: MemberProfileReactor) {
        reactor.state
            .map(\.profile)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] profile in
                self?.profileView.configure(profile: profile)
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.posts)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] posts in
                self?.posts = posts
                self?.profileView.updatePostCollectionHeight(itemCount: posts.count)
                self?.profileView.postCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

extension MemberProfileViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        posts.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MemberProfilePostCell.reuseIdentifier,
            for: indexPath
        ) as? MemberProfilePostCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(posts[indexPath.item])
        return cell
    }
}

extension MemberProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 150)
    }
}
