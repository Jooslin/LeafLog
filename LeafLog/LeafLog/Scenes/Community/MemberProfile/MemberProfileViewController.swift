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
    private var postListItems: [MemberProfileReactor.PostListItem] = []
    
    init(memberID: UUID) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = MemberProfileReactor(memberID: memberID)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = profileView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] profile in
                self?.profile = profile
                self?.profileView.postCollectionView.reloadData()
            }
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.postListItems)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] postListItems in
                self?.postListItems = postListItems
                self?.profileView.postCollectionView.reloadData()
            }
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.shouldShowMoreButton)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] shouldShowMoreButton in
                self?.profileView.setMoreButtonHidden(shouldShowMoreButton == false)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] message in
                self?.steps.accept(AppStep.alert("오류", message))
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$memberActionSheet)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] _ in
                self?.presentMemberActionSheet()
            }
            .disposed(by: disposeBag)
    }
    
    private func presentMemberActionSheet() {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        alertController.addAction(UIAlertAction(title: "차단하기", style: .destructive))
        alertController.addAction(UIAlertAction(title: "신고하기", style: .destructive))
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
}

extension MemberProfileViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        postListItems.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch postListItems[indexPath.item] {
        case .empty:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: MemberProfileEmptyCell.reuseIdentifier,
                for: indexPath
            )
            
        case .post(let post):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MemberProfilePostCell.reuseIdentifier,
                for: indexPath
            ) as? MemberProfilePostCell else {
                return UICollectionViewCell()
            }
            cell.configure(post)
            return cell
        }
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
        switch postListItems[indexPath.item] {
        case .empty:
            return CGSize(width: collectionView.bounds.width, height: 120)
            
        case .post:
            return CGSize(width: collectionView.bounds.width, height: 150)
        }
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard case .post(let post) = postListItems[indexPath.item] else { return }
        steps.accept(AppStep.communityDetail(postID: post.id))
    }
}
