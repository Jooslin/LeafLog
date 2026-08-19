//
//  CommunityDetailView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 7/7/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

// TODO: inputTextField 컴포넌트로 바꿔끼기

final class CommunityDetailView: UIView {
    let titleView = TitleHeaderView(text: "", hasBackButton: true, rightButtonImage: nil)
    let postContentView = CommunityPostContentView()
    
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
    
    fileprivate let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .interactive
    }
    
    private let contentView = UIView()
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
    
    fileprivate let sendButton = UIButton(configuration: .plain()).then {
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
    
    func configure(post: CommunityDetailReactor.Post) {
        postContentView.configure(post: post)
    }
    
    func updateCommentCollectionHeight(itemCount: Int) {
        commentCollectionHeightConstraint?.update(offset: CGFloat(itemCount) * 70)
        setNeedsLayout()
    }
    
    func isNearBottom(threshold: CGFloat) -> Bool {
        let visibleBottom = scrollView.contentOffset.y + scrollView.bounds.height
        let triggerOffset = scrollView.contentSize.height - threshold
        
        return visibleBottom >= triggerOffset
    }
}

// MARK: - Layout
private extension CommunityDetailView {
    func setLayout() {
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
        contentView.addSubview(postContentView)
        contentView.addSubview(sectionDividerView)
        contentView.addSubview(commentTitleLabel)
        contentView.addSubview(commentCollectionView)
        
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        postContentView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(28)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        sectionDividerView.snp.makeConstraints {
            $0.top.equalTo(postContentView.snp.bottom).offset(24)
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
    
    func configureTitleView() {
        titleView.titleLabel.text = ""
        titleView.rightButton.isHidden = false
        titleView.rightButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        titleView.rightButton.configuration?.baseForegroundColor = .black
    }
    
    static func makeCommentLayout() -> UICollectionViewLayout {
        UICollectionViewFlowLayout().then {
            $0.scrollDirection = .vertical
            $0.minimumLineSpacing = 0
            $0.estimatedItemSize = .zero
        }
    }
}

extension Reactive where Base: CommunityDetailView {
    var moreButtonTap: ControlEvent<Void> {
        base.titleView.rightButton.rx.tap
    }
    
    var postImageTap: ControlEvent<Int> {
        base.postContentView.rx.postImageTap
    }
    
    var heartButtonTap: ControlEvent<Void> {
        base.postContentView.rx.heartButtonTap
    }
    
    var commentButtonTap: ControlEvent<Void> {
        base.postContentView.rx.commentButtonTap
    }
    
    var sendButtonTap: ControlEvent<Void> {
        base.sendButton.rx.tap
    }
    
    var didScroll: ControlEvent<Void> {
        base.scrollView.rx.didScroll
    }
}
