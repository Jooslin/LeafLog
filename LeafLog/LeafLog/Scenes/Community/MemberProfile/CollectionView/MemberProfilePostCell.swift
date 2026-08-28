//
//  MemberProfilePostCell.swift
//  LeafLog
//
//  Created by Yeseul Jang on 8/5/26.
//

import SnapKit
import Then
import UIKit

final class MemberProfilePostCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: MemberProfilePostCell.self)
    
    private let titleLabel = UILabel(text: "", config: .title16, color: .black, lines: 1)
    
    private let profileImageView = UIView().then {
        $0.backgroundColor = .grayScale100
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    private let nicknameLabel = UILabel(text: "", config: .body12, color: .grayScale600, lines: 1)
    private let dateLabel = UILabel(text: "", config: .body12, color: .grayScale500, lines: 1)
    
    private let bodyLabel = UILabel(text: "", config: .body14, color: .grayScale600, lines: 2).then {
        $0.lineBreakMode = .byTruncatingTail
    }
    
    private let thumbnailImageView = UIImageView().then {
        $0.backgroundColor = .grayScale100
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }
    
    private let heartImageView = UIImageView(image: UIImage(systemName: "heart")).then {
        $0.tintColor = .grayScale500
        $0.contentMode = .scaleAspectFit
    }
    
    private let heartCountLabel = UILabel(text: "", config: .body12, color: .grayScale500, lines: 1)
    
    private let commentImageView = UIImageView(image: UIImage(systemName: "bubble")).then {
        $0.tintColor = .grayScale500
        $0.contentMode = .scaleAspectFit
    }
    
    private let commentCountLabel = UILabel(text: "", config: .body12, color: .grayScale500, lines: 1)
    
    private let dividerView = UIView().then {
        $0.backgroundColor = .grayScale100
    }
    
    private var thumbnailWidthConstraint: Constraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        nicknameLabel.text = nil
        dateLabel.text = nil
        bodyLabel.text = nil
        thumbnailImageView.image = nil
        heartCountLabel.text = nil
        commentCountLabel.text = nil
        thumbnailImageView.isHidden = false
        thumbnailWidthConstraint?.update(offset: 100)
    }
    
    func configure(_ post: MemberProfileReactor.Post) {
        titleLabel.text = post.title
        nicknameLabel.text = post.nickname
        dateLabel.text = post.date
        bodyLabel.setTextWithLineHeight(text: post.body, height: 20)
        heartCountLabel.text = post.likeCount
        commentCountLabel.text = post.commentCount
        
        if let imageAssetName = post.imageAssetName {
            thumbnailImageView.isHidden = false
            thumbnailImageView.image = UIImage(named: imageAssetName) ?? UIImage(resource: .placeholder)
            thumbnailWidthConstraint?.update(offset: 100)
        } else {
            thumbnailImageView.isHidden = true
            thumbnailWidthConstraint?.update(offset: 0)
        }
    }
    
    private func setLayout() {
        let metaDividerView = UIView().then {
            $0.backgroundColor = .grayScale200
        }
        
        let metaStackView = UIStackView(arrangedSubviews: [nicknameLabel, metaDividerView, dateLabel]).then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 10
        }
        
        let authorStackView = UIStackView(arrangedSubviews: [profileImageView, metaStackView]).then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 8
        }
        
        let heartStackView = UIStackView(arrangedSubviews: [heartImageView, heartCountLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 3
            $0.alignment = .center
        }
        
        let commentStackView = UIStackView(arrangedSubviews: [commentImageView, commentCountLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 3
            $0.alignment = .center
        }
        
        let reactionStackView = UIStackView(arrangedSubviews: [heartStackView, commentStackView]).then {
            $0.axis = .horizontal
            $0.spacing = 16
            $0.alignment = .center
        }
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorStackView)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(reactionStackView)
        contentView.addSubview(dividerView)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(10)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalTo(thumbnailImageView.snp.leading).offset(-12)
        }
        
        thumbnailImageView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(10)
            $0.trailing.equalToSuperview().inset(16)
            thumbnailWidthConstraint = $0.width.equalTo(100).constraint
            $0.height.equalTo(100)
        }
        
        profileImageView.snp.makeConstraints {
            $0.width.height.equalTo(20)
        }
        
        metaDividerView.snp.makeConstraints {
            $0.width.equalTo(1)
            $0.height.equalTo(12)
        }
        
        authorStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.lessThanOrEqualTo(titleLabel)
        }
        
        bodyLabel.snp.makeConstraints {
            $0.top.equalTo(authorStackView.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalTo(thumbnailImageView.snp.leading).offset(-12)
        }
        
        heartImageView.snp.makeConstraints {
            $0.width.height.equalTo(16)
        }
        
        commentImageView.snp.makeConstraints {
            $0.width.height.equalTo(16)
        }
        
        reactionStackView.snp.makeConstraints {
            $0.top.equalTo(bodyLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
        }
        
        dividerView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
}
