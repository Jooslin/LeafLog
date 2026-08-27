//
//  MemberProfileHeaderView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 8/5/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class MemberProfileHeaderView: UICollectionReusableView {
    static let reuseIdentifier = String(describing: MemberProfileHeaderView.self)
    var disposeBag = DisposeBag()
    
    private let sortImageView = UIImageView().then {
        $0.image = UIImage(systemName: "arrow.up.arrow.down")
        $0.tintColor = .grayScale500
        $0.contentMode = .scaleAspectFit
    }
    
    private let sortLabel = UILabel(text: "최신순", config: .body14, color: .black, lines: 1)
    
    fileprivate let sortButton = UIButton(type: .custom).then {
        $0.backgroundColor = .clear
    }
    
    private let profileImageView = UIImageView().then {
        $0.backgroundColor = .grayScale100
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 46
        $0.clipsToBounds = true
    }
    
    private let nicknameLabel = UILabel(text: "", config: .headline20, color: .black, lines: 1).then {
        $0.textAlignment = .center
    }
    
    private let postCountLabel = UILabel(text: "", config: .label14, color: .primary700, lines: 1)
    private let likeCountLabel = UILabel(text: "", config: .label14, color: .primary700, lines: 1)
    private let sectionTitleLabel = UILabel(text: "게시글", config: .title16, color: .black, lines: 1)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
    
    func configure(profile: MemberProfileReactor.Profile) {
        nicknameLabel.text = profile.nickname
        profileImageView.image = profile.profileImageAssetName.flatMap { UIImage(named: $0) }
        postCountLabel.text = profile.postCount
        likeCountLabel.text = profile.likeCount
    }
    
    private func setLayout() {
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
        
        addSubview(profileStackView)
        addSubview(sectionTitleLabel)
        let sortStackView = UIStackView(arrangedSubviews: [sortImageView, sortLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 6
            $0.alignment = .center
        }
        
        addSubview(sortStackView)
        addSubview(sortButton)
        
        profileStackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(42)
            $0.centerX.equalToSuperview()
        }
        
        profileImageView.snp.makeConstraints {
            $0.width.height.equalTo(96)
        }
        
        sectionTitleLabel.snp.makeConstraints {
            $0.top.equalTo(profileStackView.snp.bottom).offset(38)
            $0.leading.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(18)
        }
        
        sortStackView.snp.makeConstraints {
            $0.centerY.equalTo(sectionTitleLabel)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        sortImageView.snp.makeConstraints {
            $0.width.height.equalTo(16)
        }
        
        sortButton.snp.makeConstraints {
            $0.edges.equalTo(sortStackView)
        }
    }
}

extension Reactive where Base: MemberProfileHeaderView {
    var sortButtonTap: ControlEvent<Void> {
        base.sortButton.rx.tap
    }
}
