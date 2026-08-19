//
//  CommunityPostContentView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 8/19/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class CommunityPostContentView: UIView {
    fileprivate let postImageTapRelay = PublishRelay<Int>()
    
    private let categoryLabel = PaddingLabel(horizontalInset: 9, verticalInset: 5).then {
        $0.apply(.label12, color: .primary700, lines: 1)
        $0.backgroundColor = .primary100
        $0.layer.cornerRadius = 11
        $0.clipsToBounds = true
    }
    
    private let postTitleLabel = UILabel(
        config: .headline18,
        color: .black,
        lines: 0
    )
    
    private let profileImageView = UIView().then {
        $0.backgroundColor = .grayScale100
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    private let nicknameLabel = UILabel(config: .body12, color: .grayScale600, lines: 1)
    private let dateLabel = UILabel(config: .body12, color: .grayScale500, lines: 1)
    
    private let postBodyLabel = UILabel(
        config: .body14,
        color: .grayScale700,
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
    
    fileprivate let heartButton = UIButton(configuration: .plain()).then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
        $0.configuration?.baseForegroundColor = .black
        $0.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    
    private let heartCountLabel = UILabel(text: "N", config: .body12, color: .black, lines: 1)
    
    fileprivate let commentButton = UIButton(configuration: .plain()).then {
        $0.setImage(UIImage(systemName: "bubble"), for: .normal)
        $0.configuration?.baseForegroundColor = .black
        $0.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
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
        dateLabel.text = post.date
        postBodyLabel.setTextWithLineHeight(text: post.body, height: 22)
        heartCountLabel.text = post.likeCount
        commentCountLabel.text = post.commentCount
        configurePostImages(imageAssetNames: post.imageAssetNames)
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
        
        let heartStackView = UIStackView(arrangedSubviews: [heartButton, heartCountLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 3
            $0.alignment = .center
        }
        
        let commentStackView = UIStackView(arrangedSubviews: [commentButton, commentCountLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 3
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
        
        heartButton.snp.makeConstraints {
            $0.width.height.equalTo(25)
        }
        
        commentButton.snp.makeConstraints {
            $0.width.height.equalTo(25)
        }
    }
    
    private func configurePostImages(imageAssetNames: [String]) {
        imageButtonDisposeBag = DisposeBag()
        imageScrollView.isHidden = imageAssetNames.isEmpty
        imageScrollView.setContentOffset(.zero, animated: false)
        
        imageStackView.arrangedSubviews.forEach {
            imageStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        imageAssetNames.enumerated().forEach { index, imageAssetName in
            let imageButton = UIButton(type: .custom).then {
                $0.setImage(UIImage(named: imageAssetName) ?? UIImage(resource: .placeholder), for: .normal)
                $0.imageView?.contentMode = .scaleAspectFill
                $0.imageView?.clipsToBounds = true
                $0.backgroundColor = .grayScale100
                $0.layer.cornerRadius = 8
                $0.clipsToBounds = true
            }
            
            imageButton.rx.tap
                .map { index }
                .bind(to: postImageTapRelay)
                .disposed(by: imageButtonDisposeBag)
            
            imageButton.snp.makeConstraints {
                $0.width.height.equalTo(104)
            }
            imageStackView.addArrangedSubview(imageButton)
        }
    }
}

extension Reactive where Base: CommunityPostContentView {
    var postImageTap: ControlEvent<Int> {
        ControlEvent(events: base.postImageTapRelay.asObservable())
    }
    
    var heartButtonTap: ControlEvent<Void> {
        base.heartButton.rx.tap
    }
    
    var commentButtonTap: ControlEvent<Void> {
        base.commentButton.rx.tap
    }
}
