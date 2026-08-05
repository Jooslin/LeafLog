//
//  CommunityDetailViewController.swift
//  LeafLog
//
//  Created by Yeseul Jang on 7/7/26.
//

import RxCocoa
import RxSwift
import ReactorKit
import UIKit

final class CommunityDetailViewController: BaseViewController, View {
    private let detailView = CommunityDetailView()
    private var comments: [CommunityDetailReactor.Comment] = []
    
    override func loadView() {
        view = detailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = CommunityDetailReactor()
        navigationController?.navigationBar.isHidden = true
        detailView.commentCollectionView.dataSource = self
        detailView.commentCollectionView.delegate = self
    }
    
    func bind(reactor: CommunityDetailReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: CommunityDetailReactor) {
        Observable.just(CommunityDetailReactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.titleView.rx.backButtonTap
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.pageBack)
            })
            .disposed(by: disposeBag)
        
        detailView.rx.moreButtonTap
            .map { CommunityDetailReactor.Action.moreButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.postImageTap
            .map { CommunityDetailReactor.Action.postImageTapped(index: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.heartButtonTap
            .map { CommunityDetailReactor.Action.heartButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.commentButtonTap
            .map { CommunityDetailReactor.Action.commentButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.sendButtonTap
            .map { CommunityDetailReactor.Action.sendButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: CommunityDetailReactor) {
        reactor.state
            .map(\.post)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] post in
                self?.detailView.configure(post: post)
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.comments)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] comments in
                self?.comments = comments
                self?.detailView.updateCommentCollectionHeight(itemCount: comments.count)
                self?.detailView.commentCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$imageViewerRoute)
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] route in
                self?.presentImageViewer(route: route)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$memberProfileRoute)
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.memberProfile)
            })
            .disposed(by: disposeBag)
    }
    
    private func presentImageViewer(route: CommunityDetailReactor.ImageViewerRoute) {
        let viewController = CommunityImageViewerViewController(
            imageAssetNames: route.imageAssetNames,
            initialIndex: route.initialIndex
        )
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true)
    }
}

extension CommunityDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        comments.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CommunityCommentCell.reuseIdentifier,
            for: indexPath
        ) as? CommunityCommentCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(comments[indexPath.item])
        if let reactor {
            cell.rx.profileImageTap
                .map { CommunityDetailReactor.Action.commentProfileImageTapped(index: indexPath.item) }
                .bind(to: reactor.action)
                .disposed(by: cell.disposeBag)
        }
        
        return cell
    }
}

extension CommunityDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 70)
    }
}
