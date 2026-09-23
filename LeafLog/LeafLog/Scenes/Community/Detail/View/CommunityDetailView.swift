//
//  CommunityDetailView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 7/7/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class CommunityDetailView: UIView {
    let titleView = TitleHeaderView(text: "", hasBackButton: true, rightButtonImage: "more")
    
    let detailCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: CommunityDetailView.makeDetailLayout()
    ).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .interactive
        $0.register(
            CommunityPostContentCell.self,
            forCellWithReuseIdentifier: CommunityPostContentCell.reuseIdentifier
        )
        $0.register(
            CommunityCommentHeaderCell.self,
            forCellWithReuseIdentifier: CommunityCommentHeaderCell.reuseIdentifier
        )
        $0.register(
            CommunityCommentEmptyCell.self,
            forCellWithReuseIdentifier: CommunityCommentEmptyCell.reuseIdentifier
        )
        $0.register(
            CommunityCommentCell.self,
            forCellWithReuseIdentifier: CommunityCommentCell.reuseIdentifier
        )
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func isNearBottom(threshold: CGFloat) -> Bool {
        let visibleBottom = detailCollectionView.contentOffset.y + detailCollectionView.bounds.height
        let triggerOffset = detailCollectionView.contentSize.height - threshold
        
        return visibleBottom >= triggerOffset
    }
    
    func setCollectionViewBottomInset(_ bottomInset: CGFloat) {
        detailCollectionView.contentInset.bottom = bottomInset
        detailCollectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
}

// MARK: - Layout
private extension CommunityDetailView {
    func setLayout() {
        addSubview(titleView)
        addSubview(detailCollectionView)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        detailCollectionView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
    }

    static func makeDetailLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(120)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 0
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
}

extension Reactive where Base: CommunityDetailView {
    var moreButtonTap: ControlEvent<Void> {
        base.titleView.rightButton.rx.tap
    }
    
    var didScroll: ControlEvent<Void> {
        base.detailCollectionView.rx.didScroll
    }
}
