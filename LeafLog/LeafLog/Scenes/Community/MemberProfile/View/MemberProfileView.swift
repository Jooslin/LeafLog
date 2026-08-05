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
    let titleView = TitleHeaderView(text: "", hasBackButton: true, rightButtonImage: nil)
    
    let postCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: MemberProfileView.makePostLayout()
    ).then {
        $0.backgroundColor = .white
        $0.isScrollEnabled = false
        $0.showsVerticalScrollIndicator = false
        $0.register(
            MemberProfilePostCell.self,
            forCellWithReuseIdentifier: MemberProfilePostCell.reuseIdentifier
        )
    }
    
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
    }
    
    private let contentView = UIView()
    
    private let profileImageView = UIImageView().then {
        $0.backgroundColor = .grayScale100
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 46
        $0.clipsToBounds = true
    }
    
    private let nicknameLabel = UILabel(text: "", config: .headline24, color: .black, lines: 1).then {
        $0.textAlignment = .center
    }
    
    private let postCountLabel = UILabel(text: "", config: .label14, color: .primary700, lines: 1)
    private let likeCountLabel = UILabel(text: "", config: .label14, color: .primary700, lines: 1)
    private let sectionTitleLabel = UILabel(text: "게시글", config: .title18, color: .black, lines: 1)
    fileprivate let sortButton = UIButton(configuration: .plain()).then {
        $0.setTitle("최신순", for: .normal)
        $0.setTitleColor(.black, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        $0.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
        $0.configuration?.baseForegroundColor = .grayScale500
        $0.configuration?.imagePadding = 6
        $0.semanticContentAttribute = .forceLeftToRight
    }
    
    private var postCollectionHeightConstraint: Constraint?
    private lazy var emptyActivityBackgroundView = makeEmptyActivityBackgroundView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        configureTitleView()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(profile: MemberProfileReactor.Profile) {
        nicknameLabel.text = profile.nickname
        profileImageView.image = profile.profileImageAssetName.flatMap { UIImage(named: $0) }
        
        postCountLabel.text = profile.postCount
        likeCountLabel.text = profile.likeCount
    }
    
    func updatePostCollectionHeight(itemCount: Int) {
        let isEmpty = itemCount == 0
        postCollectionView.backgroundView = isEmpty ? emptyActivityBackgroundView : nil
        postCollectionHeightConstraint?.update(offset: isEmpty ? 120 : CGFloat(itemCount) * 150)
        layoutIfNeeded()
    }
}

// MARK: - Layout
private extension MemberProfileView {
    func setLayout() {
        let postCountTitleLabel = UILabel(text: "작성한 글", config: .body14, color: .black, lines: 1)
        let likeCountTitleLabel = UILabel(text: "받은 좋아요", config: .body14, color: .black, lines: 1)
        
        let postCountStackView = UIStackView(arrangedSubviews: [postCountTitleLabel, postCountLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 4
            $0.alignment = .center
        }
        
        let likeCountStackView = UIStackView(arrangedSubviews: [likeCountTitleLabel, likeCountLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 4
            $0.alignment = .center
        }
        
        let statStackView = UIStackView(arrangedSubviews: [postCountStackView, likeCountStackView]).then {
            $0.axis = .horizontal
            $0.spacing = 24
            $0.alignment = .center
        }
        
        let profileStackView = UIStackView(arrangedSubviews: [profileImageView, nicknameLabel, statStackView]).then {
            $0.axis = .vertical
            $0.spacing = 12
            $0.alignment = .center
        }
        
        addSubview(titleView)
        addSubview(scrollView)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
        
        scrollView.addSubview(contentView)
        contentView.addSubview(profileStackView)
        contentView.addSubview(sectionTitleLabel)
        contentView.addSubview(sortButton)
        contentView.addSubview(postCollectionView)
        
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.snp.width)
        }
        
        profileStackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(42)
            $0.centerX.equalToSuperview()
        }
        
        profileImageView.snp.makeConstraints {
            $0.width.height.equalTo(92)
        }
        
        sectionTitleLabel.snp.makeConstraints {
            $0.top.equalTo(profileStackView.snp.bottom).offset(38)
            $0.leading.equalToSuperview().inset(16)
        }
        
        sortButton.snp.makeConstraints {
            $0.centerY.equalTo(sectionTitleLabel)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        postCollectionView.snp.makeConstraints {
            $0.top.equalTo(sectionTitleLabel.snp.bottom).offset(18)
            $0.horizontalEdges.equalToSuperview()
            postCollectionHeightConstraint = $0.height.equalTo(450).constraint
            $0.bottom.equalToSuperview().inset(24)
        }
    }
    
    func configureTitleView() {
        titleView.titleLabel.text = ""
        titleView.rightButton.isHidden = false
        titleView.rightButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        titleView.rightButton.configuration?.baseForegroundColor = .grayScale600
    }
    
    static func makePostLayout() -> UICollectionViewLayout {
        UICollectionViewFlowLayout().then {
            $0.scrollDirection = .vertical
            $0.minimumLineSpacing = 0
            $0.estimatedItemSize = .zero
        }
    }
    
    func makeEmptyActivityBackgroundView() -> UIView {
        let backgroundView = UIView()
        let label = UILabel(
            text: "활동 내역이 없어요",
            config: .body14,
            color: .grayScale500,
            lines: 1
        ).then {
            $0.textAlignment = .center
        }
        
        backgroundView.addSubview(label)
        label.snp.makeConstraints {
            $0.top.equalToSuperview().offset(46)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        return backgroundView
    }
}

extension Reactive where Base: MemberProfileView {
    var moreButtonTap: ControlEvent<Void> {
        base.titleView.rightButton.rx.tap
    }
    
    var sortButtonTap: ControlEvent<Void> {
        base.sortButton.rx.tap
    }
}
