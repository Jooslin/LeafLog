//
//  DetailInfoRowView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/17/26.
//
import UIKit
import Then
import SnapKit

final class DetailInfoRowView: UIView {

    private let titleLabel = UILabel(config: .label14, color: .black)

    private let valueLabel = UILabel(config: .label14, color: .grayScale600).then {
        $0.numberOfLines = 0
        $0.textAlignment = .right
    }

    init(title: String, value: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.text = value
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(titleLabel)
        addSubview(valueLabel)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(5)
        }

        valueLabel.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(5)
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(5)
        }
    }
}
