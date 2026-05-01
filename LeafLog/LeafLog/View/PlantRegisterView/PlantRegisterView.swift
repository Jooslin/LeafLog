//
//  PlantRegisterView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/17/26.
//

import SnapKit
import Then
import UIKit

final class PlantRegisterView: UIView {
    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .onDrag
    }

    let headerView = TitleHeaderView(text: "식물 등록", hasBackButton: true)

    private let contentView = UIView()

    let cameraButton = CameraProfileButton()

    private let plantTypeTitleLabel = PlantRegisterView.makeRequiredSectionLabel(text: "식물 종류")
    let plantTypeSearchBar = SearchBarView().then {
        $0.textField.placeholder = "식물을 검색해주세요."
        $0.textField.isUserInteractionEnabled = false
    }
    let plantTypeSearchButton = UIButton(type: .system).then {
        $0.backgroundColor = .clear
    }

    private let categoryTitleLabel = PlantRegisterView.makeRequiredSectionLabel(text: "식물 카테고리")
    let categoryButtons: [UIButton] = [
        UIButton(config: .lSize, title: "직립형"),
        UIButton(config: .lSize, title: "관목형"),
        UIButton(config: .lSize, title: "덩굴성"),
        UIButton(config: .lSize, title: "풀모양"),
        UIButton(config: .lSize, title: "로제트형"),
        UIButton(config: .lSize, title: "다육형")
    ]
    private let categoryGuideView = CategoryGuideView()

    private let plantNameTitleLabel = PlantRegisterView.makeRequiredSectionLabel(text: "식물 별명")
    let plantNameTextField = PlantRegisterView.makeTextField(placeholder: "식물의 별명을 입력해주세요.")

    private let locationTitleLabel = PlantRegisterView.makeRequiredSectionLabel(text: "위치")
    let locationButtons: [UIButton] = [
        UIButton(config: .lSize, title: "거실"),
        UIButton(config: .lSize, title: "침실"),
        UIButton(config: .lSize, title: "주방"),
        UIButton(config: .lSize, title: "베란다"),
        UIButton(config: .lSize, title: "화장실"),
        UIButton(config: .lSize, title: "현관")
    ]
    private let lightGuideView = LightGuideView()

    private let wateringCycleTitleLabel = PlantRegisterView.makeRequiredSectionLabel(text: "급수 주기")
    let wateringCycleTextField = PlantRegisterView.makeTextField(placeholder: "급수 주기").then {
        $0.keyboardType = .numberPad
    }
    private let wateringCycleUnitLabel = UILabel(text: "일마다", config: .title16, color: .grayScale500)
    let wateringGuideBannerView = WateringGuideView()

    private let lastWateredTitleLabel = PlantRegisterView.makeRequiredSectionLabel(text: "마지막 급수일")
    let lastWateredDateTextField = PlantRegisterView.makeTextField(placeholder: "년 / 월 / 일").then {
        $0.keyboardType = .numbersAndPunctuation
    }
    private let lastWateredDatePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .wheels
        $0.locale = Locale(identifier: "ko_KR")
        $0.timeZone = .current
        $0.maximumDate = Date()
    }
    private lazy var lastWateredDateInputView = UIView(
        frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 304)
    ).then {
        $0.backgroundColor = .systemBackground
        $0.autoresizingMask = [.flexibleWidth]

        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(didTapLastWateredDateDone))
        ]

        $0.addSubview(toolbar)
        $0.addSubview(lastWateredDatePicker)

        toolbar.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(44)
        }

        lastWateredDatePicker.snp.makeConstraints {
            $0.top.equalTo(toolbar.snp.bottom)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    private let firstMetDateTitleLabel = PlantRegisterView.makeRequiredSectionLabel(text: "데려 온 날")
    let firstMetDateTextField = PlantRegisterView.makeTextField(placeholder: "년 / 월 / 일").then {
        $0.keyboardType = .numbersAndPunctuation
    }
    private let firstMetDatePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .wheels
        $0.locale = Locale(identifier: "ko_KR")
        $0.timeZone = .current
        $0.maximumDate = Date()
    }
    private lazy var firstMetDateInputView = UIView(
        frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 304)
    ).then {
        $0.backgroundColor = .systemBackground
        $0.autoresizingMask = [.flexibleWidth]

        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(didTapFirstMetDateDone))
        ]

        $0.addSubview(toolbar)
        $0.addSubview(firstMetDatePicker)

        toolbar.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(44)
        }

        firstMetDatePicker.snp.makeConstraints {
            $0.top.equalTo(toolbar.snp.bottom)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    let registerButton = BottomSaveButton(title: "등록하기")
    var onLastWateredDateDone: ((Date) -> Void)?
    var onFirstMetDateDone: ((Date) -> Void)?

    private let formStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = Layout.sectionSpacing
    }

    private lazy var categoryStackView = makeSelectionGrid(buttons: categoryButtons)
    private lazy var locationStackView = makeSelectionGrid(buttons: locationButtons)
    private lazy var wateringCycleInputStackView = UIStackView(
        arrangedSubviews: [wateringCycleTextField, wateringCycleUnitLabel]
    ).then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = Layout.guideSpacing
    }
    private lazy var lastWateredDateFieldContainer = makeLeadingAlignedContainer(for: lastWateredDateTextField)
    private lazy var firstMetDateFieldContainer = makeLeadingAlignedContainer(for: firstMetDateTextField)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupSelectionState()
        setupUI()
        setupDateInputViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureHeader(title: String, buttonTitle: String, showsDeleteButton: Bool) {
        headerView.titleLabel.text = title
        headerView.rightButton.isHidden = !showsDeleteButton
        headerView.rightButton.setImage(UIImage(systemName: "trash"), for: .normal)
        headerView.rightButton.configuration?.baseForegroundColor = .black
        headerView.rightButton.accessibilityLabel = "식물 삭제"
        registerButton.setTitle(buttonTitle, for: .normal)
    }

    // 선택된 식물에 대한 정보 반영
    func applySelectedPlant(
        name: String,
        growStyle: String?,
        lightDemand: String?,
        springWaterCycle: String?,
        selectedCategory: PlantCategory?
    ) {
        plantTypeSearchBar.textField.text = name
        if let suggestedWateringCycle = WateringGuideView.suggestedInputValue(from: springWaterCycle) {
            wateringCycleTextField.text = suggestedWateringCycle
        } else {
            wateringCycleTextField.text = nil
        }

        // 카테고리가 기타일 경우 비활성화
        if selectedCategory == .other {
            categoryButtons.forEach {
                $0.isSelected = false
                $0.isEnabled = false
            }
            categoryGuideView.configure(plantName: nil, category: nil)
            lightGuideView.configure(plantName: name, lightDemand: lightDemand)
            wateringGuideBannerView.configure(plantName: name, springWaterCycle: springWaterCycle)
            return
        }

        categoryButtons.forEach { $0.isEnabled = true }

        if let category = PlantCategoryDescription.matching(growStyle: growStyle) {
            categoryButtons.forEach { button in
                let buttonTitle = button.configuration?.title ?? button.title(for: .normal)
                button.isSelected = (buttonTitle == category.title)
            }
            categoryGuideView.configure(plantName: name, category: category)
        } else {
            categoryButtons.forEach { $0.isSelected = false }
            categoryGuideView.configure(plantName: nil, category: nil)
        }

        lightGuideView.configure(plantName: name, lightDemand: lightDemand)
        wateringGuideBannerView.configure(plantName: name, springWaterCycle: springWaterCycle)
    }

    // 입력화면 초기화
    func resetForm() {
        cameraButton.backgroundImageView.image = nil
        cameraButton.backgroundColor = .grayScale50
        plantTypeSearchBar.textField.text = nil
        plantNameTextField.text = nil
        wateringCycleTextField.text = nil
        lastWateredDateTextField.text = nil
        lastWateredDatePicker.date = Date()
        firstMetDateTextField.text = nil
        firstMetDatePicker.date = Date()

        categoryButtons.forEach {
            $0.isSelected = false
            $0.isEnabled = true
        }

        locationButtons.forEach { $0.isSelected = false }

        categoryGuideView.configure(plantName: nil, category: nil)
        lightGuideView.configure(plantName: nil, lightDemand: nil)
        wateringGuideBannerView.configure(plantName: nil, springWaterCycle: nil)
    }

    func setLastWateredDate(_ date: Date, text: String) {
        lastWateredDatePicker.date = date
        lastWateredDateTextField.text = text
    }

    func setFirstMetDate(_ date: Date, text: String) {
        firstMetDatePicker.date = date
        firstMetDateTextField.text = text
    }
}

