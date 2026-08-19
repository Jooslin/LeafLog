//
//  CommunityPostCell.swift
//  LeafLog
//
//  Created by 김주희 on 8/19/26.
//

import SnapKit
import Then
import UIKit
import Kingfisher

final class CommunityPostCell: UICollectionViewCell {
    private let categoryButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.filled()
        configuration.baseForegroundColor = .primary800
        configuration.background.backgroundColor = .primary200
        configuration.background.cornerRadius = 10
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 4,
            leading: 8,
            bottom: 4,
            trailing: 8
        )
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            return attributes
        }
        $0.configuration = configuration
        $0.isUserInteractionEnabled = false
    }

    private let titleLabel = UILabel(config: .title16, lines: 1).then {
        $0.lineBreakMode = .byTruncatingTail
    }

    private let profileImageView = UIImageView().then {
        $0.backgroundColor = .grayScale100
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 11
        $0.image = .userEmpty
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
        image: .chat.withRenderingMode(.alwaysTemplate)
    ).then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .grayScale400
    }

    private let commentCountLabel = UILabel(config: .body12, color: .grayScale400, lines: 1)

    private let separatorView = SeparateBar()

    private lazy var metadataStackView = UIStackView(
        arrangedSubviews: [profileImageView, nicknameLabel, metadataSeparator, dateLabel]
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
        profileImageView.kf.cancelDownloadTask()
        profileImageView.image = .userEmpty
        postImageView.kf.cancelDownloadTask()
        postImageView.image = nil
        postImageView.isHidden = false
    }

    func configure(
        with post: CommunityPost,
        nickname: String?,
        profileImageURL: URL?,
        postImageURL: URL?,
        showsCategory: Bool,
        showsSeparator: Bool
    ) {
        categoryButton.setTitle(post.category.title)
        categoryButton.isHidden = !showsCategory
        titleLabel.text = post.title
        nicknameLabel.text = nickname ?? "알 수 없는 사용자"
        dateLabel.text = Self.dateFormatter.string(from: post.createdAt)
        bodyLabel.text = post.content
        likeCountLabel.text = String(post.likeCount)
        commentCountLabel.text = String(post.commentCount ?? 0)
        commentStackView.isHidden = false
        separatorView.isHidden = !showsSeparator

        profileImageView.kf.setImage(
            with: profileImageURL,
            placeholder: UIImage.userEmpty,
            options: [
                .cacheOriginalImage,
                .transition(.fade(0.2))
            ]
        )

        let hasImage = postImageURL != nil
        postImageView.isHidden = !hasImage
        postImageView.kf.setImage(with: postImageURL)
        updateTextLayout(hasImage: hasImage, showsCategory: showsCategory)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    private func setupUI() {
        [
            categoryButton,
            titleLabel,
            metadataStackView,
            bodyLabel,
            postImageView,
            reactionStackView,
            separatorView
        ].forEach(contentView.addSubview)

        profileImageView.snp.makeConstraints {
            $0.size.equalTo(22)
        }

        metadataSeparator.snp.makeConstraints {
            $0.width.equalTo(1)
            $0.height.equalTo(12)
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

        updateTextLayout(hasImage: true, showsCategory: false)
    }

    private func updateTextLayout(hasImage: Bool, showsCategory: Bool) {
        let trailingInset: CGFloat = hasImage ? 116 : 0

        categoryButton.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview()
            $0.height.equalTo(22)
        }

        titleLabel.snp.remakeConstraints {
            if showsCategory {
                $0.top.equalTo(categoryButton.snp.bottom).offset(8)
            } else {
                $0.top.equalToSuperview().offset(16)
            }
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview().inset(trailingInset)
        }

        postImageView.snp.remakeConstraints {
            if showsCategory {
                $0.top.equalTo(categoryButton.snp.bottom).offset(8)
            } else {
                $0.top.equalToSuperview().offset(16)
            }
            $0.trailing.equalToSuperview()
            $0.size.equalTo(100)
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
