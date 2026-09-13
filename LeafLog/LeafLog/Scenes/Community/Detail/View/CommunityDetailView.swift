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

final class CommunityDetailView: UIView {
    enum CommentInputMode {
        case create
        case edit
    }
    
    let titleView = TitleHeaderView(text: "", hasBackButton: true, rightButtonImage: "more")
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
    
    private let commentInputWrapperView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.borderColor = UIColor.grayScale200.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }
    
    private let editCommentHeaderView = UIView().then {
        $0.backgroundColor = .grayScale100
        $0.isHidden = true
    }
    
    private let editCommentTitleLabel = UILabel(text: "댓글 수정 중", config: .body12, color: .grayScale700, lines: 1)
    
    fileprivate let cancelCommentEditingButton = UIButton(configuration: .plain()).then {
        $0.setImage(UIImage(resource: .x), for: .normal)
        $0.configuration?.baseForegroundColor = .grayScale600
        $0.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    
    fileprivate let inputTextField = DesignTextField().then {
        $0.backgroundColor = .white
        $0.layer.borderWidth = 0
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.setPlaceholder(text: "댓글을 입력해주세요.")
    }
    
    fileprivate let sendButton = UIButton(type: .custom).then {
        $0.backgroundColor = .grayScale100
        $0.layer.cornerRadius = 23
        $0.clipsToBounds = true
        $0.setImage(UIImage(named: "send")?.withRenderingMode(.alwaysTemplate), for: .normal)
        $0.tintColor = .grayScale500
    }
    
    private var commentCollectionHeightConstraint: Constraint?
    private var commentInputWrapperHeightConstraint: Constraint?
    private var inputTextFieldTopConstraint: Constraint?
    private var isEditingComment = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
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
    
    func updateSendButton(isEnabled: Bool) {
        sendButton.backgroundColor = isEnabled ? .primary200 : .grayScale100
        sendButton.tintColor = isEnabled ? .primary800 : .grayScale500
    }
    
    func setCommentInputMode(_ mode: CommentInputMode) {
        isEditingComment = mode == .edit
        editCommentHeaderView.isHidden = !isEditingComment
        commentInputWrapperHeightConstraint?.update(offset: isEditingComment ? 78 : 44)
        inputTextFieldTopConstraint?.update(offset: isEditingComment ? 28 : 0)
        inputTextField.setPlaceholder(text: isEditingComment ? "" : "댓글을 입력해주세요.")
        inputTextField.setContentInsets(
            isEditingComment
                ? UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
                : UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        )
        sendButton.setImage(sendButtonImage(for: mode), for: .normal)
        updateSendButton(
            isEnabled: (inputTextField.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty == false
        )
        layoutIfNeeded()
    }
    
    func setCommentText(_ text: String) {
        guard inputTextField.text != text else { return }
        
        inputTextField.text = text
        updateSendButton(isEnabled: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
    }
    
    func isNearBottom(threshold: CGFloat) -> Bool {
        let visibleBottom = scrollView.contentOffset.y + scrollView.bounds.height
        let triggerOffset = scrollView.contentSize.height - threshold
        
        return visibleBottom >= triggerOffset
    }
    
    private func sendButtonImage(for mode: CommentInputMode) -> UIImage? {
        switch mode {
        case .create:
            UIImage(named: "send")?.withRenderingMode(.alwaysTemplate)
        case .edit:
            UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)
        }
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
            $0.bottom.equalTo(safeAreaLayoutGuide)
            $0.height.equalTo(86)
        }
        
        inputContainerView.addSubview(commentInputWrapperView)
        inputContainerView.addSubview(sendButton)
        commentInputWrapperView.addSubview(editCommentHeaderView)
        editCommentHeaderView.addSubview(editCommentTitleLabel)
        editCommentHeaderView.addSubview(cancelCommentEditingButton)
        commentInputWrapperView.addSubview(inputTextField)
        
        commentInputWrapperView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(14)
            $0.trailing.equalTo(sendButton.snp.leading).offset(-12)
            commentInputWrapperHeightConstraint = $0.height.equalTo(48).constraint
        }
        
        editCommentHeaderView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(28)
        }
        
        editCommentTitleLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().inset(12)
        }
        
        cancelCommentEditingButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(8)
            $0.width.height.equalTo(24)
        }
        
        cancelCommentEditingButton.imageView?.snp.makeConstraints {
            $0.width.height.equalTo(10)
        }
        
        inputTextField.snp.makeConstraints {
            inputTextFieldTopConstraint = $0.top.equalToSuperview().constraint
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
        sendButton.snp.makeConstraints {
            $0.centerY.equalTo(commentInputWrapperView)
            $0.trailing.equalToSuperview().inset(16)
            $0.width.height.equalTo(46)
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
    
    var profileImageTap: ControlEvent<Void> {
        base.postContentView.rx.profileImageTap
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
    
    var cancelCommentEditingButtonTap: ControlEvent<Void> {
        base.cancelCommentEditingButton.rx.tap
    }
    
    var commentText: ControlProperty<String?> {
        base.inputTextField.rx.text
    }
    
    var didScroll: ControlEvent<Void> {
        base.scrollView.rx.didScroll
    }
}
