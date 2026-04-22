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

    struct RowData: Equatable {
        let title: String
        let value: String
    }

    private let cardView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 0
        $0.clipsToBounds = true
    }

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.distribution = .fillEqually
    }

    private let currentStateRow = PlantDetailInfoRowView(title: "현재 상태", value: "", showSeparator: true)
    private let adoptedDateRow = PlantDetailInfoRowView(title: "데려온 날", value: "", showSeparator: true)
    private let locationRow = PlantDetailInfoRowView(title: "위치", value: "", showSeparator: true)
    private let lastWateredDateRow = PlantDetailInfoRowView(title: "마지막 급수일", value: "", showSeparator: false)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlantDetailCell {
    private func setLayout() {
        contentView.backgroundColor = .white
        contentView.addSubview(cardView)
        cardView.addSubview(stackView)

        [currentStateRow, adoptedDateRow, locationRow, lastWateredDateRow].forEach {
            stackView.addArrangedSubview($0)
        }

        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func configure(rows: [RowData]) {
        let defaultRows = [
            RowData(title: "현재 상태", value: ""),
            RowData(title: "데려온 날", value: ""),
            RowData(title: "위치", value: ""),
            RowData(title: "마지막 급수일", value: "")
        ]

        let appliedRows = rows.isEmpty ? defaultRows : rows
        let rowViews = [currentStateRow, adoptedDateRow, locationRow, lastWateredDateRow]

        for (index, rowView) in rowViews.enumerated() {
            if index < appliedRows.count {
                rowView.isHidden = false
                rowView.configure(title: appliedRows[index].title, value: appliedRows[index].value)
            } else {
                rowView.isHidden = true
            }
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
            $0.height.equalTo(58)
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
