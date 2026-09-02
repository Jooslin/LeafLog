//
//  CommunityPostContentView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 8/19/26.
//

import RxCocoa
import RxSwift
import Kingfisher
import SnapKit
import Then
import UIKit

final class CommunityPostContentView: UIView {
    fileprivate let postImageTapRelay = PublishRelay<Int>()
    
    private let categoryLabel = PaddingLabel(horizontalInset: 9, verticalInset: 5).then {
        $0.apply(.label12, color: .primary800, lines: 1)
        $0.backgroundColor = .primary200
        $0.layer.cornerRadius = 11
        $0.clipsToBounds = true
    }
    
    private let postTitleLabel = UILabel(
        config: .headline18,
        color: .black,
        lines: 0
    )
    
    private let profileImageView = UIImageView().then {
        $0.image = UIImage(named: "non_profile")
        $0.backgroundColor = .grayScale100
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 11
        $0.clipsToBounds = true
    }
    
    fileprivate let profileImageButton = UIButton(type: .custom).then {
        $0.backgroundColor = .clear
    }
    
    private let nicknameLabel = UILabel(config: .body12, color: .grayScale800, lines: 1)
    private let dateLabel = UILabel(config: .body12, color: .grayScale600, lines: 1)
    
    private let postBodyLabel = UILabel(
        config: .body14,
        color: .grayScale600,
        lines: 0
    ).then {
        $0.lineBreakMode = .byWordWrapping
    }
    
