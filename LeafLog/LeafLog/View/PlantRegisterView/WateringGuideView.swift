//
//  WateringGuideView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/17/26.
//

import SnapKit
import Then
import UIKit

final class WateringGuideView: UIView {
    private let iconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "info.circle")
        $0.tintColor = .grayScale500
        $0.contentMode = .scaleAspectFit
    }

    private let messageLabel = UILabel().then {
        $0.apply(.body12, color: .grayScale700, lines: 0)
    }

    private let contentStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 6
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
        setupLayout()
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func suggestedInputValue(from springWaterCycle: String?) -> String? {
        WaterCycleDescription.inputValue(from: springWaterCycle)
    }

    func configure(cycleText: String) {
        let fullText = "해당 식물은 평균 \(cycleText) 주기로 급수가 필요해요."
        let attributedText = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: messageLabel.font as Any,
                .foregroundColor: UIColor.grayScale700
            ]
        )

        let highlightedRange = (fullText as NSString).range(of: cycleText)
        if highlightedRange.location != NSNotFound {
            attributedText.addAttributes([
                .foregroundColor: UIColor.primary700
            ], range: highlightedRange)
        }

        messageLabel.attributedText = attributedText
        isHidden = false
    }

    func configure(plantName: String?, springWaterCycle: String?) {
        guard let plantName, !plantName.isEmpty else {
            messageLabel.text = nil
            isHidden = true
            return
        }

        guard let cycleText = WaterCycleDescription.cycleText(from: springWaterCycle) else {
            messageLabel.text = nil
            isHidden = true
            return
        }

        let suffix = WaterCycleDescription.suffixText(from: springWaterCycle)
        let fullText = "\(plantName)은(는) 평균 \(cycleText) 주기로 급수가 필요해요. \(suffix)"

        let attributedText = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: messageLabel.font as Any,
                .foregroundColor: UIColor.grayScale700
            ]
        )

        [plantName, cycleText].forEach { highlightedText in
            let highlightedRange = (fullText as NSString).range(of: highlightedText)
            if highlightedRange.location != NSNotFound {
                attributedText.addAttributes([
                    .foregroundColor: UIColor.primary700
                ], range: highlightedRange)
            }
        }

        messageLabel.attributedText = attributedText
        isHidden = false
    }
}

private extension WateringGuideView {
    func setupStyle() {
        backgroundColor = .primary100
        layer.cornerRadius = 8
        clipsToBounds = true
    }

    func setupLayout() {
        addSubview(contentStackView)

        contentStackView.addArrangedSubview(iconImageView)
        contentStackView.addArrangedSubview(messageLabel)

        iconImageView.snp.makeConstraints {
            $0.size.equalTo(16)
        }

        contentStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
        }
    }
}

private struct WaterCycleDescription {
    let keyword: String
    let inputValue: String
    let cycleText: String
    let suffixText: String

    static let all: [WaterCycleDescription] = [
        .init(
            keyword: "토양 표면이 말랐을때 충분히 관수",
            inputValue: "4",
            cycleText: "4 ~ 6일",
            suffixText: "(표면이 말랐을때 충분히 급수)"
        ),
        .init(
            keyword: "화분 흙 대부분 말랐을때 충분히 관수",
            inputValue: "7",
            cycleText: "7 ~ 10일",
            suffixText: "(흙 대부분 말랐을때 충분히 급수)"
        ),
        .init(
            keyword: "항상 흙을 촉촉하게 유지함",
            inputValue: "0",
            cycleText: "0 ~ 2일",
            suffixText: "(수시 보충)"
        ),
        .init(
            keyword: "흙을 촉촉하게 유지함",
            inputValue: "3",
            cycleText: "3 ~ 5일",
            suffixText: "(물에 잠기지 않도록 주의)"
        )
    ]

    static func matchedDescription(from springWaterCycle: String?) -> WaterCycleDescription? {
        guard let springWaterCycle = springWaterCycle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !springWaterCycle.isEmpty else {
            return nil
        }

        let normalizedWaterCycle = normalized(springWaterCycle)
        return all.first { normalizedWaterCycle.contains(normalized($0.keyword)) }
    }

    static func cycleText(from springWaterCycle: String?) -> String? {
        matchedDescription(from: springWaterCycle)?.cycleText
    }

    static func inputValue(from springWaterCycle: String?) -> String? {
        matchedDescription(from: springWaterCycle)?.inputValue
    }

    static func suffixText(from springWaterCycle: String?) -> String {
        matchedDescription(from: springWaterCycle)?.suffixText ?? ""
    }

    private static func normalized(_ text: String) -> String {
        text.components(separatedBy: .whitespacesAndNewlines).joined()
    }
}
