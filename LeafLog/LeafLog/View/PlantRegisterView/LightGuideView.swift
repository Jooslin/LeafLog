//
//  LightGuideView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/20/26.
//

import SnapKit
import Then
import UIKit

final class LightGuideView: UIView {
    private let iconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "info.circle")
        $0.tintColor = .grayScale500
        $0.contentMode = .scaleAspectFit
    }

    private let messageLabel = UILabel(config: .body12 , color: .grayScale700, lines: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .primary100
        layer.cornerRadius = 8
        clipsToBounds = true
        setupUI()
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(plantName: String?, lightDemand: String?) {
        let descriptions = LightDemandDescription.matchingAll(lightDemand: lightDemand)

        guard !descriptions.isEmpty else {
            messageLabel.text = nil
            messageLabel.attributedText = nil
            isHidden = true
            return
        }

        let preferenceText = descriptions
            .map(\.preferenceText)
            .joined(separator: ", ")

        let fullDescription = descriptions
            .map(\.fullDescription)
            .joined(separator: ", ")

        guard let plantName, !plantName.isEmpty else {
            messageLabel.text = fullDescription
            messageLabel.attributedText = nil
            isHidden = false
            return
        }

        let fullText = "\(plantName)은(는) \(preferenceText)와 같은 장소에 두는 걸 추천합니다."
        let attributedText = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: messageLabel.font as Any,
                .foregroundColor: UIColor.grayScale700
            ]
        )

        [plantName]
            .appending(contentsOf: descriptions.map(\.preferenceText))
            .forEach { highlightedText in
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

private extension Array where Element == String {
    func appending(contentsOf elements: [String]) -> [String] {
        self + elements
    }
}

private struct LightDemandDescription {
    let keywords: [String]
    let preferenceText: String
    let fullDescription: String

    static let all: [LightDemandDescription] = [
        .init(
            keywords: ["낮은 광도", "300~800", "300∼800"],
            preferenceText: "형광등이 있는 어두운 실내",
            fullDescription: "낮은 광도 (300~800 Lux): 형광등이 있는 어두운 실내"
        ),
        .init(
            keywords: ["중간 광도", "800~1,500"],
            preferenceText: "밝은 실내, 창문 근처 (직사광선X)",
            fullDescription: "중간 광도 (800~1,500 Lux): 밝은 실내, 창문 근처 (직사광선X)"
        ),
        .init(
            keywords: ["높은 광도", "1,500~10,000"],
            preferenceText: "창가의 직광, 베란다의 직광",
            fullDescription: "높은 광도 (1,500~10,000 Lux): 창가의 직광, 베란다"
        )
    ]

    static func matchingAll(lightDemand: String?) -> [LightDemandDescription] {
        guard let lightDemand = lightDemand?.trimmingCharacters(in: .whitespacesAndNewlines),
              !lightDemand.isEmpty else {
            return []
        }

        return all.filter { description in
            description.keywords.contains { lightDemand.contains($0) }
        }
    }
}
