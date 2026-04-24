//
//  PlantDetailCell.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/22/26.
//
import SnapKit
import Then
import UIKit

final class PlantDetailCell: UICollectionViewCell {
    static let reuseIdentifier = "PlantDetailCell"

    var onGuideEnabledChanged: ((Bool) -> Void)?

    struct RowData: Equatable {
        let title: String
        let value: String
    }

    struct GuideData: Equatable, Hashable {
        let watering: String
        let temperature: String
        let humidity: String
        let pest: String
    }

    private let cardView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 0
        $0.clipsToBounds = true
    }

    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 24
        $0.alignment = .fill
        $0.distribution = .fill
    }

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.distribution = .fill
    }

    private let guideHeaderStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 12
        $0.distribution = .fill
    }

    private let guideTitleLabel = UILabel(text: "가이드", config: .title14, color: .black)

    private let guideToggleButton = UIButton(type: .system).then {
        $0.tintColor = .grayScale500
        $0.setImage(UIImage(named: "arrowDown"), for: .normal)
    }

    private let guideCardView = UIView().then {
        $0.backgroundColor = .grayScale50
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
    }

    private let guideStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 28
    }

    private let adoptedDateRow = PlantDetailInfoRowView(title: "데려온 날", value: "", showSeparator: true)
    private let locationRow = PlantDetailInfoRowView(title: "위치", value: "", showSeparator: true)
    private let lastWateredDateRow = PlantDetailInfoRowView(title: "마지막 급수일", value: "", showSeparator: false)

    private let wateringGuideRow = PlantDetailGuideRowView(
        icon: .asset("badgeWaterBig"),
        iconTintColor: nil,
        title: "물주기",
        message: "흙이 마르면 물을 충분히 주세요."
    )
    private let temperatureGuideRow = PlantDetailGuideRowView(
        icon: .asset("badgeTemperatureBig"),
        iconTintColor: nil,
        title: "적정 온도",
        message: "18-27°C"
    )
    private let humidityGuideRow = PlantDetailGuideRowView(
        icon: .asset("badgeCloudBig"),
        iconTintColor: nil,
        title: "습도",
        message: "60-80%"
    )
    private let pestGuideRow = PlantDetailGuideRowView(
        icon: .asset("badgeBugBig"),
        iconTintColor: nil,
        title: "병해충 정보",
        message: "깍지벌레 주의"
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
        setActions()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onGuideEnabledChanged = nil
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let fittingAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        setNeedsLayout()
        layoutIfNeeded()

        let targetSize = CGSize(
            width: layoutAttributes.size.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        let fittingSize = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        fittingAttributes.frame.size.height = ceil(fittingSize.height)
        return fittingAttributes
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlantDetailCell {
    private func setLayout() {
        contentView.backgroundColor = .white
        contentView.addSubview(contentStackView)
        cardView.addSubview(stackView)
        guideCardView.addSubview(guideStackView)

        [adoptedDateRow, locationRow, lastWateredDateRow].forEach {
            stackView.addArrangedSubview($0)
        }

        [wateringGuideRow, temperatureGuideRow, humidityGuideRow, pestGuideRow].forEach {
            guideStackView.addArrangedSubview($0)
        }

        contentStackView.addArrangedSubview(cardView)
        guideHeaderStackView.addArrangedSubview(guideTitleLabel)
        guideHeaderStackView.addArrangedSubview(guideToggleButton)

        contentStackView.addArrangedSubview(guideHeaderStackView)
        contentStackView.addArrangedSubview(guideCardView)

        guideTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        guideToggleButton.setContentHuggingPriority(.required, for: .horizontal)
        cardView.setContentHuggingPriority(.required, for: .vertical)
        guideHeaderStackView.setContentHuggingPriority(.required, for: .vertical)
        guideCardView.setContentHuggingPriority(.required, for: .vertical)
        cardView.setContentCompressionResistancePriority(.required, for: .vertical)
        guideHeaderStackView.setContentCompressionResistancePriority(.required, for: .vertical)
        guideCardView.setContentCompressionResistancePriority(.required, for: .vertical)

        contentStackView.setCustomSpacing(12, after: guideHeaderStackView)

        contentStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        guideHeaderStackView.snp.makeConstraints {
            $0.height.equalTo(32).priority(999)
        }

        guideStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(24)
        }
    }

    func configure(rows: [RowData], guide: GuideData, isGuideEnabled: Bool) {
        let defaultRows = [
            RowData(title: "데려온 날", value: ""),
            RowData(title: "위치", value: ""),
            RowData(title: "마지막 급수일", value: "")
        ]

        let appliedRows = rows.isEmpty ? defaultRows : rows
        let rowViews = [adoptedDateRow, locationRow, lastWateredDateRow]

        for (index, rowView) in rowViews.enumerated() {
            if index < appliedRows.count {
                rowView.isHidden = false
                rowView.configure(title: appliedRows[index].title, value: appliedRows[index].value)
            } else {
                rowView.isHidden = true
            }
        }

        wateringGuideRow.configure(message: guide.watering)
        temperatureGuideRow.configure(message: guide.temperature)
        humidityGuideRow.configure(message: guide.humidity)
        pestGuideRow.configure(message: guide.pest)

        applyGuideVisibility(isEnabled: isGuideEnabled)
    }

    private func setActions() {
        guideToggleButton.addAction(
            UIAction { [weak self] _ in
                self?.handleGuideToggleChanged()
            },
            for: .touchUpInside
        )
    }

    @objc private func handleGuideToggleChanged() {
        onGuideEnabledChanged?(guideCardView.isHidden)
    }

    private func applyGuideVisibility(isEnabled: Bool) {
        UIView.performWithoutAnimation {
            guideCardView.isHidden = !isEnabled
            let imageName = isEnabled ? "arrowUp" : "arrowDown"
            guideToggleButton.setImage(UIImage(named: imageName), for: .normal)
            contentView.layoutIfNeeded()
        }
    }
}

private enum PlantDetailGuideIcon {
    case system(String)
    case asset(String)
}

private final class PlantDetailGuideRowView: UIView {
    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let titleLabel = UILabel(config: .title14, color: .black)
    private let messageLabel = UILabel(config: .body14, color: .grayScale600, lines: 0)

    private let textStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 6
        $0.alignment = .fill
    }

    init(
        icon: PlantDetailGuideIcon,
        iconTintColor: UIColor?,
        title: String,
        message: String
    ) {
        super.init(frame: .zero)
        configureIcon(icon, tintColor: iconTintColor)
        titleLabel.text = title
        messageLabel.text = message
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureIcon(_ icon: PlantDetailGuideIcon, tintColor: UIColor?) {
        switch icon {
        case .system(let name):
            iconImageView.image = UIImage(systemName: name)
        case .asset(let name):
            iconImageView.image = UIImage(named: name)
        }

        iconImageView.tintColor = tintColor
    }

    func configure(message: String) {
        messageLabel.text = message
    }
}

private extension PlantDetailGuideRowView {
    func setLayout() {
        addSubview(iconImageView)
        addSubview(textStackView)

        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(messageLabel)

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview()
            $0.size.equalTo(32)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        textStackView.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview()
            $0.verticalEdges.equalToSuperview()
        }
    }
}

private final class PlantDetailInfoRowView: UIView {
    private static let lineWidth = 1 / UIScreen.main.scale
    private let titleLabel = UILabel(config: .body14, color: .grayScale700)
    private let valueLabel = UILabel(config: .body14, color: .black).then {
        $0.textAlignment = .right
    }

    private let separator = SeparateBar()

    init(title: String, value: String, showSeparator: Bool) {
        super.init(frame: .zero)
        titleLabel.text = title
        valueLabel.text = value
        separator.isHidden = !showSeparator
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

private extension PlantDetailInfoRowView {
    func setLayout() {
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(separator)

        snp.makeConstraints {
            $0.height.equalTo(58).priority(999)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        valueLabel.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        separator.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(Self.lineWidth)
        }
    }
}
