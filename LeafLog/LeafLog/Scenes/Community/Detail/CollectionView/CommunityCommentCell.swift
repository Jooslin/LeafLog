//
//  CommunityCommentCell.swift
//  LeafLog
//
//  Created by Yeseul Jang on 7/7/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class CommunityCommentCell: UICollectionViewCell {
    static let reuseIdentifier = "CommunityCommentCell"
    var disposeBag = DisposeBag()
    
    fileprivate let profileImageButton = UIButton(type: .custom).then {
        $0.backgroundColor = .grayScale100
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    private let nicknameLabel = UILabel(text: "", config: .body12, color: .grayScale600, lines: 1)
    private let dateLabel = UILabel(text: "", config: .body12, color: .grayScale500, lines: 1)
    private let bodyLabel = UILabel(text: "", config: .body14, color: .black, lines: 0)
    
    private let authorBadgeLabel = PaddingLabel(
        horizontalInset: 10,
        verticalInset: 3
    ).then {
        $0.apply(.label12, color: .primary700, lines: 1)
        $0.text = "작성자"
        $0.backgroundColor = .primary100
        $0.layer.borderColor = UIColor.primary400.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.isHidden = true
    }
    
    private let myCommentBadgeLabel = PaddingLabel(
        horizontalInset: 10,
        verticalInset: 3
    ).then {
        $0.apply(.label12, color: .grayScale400, lines: 1)
        $0.text = "내 댓글"
        $0.backgroundColor = .white
        $0.layer.borderColor = UIColor.grayScale100.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.isHidden = true
    }
    
    private let moreButton = UIButton(configuration: .plain()).then {
        let image = UIImage(systemName: "ellipsis")
        $0.setImage(image, for: .normal)
        $0.configuration?.baseForegroundColor = .black
        $0.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        nicknameLabel.text = nil
        dateLabel.text = nil
        bodyLabel.text = nil
        disposeBag = DisposeBag()
        applyBadge(.none)
    }
    
    private func setLayout() {
        let dividerView = UIView().then {
            $0.backgroundColor = .grayScale100
        }
        
        let metaStackView = UIStackView(arrangedSubviews: [nicknameLabel, dividerView, dateLabel]).then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 8
        }
        
        let badgeStackView = UIStackView(arrangedSubviews: [authorBadgeLabel, myCommentBadgeLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 6
            $0.alignment = .center
        }
        
        let topStackView = UIStackView(arrangedSubviews: [metaStackView, badgeStackView]).then {
            $0.axis = .horizontal
            $0.spacing = 10
            $0.alignment = .center
        }
        
        contentView.addSubview(profileImageButton)
        contentView.addSubview(topStackView)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(moreButton)
        
        profileImageButton.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.leading.equalToSuperview().inset(20)
            $0.width.height.equalTo(20)
        }
        
        topStackView.snp.makeConstraints {
            $0.centerY.equalTo(profileImageButton)
            $0.leading.equalTo(profileImageButton.snp.trailing).offset(8)
            $0.trailing.lessThanOrEqualTo(moreButton.snp.leading).offset(-8)
        }
        
        dividerView.snp.makeConstraints {
            $0.width.equalTo(1)
            $0.height.equalTo(12)
        }
        
        moreButton.snp.makeConstraints {
            $0.top.equalToSuperview().inset(4)
            $0.trailing.equalToSuperview().inset(16)
            $0.width.height.equalTo(20)
        }
        
        bodyLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageButton.snp.bottom).offset(6)
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.lessThanOrEqualToSuperview().inset(8)
        }
    }
}

extension Reactive where Base: CommunityCommentCell {
    var profileImageTap: ControlEvent<Void> {
        base.profileImageButton.rx.tap
    }
}

extension CommunityCommentCell {
    func configure(_ comment: CommunityDetailReactor.Comment) {
        nicknameLabel.text = comment.nickname
        dateLabel.text = comment.date
        bodyLabel.text = comment.body
        applyBadge(comment.badge)
        bodyLabel.setTextWithLineHeight(text: comment.body, height: 20)
    }
    
    private func applyBadge(_ badge: CommunityDetailReactor.CommentBadge) {
        switch badge {
        case .author:
            authorBadgeLabel.isHidden = false
            myCommentBadgeLabel.isHidden = true
        case .mine:
            authorBadgeLabel.isHidden = true
            myCommentBadgeLabel.isHidden = false
        case .none:
            authorBadgeLabel.isHidden = true
            myCommentBadgeLabel.isHidden = true
        }
    }
}