    private let imageStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 12
        $0.distribution = .fill
    }
    
    private let imageScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceHorizontal = true
    }
    
    private let heartImageView = UIImageView(image: UIImage(systemName: "heart")).then {
        $0.tintColor = .black
        $0.contentMode = .scaleAspectFit
    }
    
    fileprivate let heartButton = UIButton(type: .custom).then {
        $0.backgroundColor = .clear
    }
    
    private let heartCountLabel = UILabel(text: "N", config: .body12, color: .black, lines: 1)
    
    private let commentImageView = UIImageView(image: UIImage(systemName: "message")).then {
        $0.tintColor = .black
        $0.contentMode = .scaleAspectFit
    }
    
    fileprivate let commentButton = UIButton(type: .custom).then {
        $0.backgroundColor = .clear
    }
    
    private let commentCountLabel = UILabel(text: "N", config: .body12, color: .black, lines: 1)
    private var imageButtonDisposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(post: CommunityDetailReactor.Post) {
        categoryLabel.text = post.category
        postTitleLabel.text = post.title
        nicknameLabel.text = post.nickname
        configureProfileImage(with: post.profileImageURL)
        dateLabel.text = post.date
        postBodyLabel.setTextWithLineHeight(text: post.body, height: 22)
        heartCountLabel.text = post.likeCount
        commentCountLabel.text = post.commentCount
        configureHeart(isLiked: post.isLiked)
        configurePostImages(imageURLs: post.imageURLs)
    }
    
    private func setLayout() {
        let metaDividerView = UIView().then {
            $0.backgroundColor = .grayScale100
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
        authorStackView.addSubview(profileImageButton)
        
        let heartIconContainerView = UIView().then {
            $0.addSubview(heartImageView)
            $0.addSubview(heartButton)
        }
        
        let heartStackView = UIStackView(arrangedSubviews: [heartIconContainerView, heartCountLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 0
            $0.alignment = .center
        }
        
        let commentIconContainerView = UIView().then {
            $0.addSubview(commentImageView)
            $0.addSubview(commentButton)
        }
        
        let commentStackView = UIStackView(arrangedSubviews: [commentIconContainerView, commentCountLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 0
            $0.alignment = .center
        }
        
        let reactionStackView = UIStackView(arrangedSubviews: [heartStackView, commentStackView]).then {
            $0.axis = .horizontal
            $0.spacing = 16
            $0.alignment = .center
        }
        
        let reactionContainerView = UIView().then {
            $0.addSubview(reactionStackView)
        }
        
        let postStackView = UIStackView(arrangedSubviews: [
            categoryLabel,
            postTitleLabel,
            authorStackView,
            postBodyLabel,
            imageScrollView,
            reactionContainerView
        ]).then {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.spacing = 16
        }
        
        addSubview(postStackView)
        
        postStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        categoryLabel.snp.makeConstraints {
            $0.height.equalTo(22)
        }
        
        profileImageView.snp.makeConstraints {
            $0.width.height.equalTo(20)
        }
        
        profileImageButton.snp.makeConstraints {
            $0.leading.verticalEdges.equalToSuperview()
            $0.trailing.equalTo(nicknameLabel)
        }
        
        metaDividerView.snp.makeConstraints {
            $0.width.equalTo(1)
            $0.height.equalTo(12)
        }
        
        imageScrollView.addSubview(imageStackView)
        
        imageScrollView.snp.makeConstraints {
            $0.height.equalTo(104)
            $0.width.equalToSuperview()
        }
        
        imageStackView.snp.makeConstraints {
            $0.edges.equalTo(imageScrollView.contentLayoutGuide)
            $0.height.equalTo(imageScrollView.frameLayoutGuide)
        }
        
        reactionContainerView.snp.makeConstraints {
            $0.width.equalToSuperview()
        }
        
        reactionStackView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview()
            $0.trailing.equalToSuperview()
        }
        
        heartIconContainerView.snp.makeConstraints {
            $0.width.height.equalTo(32)
        }
        
        heartImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        
        heartButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        commentIconContainerView.snp.makeConstraints {
            $0.width.height.equalTo(32)
        }
        
        commentImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        
        commentButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func configureHeart(isLiked: Bool) {
        heartImageView.image = UIImage(systemName: isLiked ? "heart.fill" : "heart")
        heartImageView.tintColor = isLiked ? .systemRed : .black
    }
    
    private func configureProfileImage(with profileImageURL: URL?) {
        let placeholderImage = UIImage(named: "non_profile")
        profileImageView.kf.cancelDownloadTask()
        
        guard let profileImageURL else {
            profileImageView.image = placeholderImage
            return
        }
        
        profileImageView.kf.setImage(
            with: profileImageURL,
            placeholder: placeholderImage,
            options: [
                .cacheOriginalImage,
                .transition(.fade(0.2))
            ]
        )
    }
    
    private func configurePostImages(imageURLs: [URL]) {
        imageButtonDisposeBag = DisposeBag()
        imageScrollView.isHidden = imageURLs.isEmpty
        imageScrollView.setContentOffset(.zero, animated: false)
        
        imageStackView.arrangedSubviews.forEach {
            imageStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        imageURLs.enumerated().forEach { index, imageURL in
            let imageView = UIImageView().then {
                $0.contentMode = .scaleAspectFill
                $0.image = UIImage(resource: .placeholder)
                $0.backgroundColor = .grayScale100
                $0.layer.cornerRadius = 8
                $0.clipsToBounds = true
            }
            
            let imageButton = UIButton(type: .custom).then {
                $0.backgroundColor = .clear
            }
            
            let imageContainerView = UIView().then {
                $0.addSubview(imageView)
                $0.addSubview(imageButton)
            }
            
            imageView.kf.setImage(
                with: imageURL,
                placeholder: UIImage(resource: .placeholder),
                options: [
                    .cacheOriginalImage,
                    .transition(.fade(0.2))
                ]
            )
            
            imageButton.rx.tap
                .map { index }
                .bind(to: postImageTapRelay)
                .disposed(by: imageButtonDisposeBag)
            
            imageContainerView.snp.makeConstraints {
                $0.width.height.equalTo(104)
            }
            
            imageView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            
            imageButton.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            
            imageStackView.addArrangedSubview(imageContainerView)
        }
    }
}

extension Reactive where Base: CommunityPostContentView {
    var postImageTap: ControlEvent<Int> {
        ControlEvent(events: base.postImageTapRelay.asObservable())
    }
    
    var profileImageTap: ControlEvent<Void> {
        base.profileImageButton.rx.tap
    }
    
    var heartButtonTap: ControlEvent<Void> {
        base.heartButton.rx.tap
    }
    
    var commentButtonTap: ControlEvent<Void> {
        base.commentButton.rx.tap
    }
}
