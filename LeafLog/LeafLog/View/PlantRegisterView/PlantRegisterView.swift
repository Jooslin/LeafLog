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

    let headerView = TitleHeaderView(text: "식물 등록", hasBackButton: true)

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .onDrag
    }

    private let contentView = UIView()

    let cameraButton = CameraProfileButton()

    private let plantTypeTitleLabel = PlantRegisterView.makeRequiredSectionLabel(text: "식물 종류")
    let plantTypeSearchBar = SearchBarView().then {
        $0.textField.placeholder = "식물을 검색해주세요."
        $0.textField.isUserInteractionEnabled = false
        $0.cameraButton.isUserInteractionEnabled = false
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
    private let categoryGuideLabel = InsetLabel(text: "직립형은 위로 쭉 자라는 형태를 나타내요.", config: .label12, color: .primary700).then {
        $0.backgroundColor = .primary100
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.textInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    }

    private let plantNameTitleLabel = PlantRegisterView.makeRequiredSectionLabel(text: "식물 별명")
    let plantNameTextField = PlantRegisterView.makeTextField(placeholder: "place holder")

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
    let wateringCycleTextField = PlantRegisterView.makeTextField(placeholder: "7").then {
        $0.keyboardType = .numberPad
    }
    private let wateringCycleUnitLabel = UILabel(text: "일마다", config: .title16, color: .grayScale500)
    let wateringGuideBannerView = GuideBannerView()

    private let lastWateredTitleLabel = PlantRegisterView.makeRequiredSectionLabel(text: "마지막 급수일")
    let lastWateredDateTextField = PlantRegisterView.makeTextField(placeholder: "년 / 월 / 일").then {
        $0.keyboardType = .numbersAndPunctuation
    }

    let registerButton = BottomSaveButton(title: "등록하기")

    private lazy var categoryStackView = makeSelectionGrid(buttons: categoryButtons)
    private lazy var locationStackView = makeSelectionGrid(buttons: locationButtons)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupSelectionState()
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension PlantRegisterView {
    func setupSelectionState() {
        categoryButtons.first?.isSelected = true
        locationButtons[3].isSelected = true
    }

    func setupUI() {
        addSubview(headerView)
        addSubview(scrollView)
        addSubview(registerButton)

        scrollView.addSubview(contentView)

        headerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(64)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(48)
        }

        registerButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
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

        [
            cameraButton,
            plantTypeTitleLabel,
            plantTypeSearchBar,
            plantTypeSearchButton,
            categoryTitleLabel,
            categoryStackView,
            categoryGuideLabel,
            plantNameTitleLabel,
            plantNameTextField,
            locationTitleLabel,
            locationStackView,
            lightGuideView,
            wateringCycleTitleLabel,
            wateringCycleTextField,
            wateringCycleUnitLabel,
            wateringGuideBannerView,
            lastWateredTitleLabel,
            lastWateredDateTextField
        ].forEach { contentView.addSubview($0) }

        cameraButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
        }

        plantTypeTitleLabel.snp.makeConstraints {
            $0.top.equalTo(cameraButton.snp.bottom).offset(28)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        plantTypeSearchBar.snp.makeConstraints {
            $0.top.equalTo(plantTypeTitleLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalTo(plantTypeTitleLabel)
            $0.height.equalTo(48)
        }

        plantTypeSearchButton.snp.makeConstraints {
            $0.edges.equalTo(plantTypeSearchBar)
        }

        categoryTitleLabel.snp.makeConstraints {
            $0.top.equalTo(plantTypeSearchBar.snp.bottom).offset(20)
            $0.horizontalEdges.equalTo(plantTypeTitleLabel)
        }

        categoryStackView.snp.makeConstraints {
            $0.top.equalTo(categoryTitleLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalTo(plantTypeTitleLabel)
        }

        categoryGuideLabel.snp.makeConstraints {
            $0.top.equalTo(categoryStackView.snp.bottom).offset(8)
            $0.leading.equalTo(plantTypeTitleLabel)
        }

        plantNameTitleLabel.snp.makeConstraints {
            $0.top.equalTo(categoryGuideLabel.snp.bottom).offset(24)
            $0.horizontalEdges.equalTo(plantTypeTitleLabel)
        }

        plantNameTextField.snp.makeConstraints {
            $0.top.equalTo(plantNameTitleLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalTo(plantTypeTitleLabel)
            $0.height.equalTo(48)
        }

        locationTitleLabel.snp.makeConstraints {
            $0.top.equalTo(plantNameTextField.snp.bottom).offset(24)
            $0.horizontalEdges.equalTo(plantTypeTitleLabel)
        }

        locationStackView.snp.makeConstraints {
            $0.top.equalTo(locationTitleLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalTo(plantTypeTitleLabel)
        }

        lightGuideView.snp.makeConstraints {
            $0.top.equalTo(locationStackView.snp.bottom).offset(8)
            $0.horizontalEdges.equalTo(plantTypeTitleLabel)
        }

        wateringCycleTitleLabel.snp.makeConstraints {
            $0.top.equalTo(lightGuideView.snp.bottom).offset(24)
            $0.horizontalEdges.equalTo(plantTypeTitleLabel)
        }

        wateringCycleTextField.snp.makeConstraints {
            $0.top.equalTo(wateringCycleTitleLabel.snp.bottom).offset(12)
            $0.leading.equalTo(plantTypeTitleLabel)
            $0.width.equalTo(84)
            $0.height.equalTo(48)
        }

        wateringCycleUnitLabel.snp.makeConstraints {
            $0.leading.equalTo(wateringCycleTextField.snp.trailing).offset(8)
            $0.centerY.equalTo(wateringCycleTextField)
        }

        wateringGuideBannerView.snp.makeConstraints {
            $0.top.equalTo(wateringCycleTextField.snp.bottom).offset(8)
            $0.horizontalEdges.equalTo(plantTypeTitleLabel)
        }

        lastWateredTitleLabel.snp.makeConstraints {
            $0.top.equalTo(wateringGuideBannerView.snp.bottom).offset(24)
            $0.horizontalEdges.equalTo(plantTypeTitleLabel)
        }

        lastWateredDateTextField.snp.makeConstraints {
            $0.top.equalTo(lastWateredTitleLabel.snp.bottom).offset(12)
            $0.leading.equalTo(plantTypeTitleLabel)
            $0.width.equalTo(96)
            $0.height.equalTo(48)
            $0.bottom.equalToSuperview().inset(24)
        }
        categoryGuideLabel.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(28)
        }
    }

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

private final class InsetLabel: UILabel {
    var textInsets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}

private final class LightGuideView: UIView {
    private let iconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "info.circle")
        $0.tintColor = .grayScale500
        $0.contentMode = .scaleAspectFit
    }

    private let messageLabel = UILabel(config: .body12, color: .grayScale700, lines: 0).then {
        $0.text = "해당 식물은 반음영이 있는 여유로운 채광(300~800 Lux)을 선호해요."
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .primary100
        layer.cornerRadius = 8
        clipsToBounds = true
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(iconImageView)
        addSubview(messageLabel)

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(10)
            $0.top.equalToSuperview().inset(8)
            $0.size.equalTo(16)
        }

        messageLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(8)
            $0.leading.equalTo(iconImageView.snp.trailing).offset(6)
            $0.trailing.equalToSuperview().inset(10)
        }
    }
}
