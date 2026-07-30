//
//  MyActivityPostCell.swift
//  LeafLog
//

import SnapKit
import Then
import UIKit

final class MyActivityPostCell: UICollectionViewCell {
    private let titleLabel = UILabel(config: .title16, lines: 1).then {
        $0.lineBreakMode = .byTruncatingTail
    }

    private let profileView = UIView().then {
        $0.backgroundColor = .grayScale100
        $0.layer.cornerRadius = 11
    }

    private let nicknameLabel = UILabel(config: .body12, color: .grayScale800, lines: 1)

    private let metadataSeparator = UIView().then {
        $0.backgroundColor = .grayScale100
    }

    private let dateLabel = UILabel(config: .body12, color: .grayScale600, lines: 1)

    private let bodyLabel = UILabel(config: .body14, color: .grayScale600, lines: 2).then {
        $0.lineBreakMode = .byTruncatingTail
    }

    private let postImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }

    private let likeImageView = UIImageView(
        image: UIImage(named: "heart")?.withRenderingMode(.alwaysTemplate)
    ).then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .grayScale400
    }

    private let likeCountLabel = UILabel(config: .body12, color: .grayScale400, lines: 1)

    private let commentImageView = UIImageView(
        image: UIImage(named: "message")?.withRenderingMode(.alwaysTemplate)
    ).then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .grayScale400
    }

    private let commentCountLabel = UILabel(config: .body12, color: .grayScale400, lines: 1)

    private let separatorView = SeparateBar()

    private lazy var metadataStackView = UIStackView(
        arrangedSubviews: [profileView, nicknameLabel, metadataSeparator, dateLabel]
    ).then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 8
    }

    private lazy var likeStackView = UIStackView(
        arrangedSubviews: [likeImageView, likeCountLabel]
    ).then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 4
    }

    private lazy var commentStackView = UIStackView(
        arrangedSubviews: [commentImageView, commentCountLabel]
    ).then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 4
    }

    private lazy var reactionStackView = UIStackView(
        arrangedSubviews: [likeStackView, commentStackView]
    ).then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 16
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        postImageView.image = nil
        postImageView.isHidden = false
    }

    func configure(with post: MyActivityPost) {
        titleLabel.text = post.title
        nicknameLabel.text = post.nickname
        dateLabel.text = post.date
        bodyLabel.text = post.body
        likeCountLabel.text = post.likeCount
        commentCountLabel.text = post.commentCount
        separatorView.isHidden = !post.showsSeparator

        let hasImage = post.imageName != nil
        postImageView.isHidden = !hasImage
        postImageView.image = post.imageName.flatMap(UIImage.init(named:))
        updateTextLayout(hasImage: hasImage)
    }

    private func setupUI() {
        [
            titleLabel,
            metadataStackView,
            bodyLabel,
            postImageView,
            reactionStackView,
            separatorView
        ].forEach(contentView.addSubview)

        profileView.snp.makeConstraints {
            $0.size.equalTo(22)
        }

        metadataSeparator.snp.makeConstraints {
            $0.width.equalTo(1)
            $0.height.equalTo(12)
        }

        postImageView.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(100)
        }

        metadataStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview()
        }

        reactionStackView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.bottom.equalTo(separatorView.snp.top).offset(-16)
        }

        [likeImageView, commentImageView].forEach {
            $0.snp.makeConstraints { $0.size.equalTo(16) }
        }

        separatorView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
        }

        updateTextLayout(hasImage: true)
    }

    private func updateTextLayout(hasImage: Bool) {
        let trailingInset: CGFloat = hasImage ? 116 : 0

        titleLabel.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview().inset(trailingInset)
        }

        bodyLabel.snp.remakeConstraints {
            $0.top.equalTo(metadataStackView.snp.bottom).offset(8)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview().inset(trailingInset)
        }

        reactionStackView.snp.remakeConstraints {
            $0.leading.equalToSuperview()
            if hasImage {
                $0.top.equalTo(postImageView.snp.bottom).offset(12)
            } else {
                $0.top.equalTo(bodyLabel.snp.bottom).offset(10)
            }
            $0.bottom.equalTo(separatorView.snp.top).offset(-16)
        }
    }
}
