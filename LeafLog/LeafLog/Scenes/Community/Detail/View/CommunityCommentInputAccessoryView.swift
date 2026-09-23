//
//  CommunityCommentInputAccessoryView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 9/23/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class CommunityCommentInputAccessoryView: UIView {
    enum CommentInputMode {
        case create
        case edit
    }
    
    private enum Metric {
        static let createHeight: CGFloat = 86
        static let editHeight: CGFloat = 112
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
    
    private var commentInputWrapperHeightConstraint: Constraint?
    private var inputTextFieldTopConstraint: Constraint?
    private var isEditingComment = false
    
    var preferredHeight: CGFloat {
        isEditingComment ? Metric.editHeight : Metric.createHeight
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: preferredHeight)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        layer.borderColor = UIColor.grayScale100.cgColor
        layer.borderWidth = 1 / UIScreen.main.scale
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: preferredHeight)
    }
    
    func applyPreferredHeight() {
        guard frame.height != preferredHeight else { return }
        
        frame.size.height = preferredHeight
    }
    
    func updateSendButton(isEnabled: Bool) {
        sendButton.backgroundColor = isEnabled ? .primary200 : .grayScale100
        sendButton.tintColor = isEnabled ? .primary800 : .grayScale500
    }
    
    func setCommentInputMode(_ mode: CommentInputMode) {
        isEditingComment = mode == .edit
        editCommentHeaderView.isHidden = !isEditingComment
        commentInputWrapperHeightConstraint?.update(offset: isEditingComment ? 78 : 48)
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
        applyPreferredHeight()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setCommentText(_ text: String) {
        guard inputTextField.text != text else { return }
        
        inputTextField.text = text
        updateSendButton(isEnabled: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
    }
    
    func focusCommentInput() {
        inputTextField.becomeFirstResponder()
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

private extension CommunityCommentInputAccessoryView {
    func setLayout() {
        addSubview(commentInputWrapperView)
        addSubview(sendButton)
        commentInputWrapperView.addSubview(editCommentHeaderView)
        editCommentHeaderView.addSubview(editCommentTitleLabel)
        editCommentHeaderView.addSubview(cancelCommentEditingButton)
        commentInputWrapperView.addSubview(inputTextField)
        
        commentInputWrapperView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(14)
            $0.bottom.lessThanOrEqualToSuperview().inset(16).priority(.high)
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
    }
}

extension Reactive where Base: CommunityCommentInputAccessoryView {
    var sendButtonTap: ControlEvent<Void> {
        base.sendButton.rx.tap
    }
    
    var cancelCommentEditingButtonTap: ControlEvent<Void> {
        base.cancelCommentEditingButton.rx.tap
    }
    
    var commentText: ControlProperty<String?> {
        base.inputTextField.rx.text
    }
}
