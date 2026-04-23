//
//  NotificationAlarmCell.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/23/26.
//

import UIKit
import SnapKit
import Then

final class NotificationAlarmCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel(text: "", config: .label14)
    private let descriptionLabel = UILabel(text: "", config: .body14, color: .grayScale600, lines: 0)
    private let timeLabel = UILabel(text: "", config: .label12, color: .grayScale400, lines: 1).then {
        $0.textAlignment = .right
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    private func setLayout() {
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel]).then {
            $0.axis = .vertical
            $0.spacing = 2
        }
        
        contentView.addSubview(imageView)
        contentView.addSubview(labelStack)
        contentView.addSubview(timeLabel)
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(32)
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalTo(labelStack)
        }
        
        labelStack.snp.makeConstraints {
            $0.leading.equalTo(imageView.snp.trailing).offset(12)
            $0.trailing.equalTo(timeLabel.snp.leading).offset(-12)
            $0.verticalEdges.equalToSuperview().inset(16)
        }
        
        timeLabel.snp.makeConstraints {
            $0.centerY.equalTo(labelStack)
            $0.trailing.equalToSuperview().inset(16)
        }
    }
}

extension NotificationAlarmCell {
    func configure(_ data: NotificationCenterView.Alarm) {
        imageView.image = data.category == .management ? UIImage(named: Badge.water.bigImage) : nil
        
        titleLabel.text = data.title
        descriptionLabel.text = data.body
        timeLabel.text = data.sentTimeLabel
    }
}
