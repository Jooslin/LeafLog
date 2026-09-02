//
//  MemberProfileView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 8/5/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class MemberProfileView: UIView {
    let titleView = TitleHeaderView(text: "", hasBackButton: true, rightButtonImage: "more")
    
    let postCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: MemberProfileView.makePostLayout()
    ).then {
        $0.backgroundColor = .white
        $0.isScrollEnabled = true
        $0.showsVerticalScrollIndicator = false
        $0.register(
            MemberProfilePostCell.self,
            forCellWithReuseIdentifier: MemberProfilePostCell.reuseIdentifier
        )
        $0.register(
            MemberProfileHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MemberProfileHeaderView.reuseIdentifier
        )
        $0.register(
            MemberProfileEmptyCell.self,
            forCellWithReuseIdentifier: MemberProfileEmptyCell.reuseIdentifier
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
    
    func setMoreButtonHidden(_ isHidden: Bool) {
        titleView.rightButton.isHidden = isHidden
    }
}

// MARK: - Layout
private extension MemberProfileView {
    func setLayout() {
        addSubview(titleView)
        addSubview(postCollectionView)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        postCollectionView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    static func makePostLayout() -> UICollectionViewLayout {
        UICollectionViewFlowLayout().then {
            $0.scrollDirection = .vertical
            $0.minimumLineSpacing = 0
            $0.estimatedItemSize = .zero
        }
    }
}

extension Reactive where Base: MemberProfileView {
    var moreButtonTap: ControlEvent<Void> {
        base.titleView.rightButton.rx.tap
    }
}
