//
//  CommunityDetailView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 7/7/26.
//

import SnapKit
import Then
import UIKit

final class CommunityDetailView: UIView {
    let titleView = TitleHeaderView(text: "", hasBackButton: true, rightButtonImage: nil)
    
    let commentCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: CommunityDetailView.makeCommentLayout()
    ).then {
        $0.backgroundColor = .white
        $0.isScrollEnabled = false
        $0.showsVerticalScrollIndicator = false
        $0.register(
            CommunityCommentCell.self,
            forCellWithReuseIdentifier: CommunityCommentCell.reuseIdentifier
        )
    }
    
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .interactive
    }
    
    private let contentView = UIView()
    
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
        $0.distribution = .fillEqually
    }
    
    private let heartButton = UIButton(configuration: .plain()).then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
        $0.configuration?.baseForegroundColor = .black
        $0.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    
    private let heartCountLabel = UILabel(text: "N", config: .body12, color: .black, lines: 1)
    
    private let commentButton = UIButton(configuration: .plain()).then {
        $0.setImage(UIImage(systemName: "bubble"), for: .normal)
        $0.configuration?.baseForegroundColor = .black
        $0.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    
    private let commentCountLabel = UILabel(text: "N", config: .body12, color: .black, lines: 1)
    
    private let commentTitleLabel = UILabel(text: "댓글", config: .title14, color: .black, lines: 1)
    
    private let inputContainerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.borderColor = UIColor.grayScale100.cgColor
        $0.layer.borderWidth = 1 / UIScreen.main.scale
    }
    
    private let inputTextField = UITextField().then {
        $0.placeholder = "댓글을 입력해주세요."
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .black
        $0.backgroundColor = .white
        $0.layer.borderColor = UIColor.grayScale200.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 12
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        $0.leftViewMode = .always
    }
    
    private let sendButton = UIButton(configuration: .plain()).then {
        $0.backgroundColor = .grayScale100
        $0.layer.cornerRadius = 20
        $0.clipsToBounds = true
        $0.setImage(UIImage(systemName: "paperplane"), for: .normal)
        $0.configuration?.baseForegroundColor = .grayScale500
        $0.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    
    private var commentCollectionHeightConstraint: Constraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        configureTitleView()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateCommentCollectionHeight(itemCount: Int) {
        commentCollectionHeightConstraint?.update(offset: CGFloat(itemCount) * 70)
        layoutIfNeeded()
    }
}

// MARK: - Layout
extension CommunityDetailView {
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
        
        let postStackView = UIStackView(arrangedSubviews: [
            categoryLabel,
            postTitleLabel,
            authorStackView,
            postBodyLabel,
            imageStackView,
            reactionStackView
        ]).then {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.spacing = 16
        }
        
        let sectionDividerView = UIView().then {
            $0.backgroundColor = .grayScale100
        }
        
        addSubview(titleView)
        addSubview(scrollView)
        addSubview(inputContainerView)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(inputContainerView.snp.top)
        }
        
        inputContainerView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(86)
        }
        
        inputContainerView.addSubview(inputTextField)
        inputContainerView.addSubview(sendButton)
        
        inputTextField.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(14)
            $0.trailing.equalTo(sendButton.snp.leading).offset(-12)
            $0.height.equalTo(44)
        }
        
        sendButton.snp.makeConstraints {
            $0.centerY.equalTo(inputTextField)
            $0.trailing.equalToSuperview().inset(16)
            $0.width.height.equalTo(40)
        }
        
        scrollView.addSubview(contentView)
        contentView.addSubview(postStackView)
        contentView.addSubview(sectionDividerView)
        contentView.addSubview(commentTitleLabel)
        contentView.addSubview(commentCollectionView)
        
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.snp.width)
        }
        
        postStackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(28)
            $0.horizontalEdges.equalToSuperview().inset(16)
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
        
        imageStackView.snp.makeConstraints {
            $0.height.equalTo(104)
            $0.width.equalToSuperview()
        }
        
        reactionStackView.snp.makeConstraints {
            $0.trailing.equalTo(postStackView.snp.trailing)
        }
        
        heartButton.snp.makeConstraints {
            $0.width.height.equalTo(20)
        }
        
        commentButton.snp.makeConstraints {
            $0.width.height.equalTo(20)
        }
        
        sectionDividerView.snp.makeConstraints {
            $0.top.equalTo(postStackView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(1)
        }
        
        commentTitleLabel.snp.makeConstraints {
            $0.top.equalTo(sectionDividerView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        commentCollectionView.snp.makeConstraints {
            $0.top.equalTo(commentTitleLabel.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview()
            commentCollectionHeightConstraint = $0.height.equalTo(280).constraint
            $0.bottom.equalToSuperview().inset(8)
        }
    }
}

// MARK: - Configure
extension CommunityDetailView {
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
    
    private func configureTitleView() {
        titleView.titleLabel.text = ""
        titleView.rightButton.isHidden = false
        titleView.rightButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        titleView.rightButton.configuration?.baseForegroundColor = .black
    }
    
    private func configurePostImages(imageAssetNames: [String]) {
        imageStackView.arrangedSubviews.forEach {
            imageStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        imageAssetNames.prefix(3).forEach { imageAssetName in
            let imageView = UIImageView().then {
                $0.image = UIImage(named: imageAssetName) ?? UIImage(resource: .placeholder)
                $0.contentMode = .scaleAspectFill
                $0.backgroundColor = .grayScale100
                $0.layer.cornerRadius = 8
                $0.clipsToBounds = true
            }
            imageStackView.addArrangedSubview(imageView)
        }
    }
    
    private static func makeCommentLayout() -> UICollectionViewLayout {
        UICollectionViewFlowLayout().then {
            $0.scrollDirection = .vertical
            $0.minimumLineSpacing = 0
            $0.estimatedItemSize = .zero
        }
    }
}

private final class PaddingLabel: UILabel {
    private let horizontalInset: CGFloat
    private let verticalInset: CGFloat
    
    init(horizontalInset: CGFloat, verticalInset: CGFloat) {
        self.horizontalInset = horizontalInset
        self.verticalInset = verticalInset
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + horizontalInset * 2,
            height: size.height + verticalInset * 2
        )
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
        super.drawText(in: rect.inset(by: insets))
    }
}
