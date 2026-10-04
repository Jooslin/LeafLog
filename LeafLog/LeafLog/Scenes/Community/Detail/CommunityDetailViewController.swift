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

nonisolated private enum CommunityDetailItemID: Hashable, Sendable {
    case post(UUID)
    case commentHeader
    case emptyComment
    case comment(UUID)
    
    init(_ item: CommunityDetailReactor.DetailItem) {
        switch item {
        case .post(let post):
            self = .post(post.id)
        case .commentHeader:
            self = .commentHeader
        case .emptyComment:
            self = .emptyComment
        case .comment(let comment):
            self = .comment(comment.id)
        }
    }
}

final class CommunityDetailViewController: BaseViewController, View {
    private let detailView = CommunityDetailView(frame: UIScreen.main.bounds)
    private let commentInputAccessoryView = CommunityCommentInputAccessoryView(
        frame: CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: 86
        )
    )
    private var comments: [CommunityDetailReactor.Comment] = []
    private var detailItems: [CommunityDetailReactor.DetailItem] = []
    private lazy var dataSource = UICollectionViewDiffableDataSource<
        Int,
        CommunityDetailItemID
    >(
        collectionView: detailView.detailCollectionView
    ) { [weak self] collectionView, indexPath, itemID in
        guard let item = self?.detailItem(for: itemID) else {
            return UICollectionViewCell()
        }
        
        return self?.makeCell(
            collectionView: collectionView,
            indexPath: indexPath,
            item: item
        ) ?? UICollectionViewCell()
    }
    
    override var inputAccessoryView: UIView? {
        commentInputAccessoryView
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
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
        _ = dataSource
        updateCollectionViewBottomInset()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        resignFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateCollectionViewBottomInset()
    }
    
    func bind(reactor: CommunityDetailReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    func refreshPostIfNeeded(postID: UUID) {
        guard reactor?.currentState.post?.id == postID else { return }
        reactor?.action.onNext(.loadDetail)
    }
    
    var currentPostID: UUID? {
        reactor?.currentState.post?.id
    }
    
    private func bindAction(reactor: CommunityDetailReactor) {
        Observable.just(CommunityDetailReactor.Action.loadDetail)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.detailCollectionView.rx.setDelegate(self)
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
        
        commentInputAccessoryView.rx.sendButtonTap
            .map { CommunityDetailReactor.Action.sendButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        commentInputAccessoryView.rx.cancelCommentEditingButtonTap
            .map { CommunityDetailReactor.Action.cancelCommentEditingButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        commentInputAccessoryView.rx.commentText
            .orEmpty
            .map { CommunityDetailReactor.Action.enterCommentText($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        commentInputAccessoryView.rx.commentText
            .map { ($0 ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isEnabled in
                self?.commentInputAccessoryView.updateSendButton(isEnabled: isEnabled)
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
            .map(\.detailItems)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] detailItems in
                self?.detailItems = detailItems
                self?.comments = detailItems.compactMap {
                    guard case .comment(let comment) = $0 else { return nil }
                    return comment
                }
                self?.applySnapshot(detailItems: detailItems)
            }
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.commentInputText)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] text in
                self?.commentInputAccessoryView.setCommentText(text)
            }
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.editingCommentID == nil ? CommunityCommentInputAccessoryView.CommentInputMode.create : .edit }
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] mode in
                self?.commentInputAccessoryView.setCommentInputMode(mode)
                self?.commentInputAccessoryView.applyPreferredHeight()
                self?.commentInputAccessoryView.layoutIfNeeded()
                self?.reloadInputViews()
                self?.updateCollectionViewBottomInset()
                
                guard mode == .edit else { return }
                
                DispatchQueue.main.async {
                    self?.commentInputAccessoryView.focusCommentInput()
                }
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$postActionSheetKind)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] kind in
                self?.presentPostActionSheet(kind: kind)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$commentActionSheetKind)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] kind in
                self?.presentCommentActionSheet(kind: kind)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$commentScrollTarget)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] target in
                self?.scrollToComment(target)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$shouldDismissCommentInput)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] _ in
                self?.dismissCommentInput()
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
        
        reactor.pulse(\.$editPostRoute)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] post in
                self?.steps.accept(AppStep.communityComposeEdit(post))
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$deletedPostRoute)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] postID in
                self?.steps.accept(AppStep.communityPostDeleted(postID: postID))
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$reportCompleted)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] _ in
                self?.presentReportCompletedAlert()
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
    
    private func updateCollectionViewBottomInset() {
        detailView.setCollectionViewBottomInset(commentInputAccessoryView.preferredHeight)
    }
    
    private func applySnapshot(detailItems: [CommunityDetailReactor.DetailItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<
            Int,
            CommunityDetailItemID
        >()
        snapshot.appendSections([0])
        snapshot.appendItems(detailItems.map(CommunityDetailItemID.init), toSection: 0)
        
        dataSource.apply(
            snapshot,
            animatingDifferences: detailView.detailCollectionView.window != nil
        )
    }
    
    private func detailItem(
        for itemID: CommunityDetailItemID
    ) -> CommunityDetailReactor.DetailItem? {
        detailItems.first {
            CommunityDetailItemID($0) == itemID
        }
    }
    
    private func endCommentInputEditing() {
        commentInputAccessoryView.resignCommentInputFocus()
        keepCommentInputAccessoryVisible()
    }
    
    private func keepCommentInputAccessoryVisible() {
        DispatchQueue.main.async { [weak self] in
            self?.becomeFirstResponder()
        }
    }
    
    private func makeCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: CommunityDetailReactor.DetailItem
    ) -> UICollectionViewCell {
        switch item {
        case .post(let post):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CommunityPostContentCell.reuseIdentifier,
                for: indexPath
            ) as? CommunityPostContentCell else {
                return UICollectionViewCell()
            }
            
            cell.configure(post: post)
            if let reactor {
                cell.rx.postImageTap
                    .map { CommunityDetailReactor.Action.postImageTapped(index: $0) }
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
                
                cell.rx.profileImageTap
                    .map { CommunityDetailReactor.Action.postProfileImageTapped }
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
                
                cell.rx.heartButtonTap
                    .map { CommunityDetailReactor.Action.heartButtonTapped }
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
            }
            
            return cell
            
        case .commentHeader:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CommunityCommentHeaderCell.reuseIdentifier,
                for: indexPath
            ) as? CommunityCommentHeaderCell else {
                return UICollectionViewCell()
            }
            
            return cell
            
        case .emptyComment:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CommunityCommentEmptyCell.reuseIdentifier,
                for: indexPath
            ) as? CommunityCommentEmptyCell else {
                return UICollectionViewCell()
            }
            
            return cell
            
        case .comment(let comment):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CommunityCommentCell.reuseIdentifier,
                for: indexPath
            ) as? CommunityCommentCell else {
                return UICollectionViewCell()
            }
            
            cell.configure(comment)
            if let reactor {
                cell.rx.profileImageTap
                    .compactMap { [weak self] in
                        self?.comments.firstIndex { $0.id == comment.id }
                    }
                    .map { CommunityDetailReactor.Action.commentProfileImageTapped(index: $0) }
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
                
                cell.rx.moreButtonTap
                    .compactMap { [weak self] in
                        self?.comments.firstIndex { $0.id == comment.id }
                    }
                    .map { CommunityDetailReactor.Action.commentMoreButtonTapped(index: $0) }
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
            }
            
            return cell
        }
    }
    
    private func scrollToComment(_ target: CommunityDetailReactor.CommentScrollTarget) {
        switch target {
        case .firstComment:
            guard let commentIndex = detailItems.firstIndex(where: {
                guard case .comment = $0 else { return false }
                return true
            }) else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                self.detailView.detailCollectionView.layoutIfNeeded()
                self.detailView.detailCollectionView.scrollToItem(
                    at: IndexPath(item: commentIndex, section: 0),
                    at: .top,
                    animated: true
                )
            }
        }
    }
    
    private func presentPostActionSheet(kind: CommunityDetailReactor.PostActionSheetKind) {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        switch kind {
        case .owner:
            alertController.addAction(UIAlertAction(title: "수정하기", style: .default) { [weak self] _ in
                self?.reactor?.action.onNext(.editButtonTapped)
            })
            alertController.addAction(UIAlertAction(title: "삭제하기", style: .destructive) { [weak self] _ in
                self?.presentDeleteConfirmAlert()
            })
            alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
            present(alertController, animated: true)
            
        case .visitor:
            presentReportConfirmAlert()
        }
    }
    
    private func presentCommentActionSheet(kind: CommunityDetailReactor.CommentActionSheetKind) {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        switch kind {
        case .owner(let commentID):
            alertController.addAction(UIAlertAction(title: "수정하기", style: .default) { [weak self] _ in
                self?.reactor?.action.onNext(.editCommentButtonTapped(commentID: commentID))
            })
            alertController.addAction(UIAlertAction(title: "삭제하기", style: .destructive) { [weak self] _ in
                self?.presentCommentDeleteConfirmAlert(commentID: commentID)
            })
            alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
            present(alertController, animated: true)
            
        case .visitor:
            presentCommentReportConfirmAlert()
        }
    }
    
    private func presentCommentReportConfirmAlert() {
        let alertController = UIAlertController(
            title: "이 댓글을 신고하시겠습니까?",
            message: nil,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "신고하기", style: .destructive) { [weak self] _ in
            self?.presentCommentReportReasonActionSheet()
        })
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentCommentDeleteConfirmAlert(commentID: UUID) {
        let alertController = UIAlertController(
            title: "댓글을 삭제하시겠습니까?",
            message: nil,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.deleteCommentButtonTapped(commentID: commentID))
        })
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentDeleteConfirmAlert() {
        let alertController = UIAlertController(
            title: "게시글을 삭제하시겠습니까?",
            message: nil,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.deleteButtonTapped)
        })
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentReportConfirmAlert() {
        let alertController = UIAlertController(
            title: "이 게시글을 신고하시겠습니까?",
            message: nil,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "신고하기", style: .destructive) { [weak self] _ in
            self?.presentReportReasonActionSheet()
        })
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentReportReasonActionSheet() {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        CommunityReportReason.allCases.forEach { reason in
            alertController.addAction(UIAlertAction(title: reason.title, style: .destructive) { [weak self] _ in
                self?.reactor?.action.onNext(.reportReasonSelected(reason))
            })
        }
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentCommentReportReasonActionSheet() {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        CommunityReportReason.allCases.forEach { reason in
            alertController.addAction(UIAlertAction(title: reason.title, style: .destructive) { [weak self] _ in
                self?.reactor?.action.onNext(.commentReportReasonSelected(reason))
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

extension CommunityDetailViewController: UICollectionViewDelegate {}
