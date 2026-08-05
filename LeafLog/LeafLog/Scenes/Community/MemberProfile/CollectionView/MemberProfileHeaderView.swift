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
    
    fileprivate let sortButton = UIButton(configuration: .plain()).then {
        $0.setTitle("최신순", for: .normal)
        $0.setTitleColor(.black, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        $0.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
        $0.configuration?.baseForegroundColor = .grayScale500
        $0.configuration?.imagePadding = 6
        $0.semanticContentAttribute = .forceLeftToRight
    }
    
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
        addSubview(sortButton)
        
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
            $0.bottom.equalToSuperview().inset(18)
        }
        
        sortButton.snp.makeConstraints {
            $0.centerY.equalTo(sectionTitleLabel)
            $0.trailing.equalToSuperview().inset(16)
        }
    }
}

extension Reactive where Base: MemberProfileHeaderView {
    var sortButtonTap: ControlEvent<Void> {
        base.sortButton.rx.tap
    }
}