// MARK: UI 구현
private extension PlantRegisterView {
    enum Layout {
        static let horizontalInset: CGFloat = 16
        static let topInset: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let fieldSpacing: CGFloat = 12
        static let guideSpacing: CGFloat = 8
        static let bottomInset: CGFloat = 24
    }

    func setupSelectionState() {
        categoryButtons.first?.isSelected = true
        locationButtons[3].isSelected = true
    }

    func setupUI() {
        addSubview(headerView)
        addSubview(scrollView)
        addSubview(registerButton)

        scrollView.addSubview(contentView)
        contentView.addSubview(cameraButton)
        contentView.addSubview(formStackView)
        contentView.addSubview(plantTypeSearchButton)

        headerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(64)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(48)
        }

        registerButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(Layout.horizontalInset)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(Layout.bottomInset)
            $0.height.equalTo(48)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(registerButton.snp.top).offset(-16)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        cameraButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Layout.topInset)
            $0.centerX.equalToSuperview()
        }

        formStackView.snp.makeConstraints {
            $0.top.equalTo(cameraButton.snp.bottom).offset(Layout.sectionSpacing)
            $0.horizontalEdges.equalToSuperview().inset(Layout.horizontalInset)
            $0.bottom.equalToSuperview().inset(Layout.bottomInset)
        }

        plantTypeSearchBar.snp.makeConstraints {
            $0.height.equalTo(48)
        }

        plantNameTextField.snp.makeConstraints {
            $0.height.equalTo(48)
        }

        wateringCycleTextField.snp.makeConstraints {
            $0.width.equalTo(84)
            $0.height.equalTo(48)
        }

        lastWateredDateTextField.snp.makeConstraints {
            $0.width.equalTo(126)
            $0.height.equalTo(48)
        }

        firstMetDateTextField.snp.makeConstraints {
            $0.width.equalTo(126)
            $0.height.equalTo(48)
        }

        categoryGuideView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(32)
        }

        [
            makeSectionStack(arrangedSubviews: [plantTypeTitleLabel, plantTypeSearchBar]),
            makeSectionStack(
                arrangedSubviews: [categoryTitleLabel, categoryStackView, categoryGuideView],
                customSpacings: [categoryStackView: Layout.guideSpacing]
            ),
            makeSectionStack(arrangedSubviews: [plantNameTitleLabel, plantNameTextField]),
            makeSectionStack(
                arrangedSubviews: [locationTitleLabel, locationStackView, lightGuideView],
                customSpacings: [locationStackView: Layout.guideSpacing]
            ),
            makeSectionStack(arrangedSubviews: [firstMetDateTitleLabel, firstMetDateFieldContainer]),
            makeSectionStack(
                arrangedSubviews: [wateringCycleTitleLabel, wateringCycleInputStackView, wateringGuideBannerView],
                customSpacings: [wateringCycleInputStackView: Layout.guideSpacing]
            ),
            makeSectionStack(arrangedSubviews: [lastWateredTitleLabel, lastWateredDateFieldContainer])
        ].forEach { formStackView.addArrangedSubview($0) }

        plantTypeSearchButton.snp.makeConstraints {
            $0.top.leading.bottom.equalTo(plantTypeSearchBar)
            $0.trailing.equalTo(plantTypeSearchBar.cameraButton.snp.leading).offset(-8)
        }
    }

    func setupDateInputViews() {
        lastWateredDateTextField.inputView = lastWateredDateInputView
        lastWateredDateTextField.tintColor = .clear
        firstMetDateTextField.inputView = firstMetDateInputView
        firstMetDateTextField.tintColor = .clear
    }

    @objc func didTapLastWateredDateDone() {
        let selectedDate = lastWateredDatePicker.date
        onLastWateredDateDone?(selectedDate)
        lastWateredDateTextField.resignFirstResponder()
    }

    @objc func didTapFirstMetDateDone() {
        let selectedDate = firstMetDatePicker.date
        onFirstMetDateDone?(selectedDate)
        firstMetDateTextField.resignFirstResponder()
    }

    // 버튼 그리드 배치하기
    func makeSelectionGrid(buttons: [UIButton]) -> UIStackView {
        let rows = stride(from: 0, to: buttons.count, by: 3).map { startIndex -> UIStackView in
            let rowButtons = Array(buttons[startIndex ..< min(startIndex + 3, buttons.count)])
            rowButtons.forEach { button in
                button.snp.makeConstraints {
                    $0.height.equalTo(36)
                }
            }

            return UIStackView(arrangedSubviews: rowButtons).then {
                $0.axis = .horizontal
                $0.spacing = 8
                $0.distribution = .fillEqually
            }
        }

        return UIStackView(arrangedSubviews: rows).then {
            $0.axis = .vertical
            $0.spacing = 8
        }
    }

    func makeSectionStack(arrangedSubviews: [UIView], customSpacings: [UIView: CGFloat] = [:]) -> UIStackView {
        UIStackView(arrangedSubviews: arrangedSubviews).then {
            $0.axis = .vertical
            $0.spacing = Layout.fieldSpacing

            for (view, spacing) in customSpacings {
                $0.setCustomSpacing(spacing, after: view)
            }
        }
    }

    func makeLeadingAlignedContainer(for contentView: UIView) -> UIView {
        UIView().then { containerView in
            containerView.addSubview(contentView)
            contentView.snp.makeConstraints {
                $0.top.leading.bottom.equalToSuperview()
            }
        }
    }

    static func makeRequiredSectionLabel(text: String) -> UILabel {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: UIFont.systemFont(ofSize: 14, weight: .semibold)),
                .foregroundColor: UIColor.black
            ]
        )
        attributedText.append(
            NSAttributedString(
                string: "*",
                attributes: [
                    .font: UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: UIFont.systemFont(ofSize: 14, weight: .semibold)),
                    .foregroundColor: UIColor.systemRed
                ]
            )
        )
        label.attributedText = attributedText
        return label
    }

    static func makeTextField(placeholder: String) -> UITextField {
        UITextField().then {
            $0.placeholder = placeholder
            $0.layer.cornerRadius = 12
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.grayScale100.cgColor
            $0.clearButtonMode = .whileEditing
            $0.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            $0.textColor = .label
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
            $0.leftView = paddingView
            $0.leftViewMode = .always
        }
    }
}
