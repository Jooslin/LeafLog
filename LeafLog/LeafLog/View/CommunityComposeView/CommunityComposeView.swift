//
//  CommunityComposeView.swift
//  LeafLog
//
//  Created by 변예린 on 7/1/26.
//

import UIKit
import Kingfisher
import SnapKit
import Then

final class CommunityComposeView: UIView {
    // MARK: - UI Components
    let titleView = TitleHeaderView(text: "", hasBackButton: true, rightButtonImage: "helpCircle")
    
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
    }
    private let contentView = UIView()
    
    let categoryDailyButton = UIButton(config: .lSize, title: "식물 일상").then {
        $0.layer.cornerRadius = 8
    }
    let categoryQuestionButton = UIButton(config: .lSize, title: "식물 고민").then {
        $0.layer.cornerRadius = 8
    }
    let categoryPlanetButton = UIButton(config: .lSize, title: "초록별 여행").then {
        $0.layer.cornerRadius = 8
    }
    
    let titleTextField = DesignTextField().then {
        $0.placeholder = "제목을 입력해주세요."
    }

    let bodyTextView = UITextView().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .label
        $0.backgroundColor = .grayScale50
        $0.layer.borderColor = UIColor.grayScale100.cgColor
        $0.layer.borderWidth = 1
        
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true

        $0.isScrollEnabled = true
        $0.showsVerticalScrollIndicator = false
        $0.textContainerInset = UIEdgeInsets(
            top: 12,
            left: 12,
            bottom: 12,
            right: 12
        )
        $0.textContainer.lineFragmentPadding = 0
    }
    
    private let bodyPlaceholderLabel = UILabel(text: "게시글 내용을 입력해주세요.", config: .body14, color: .grayScale300)
    
    let saveButton = BottomSaveButton(title: "")
    
    //MARK: init
    init(mode: Mode) {
        super.init(frame: .zero)
        
        switch mode {
        case .create:
            titleView.titleLabel.text = "게시글 작성"
            saveButton.setTitle("등록하기")
        case .edit:
            titleView.titleLabel.text = "게시글 수정"
            saveButton.setTitle("수정하기")
        }
        
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayout() {
        let buttonStack = UIStackView(arrangedSubviews: [categoryDailyButton, categoryQuestionButton, categoryPlanetButton]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .fill
        }
        
        let categoryStack = makeVerticalStackView(title: "카테고리*", style: .attributed, views: [buttonStack])
        let titleStack = makeVerticalStackView(title: "제목*", style: .attributed, views: [titleTextField])
        //TODO: custom comp 만들기
        let pictureStack = makeVerticalStackView(title: "사진 첨부 (선택)", style: .plain, views: [])
        let bodyStack = makeVerticalStackView(title: "내용*", style: .attributed, views: [bodyTextView])
        
        let stackView = UIStackView(arrangedSubviews: [categoryStack, titleStack, pictureStack, bodyStack]).then {
            $0.axis = .vertical
            $0.spacing = 32
            $0.alignment = .leading
        }
        
        addSubview(titleView)
        addSubview(scrollView)
        addSubview(saveButton)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.greaterThanOrEqualTo(saveButton.snp.top).inset(24)
        }
        
        saveButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(24)
            $0.height.equalTo(48)
        }
        
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.snp.width)
        }
        
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.verticalEdges.equalToSuperview().inset(32)
        }
        
        categoryStack.snp.makeConstraints {
            $0.width.equalToSuperview()
        }
        
        buttonStack.snp.makeConstraints {
            $0.height.equalTo(36)
        }
        
        titleStack.snp.makeConstraints {
            $0.width.equalToSuperview()
        }
        
        bodyStack.snp.makeConstraints {
            $0.width.equalToSuperview()
        }
        
        bodyTextView.addSubview(bodyPlaceholderLabel)
        
        bodyTextView.snp.makeConstraints {
            $0.height.equalTo(140)
        }
        
        bodyPlaceholderLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview().inset(12)
        }
    }
 
}

//MARK: Components
extension CommunityComposeView {
    private func makeAttributedTitle(text: String) -> UILabel {
        let label = UILabel(config: .title14)
        let attributedString = NSMutableAttributedString(string: text)
        
        if let starRange = text.range(of: "*") {
            let nsRange = NSRange(starRange, in: text)
            
            // 별 색상 설정
            attributedString.addAttribute(
                .foregroundColor,
                value: UIColor.subRed,
                range: nsRange
            )
            
            // 폰트 설정
            attributedString.addAttribute(
                .font,
                value: label.font as Any,
                range: NSRange(location: 0, length: attributedString.length)
            )
        }
        
        label.attributedText = attributedString
        
        return label
    }
    
    private func makeVerticalStackView(title: String, style: TitleStyle, views: [UIView]) -> UIStackView {
        let titleLabel = switch style {
        case .plain:
            UILabel(text: title, config: .title14)
        case .attributed:
            makeAttributedTitle(text: title)
        }
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel] + views).then {
            $0.axis = .vertical
            $0.spacing = 16
            
            titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            titleLabel.setContentHuggingPriority(.required, for: .vertical)
        }
        
        return stackView
    }
}

//MARK: Types
extension CommunityComposeView {
    enum Mode {
        case create
        case edit
    }
    
    enum TitleStyle {
        case plain
        case attributed
    }
}
