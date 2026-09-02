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
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = detailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        detailView.rx.profileImageTap
            .map { CommunityDetailReactor.Action.postProfileImageTapped }
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
        
        detailView.rx.commentText
            .map { ($0 ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isEnabled in
                self?.detailView.updateSendButton(isEnabled: isEnabled)
            })
            .disposed(by: disposeBag)
        
        detailView.rx.didScroll
            .filter { [weak self] in
                self?.detailView.isNearBottom(threshold: 300) == true
            }
            .map { CommunityDetailReactor.Action.reachedBottom }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: CommunityDetailReactor) {
        reactor.state
            .map(\.post)
            .distinctUntilChanged()
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] post in
                self?.detailView.configure(post: post)
            }
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.comments)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] comments in
                self?.comments = comments
                self?.detailView.commentCollectionView.reloadData()
                self?.detailView.updateCommentCollectionHeight(itemCount: comments.count)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$postActionSheetKind)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] kind in
                self?.presentPostActionSheet(kind: kind)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$imageViewerRoute)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] route in
                self?.presentImageViewer(route: route)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$memberProfileRoute)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] memberID in
                self?.steps.accept(AppStep.memberProfile(memberID: memberID))
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
    
    private func presentImageViewer(route: CommunityDetailReactor.ImageViewerRoute) {
        let viewController = CommunityImageViewerViewController(
            imageURLs: route.imageURLs,
            initialIndex: route.initialIndex
        )
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true)
    }
    
    private func presentPostActionSheet(kind: CommunityDetailReactor.PostActionSheetKind) {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        switch kind {
        case .owner:
            alertController.addAction(UIAlertAction(title: "수정하기", style: .default))
            alertController.addAction(UIAlertAction(title: "삭제하기", style: .destructive))
            
        case .visitor:
            alertController.addAction(UIAlertAction(title: "신고하기", style: .destructive) { [weak self] _ in
                self?.presentReportReasonActionSheet()
            })
        }
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentReportReasonActionSheet() {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        [
            "부적절한 콘텐츠",
            "광고/홍보",
            "식물과 관련 없는 내용",
            "개인정보/도용",
            "반복 게시/도배"
        ].forEach { reason in
            alertController.addAction(UIAlertAction(title: reason, style: .destructive) { [weak self] _ in
                self?.presentReportCompletedAlert()
            })
        }
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentReportCompletedAlert() {
        let alertController = UIAlertController(
            title: "신고가 접수되었습니다.",
            message: "운영자 확인 후 필요한 조치를 진행하겠습니다.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "닫기", style: .default))
        present(alertController, animated: true)
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
