//
//  GuideBannerView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/17/26.
//

import SnapKit
import Then
import UIKit

final class GuideBannerView: UIView {
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
        configure(cycleText: "7일")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GuideBannerView {
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
    }
}

private extension GuideBannerView {
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
