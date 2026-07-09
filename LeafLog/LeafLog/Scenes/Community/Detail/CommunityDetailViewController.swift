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
    
    private let comments: [CommunityCommentCell.Comment] = [
        .init(
            nickname: "닉네임임",
            date: "2026.04.27",
            body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
            isAuthor: false,
            isMine: false
        ),
        .init(
            nickname: "닉네임임",
            date: "2026.04.27",
            body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
            isAuthor: true,
            isMine: false
        ),
        .init(
            nickname: "닉네임임",
            date: "2026.04.27",
            body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
            isAuthor: false,
            isMine: true
        ),
        .init(
            nickname: "닉네임임",
            date: "2026.04.27",
            body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
            isAuthor: false,
            isMine: false
        )
    ]
    
    override func loadView() {
        view = detailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reactor = CommunityDetailReactor()
        navigationController?.navigationBar.isHidden = true
        detailView.commentCollectionView.dataSource = self
        detailView.commentCollectionView.delegate = self
        detailView.updateCommentCollectionHeight(itemCount: comments.count)
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
    }
    
    private func bindState(reactor: CommunityDetailReactor) {
        reactor.state
            .map(\.post)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] post in
                self?.detailView.configure(post: post)
            })
            .disposed(by: disposeBag)
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
