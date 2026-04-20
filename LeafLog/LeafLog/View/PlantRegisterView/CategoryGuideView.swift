//
//  CategoryGuideView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/20/26.
//

import SnapKit
import Then
import UIKit

final class CategoryGuideView: UIView {
    private let iconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "info.circle")
        $0.tintColor = .grayScale500
        $0.contentMode = .scaleAspectFit
    }

    private let messageLabel = UILabel(config: .body12, color: .grayScale700, lines: 0)

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

    func configure(plantName: String?, category: PlantCategoryDescription?) {
        guard let plantName, let category else {
            messageLabel.text = nil
            messageLabel.attributedText = nil
            isHidden = true
            return
        }

        let fullText = "\(plantName)은(는) \(category.description) \(category.title) 식물 입니다."
        let attributedText = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: messageLabel.font as Any,
                .foregroundColor: UIColor.grayScale700
            ]
        )

        [plantName, category.description, category.title].forEach { highlightedText in
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

struct PlantCategoryDescription {
    let title: String
    let description: String

    static let all: [PlantCategoryDescription] = [
        .init(title: "직립형", description: "위로 쭉 자라는"),
        .init(title: "관목형", description: "풍성하게 자라는"),
        .init(title: "덩굴성", description: "길게 늘어지는"),
        .init(title: "풀모양", description: "가늘게 자라는"),
        .init(title: "로제트형", description: "납작하고 동그랗게 퍼지며 자라는"),
        .init(title: "다육형", description: "통통하게 자라는")
    ]

    static func matching(growStyle: String?) -> PlantCategoryDescription? {
        guard let growStyle = growStyle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !growStyle.isEmpty else {
            return nil
        }

        return all.first { category in
            growStyle.contains(category.title) || category.title.contains(growStyle)
        }
    }
}
