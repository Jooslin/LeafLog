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
import RxCocoa
import RxSwift

final class CommunityComposeView: UIView {
    // MARK: - UI Components
    let titleView = TitleHeaderView(text: "", hasBackButton: true, rightButtonImage: "helpCircle")
    
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
    }
    private let contentView = UIView()
    
    let categoryDailyButton = UIButton(config: .lSize, title: PostCategory.plantLife.title).then {
        $0.layer.cornerRadius = 8
        $0.tag = PostCategory.plantLife.rawValue
    }
    let categoryQuestionButton = UIButton(config: .lSize, title: PostCategory.plantHelp.title).then {
        $0.layer.cornerRadius = 8
        $0.tag = PostCategory.plantHelp.rawValue
    }
    let categoryPlanetButton = UIButton(config: .lSize, title: PostCategory.greenTrip.title).then {
        $0.layer.cornerRadius = 8
        $0.tag = PostCategory.greenTrip.rawValue
    }
    
    let titleTextField = DesignTextField().then {
        $0.placeholder = "제목을 입력해주세요."
    }

    let pictureViews = [
        PictureComposeView(),
        PictureComposeView(),
        PictureComposeView()
    ]
    
    private let pictureNoticeLabel = UILabel(text: "최대 3장까지 첨부 가능", config: .body12, color: .grayScale300).then {
        $0.textAlignment = .right
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
    
    let bodyCountLabel = UILabel(config: .body12).then {
        $0.textAlignment = .right
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
        applyPictures([])
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
        
        let pictureSlots = pictureViews.map { pictureView in
            let slotView = UIView()
            slotView.addSubview(pictureView)

            pictureView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }

            return slotView
        }

        let pictureViewHorizontalStack = UIStackView(arrangedSubviews: pictureSlots).then {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.spacing = 12
            $0.alignment = .center
        }
        
        let pictureViewStack = UIStackView(arrangedSubviews: [pictureViewHorizontalStack, pictureNoticeLabel]).then {
            $0.axis = .vertical
            $0.spacing = 6
        }
        
        let bodyVerticalStack = UIStackView(arrangedSubviews: [bodyTextView, bodyCountLabel]).then {
            $0.axis = .vertical
            $0.spacing = 6
        }
        
        let categoryStack = makeVerticalStackView(title: "카테고리*", style: .attributed, views: [buttonStack])
        let titleStack = makeVerticalStackView(title: "제목*", style: .attributed, views: [titleTextField])
        let pictureStack = makeVerticalStackView(title: "사진 첨부 (선택)", style: .plain, views: [pictureViewStack])
        let bodyStack = makeVerticalStackView(title: "내용*", style: .attributed, views: [bodyVerticalStack])
        
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
            $0.bottom.equalTo(saveButton.snp.top).offset(-24)
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
        
        pictureStack.snp.makeConstraints {
            $0.width.equalTo(stackView.snp.width)
        }
        
        bodyStack.snp.makeConstraints {
            $0.width.equalToSuperview()
        }
        
        pictureSlots.forEach { slotView in
            slotView.snp.makeConstraints {
                $0.height.equalTo(slotView.snp.width)
            }
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

//MARK: Configure
extension CommunityComposeView {
    // Category
    func applySelectedCategory(_ category: PostCategory) {
        [categoryDailyButton, categoryQuestionButton, categoryPlanetButton].forEach {
            $0.isSelected = $0.tag == category.rawValue
        }
    }
    
    // Picture
    func applyPictures(_ pictures: [PictureComposeView.ImageSource]) {
        let visiblePictureCount = min(pictures.count + 1, pictureViews.count)

        for (index, pictureView) in pictureViews.enumerated() {
            let source = pictures.indices.contains(index)
                ? pictures[index]
                : nil
            pictureView.setImage(
                source,
                isOccupied: pictures.indices.contains(index)
            )
            pictureView.isHidden = index >= visiblePictureCount
        }
    }
    
    // TextView
    static let bodyMaxCount = 1000

    func updateCount(_ current: Int, max: Int = CommunityComposeView.bodyMaxCount) {
        if current >= max {
            let text = "최대 1,000자까지 입력할 수 있어요. \(current)/\(max)"
            bodyCountLabel.text = text
            bodyCountLabel.apply(.body12, color: .subRed)
        } else {
            let text = "\(current)/\(max)"
            let attributedString = NSMutableAttributedString(
                string: text,
                attributes: [
                    .foregroundColor: UIColor.grayScale300,
                    .font: UIFont.systemFont(ofSize: 12)
                ]
            )
            
            let currentRange = (text as NSString).range(of: "\(current)")
            attributedString.addAttribute(
                .foregroundColor,
                value: UIColor.grayScale900,
                range: currentRange
            )
            
            bodyCountLabel.attributedText = attributedString
        }
    }
    
    func updatePlaceholderVisibility(_ count: Int) {
        bodyPlaceholderLabel.isHidden = count > 0 ? true : false
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

//MARK: Reactive
extension Reactive where Base: CommunityComposeView {
    var categoryButtonTap: Observable<Int> {
        let dailyTap = base.categoryDailyButton.rx.tap
            .map { _ in base.categoryDailyButton.tag }
        
        let questionTap = base.categoryQuestionButton.rx.tap
            .map { _ in base.categoryQuestionButton.tag }
        
        let planetTap = base.categoryPlanetButton.rx.tap
            .map { _ in base.categoryPlanetButton.tag }
        
        return Observable.merge([dailyTap, questionTap, planetTap])
    }
    
    var pictureViewTap: Observable<Int> {
        Observable.merge(
            base.pictureViews.enumerated()
            .map { index, view in
                view.rx.tap.map { index }
            })
    }

    var pictureRemoveButtonTap: Observable<Int> {
        Observable.merge(
            base.pictureViews.enumerated()
            .map { index, view in
                view.rx.cancelButtonTap.map { index }
            })
    }

    var pictureViewLongPress: Observable<(
        index: Int,
        gesture: UILongPressGestureRecognizer
    )> {
        Observable.merge(
            base.pictureViews.enumerated()
            .map { index, view in
                view.rx.longPress.map { (index, $0) }
            })
    }
}
