//
//  WideTotalCardView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/29/26.
//

import UIKit
import SnapKit
import Then

final class WideTotalCardView: BaseCardView {
    private let sproutImageView = UIImageView(image: .badgeSproutBig)
    private let waterImageView = UIImageView(image: .badgeWaterBig)
    let plantLabel = UILabel(text: "", config: .label14)
    let waterLabel = UILabel(text: "", config: .label14)
    let separateBar = SeparateBar()
    
    init() {
        super.init(cornerRadius: 12)
        
        backgroundColor = .white
        
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WideTotalCardView {
    private func setLayout() {
        let plantStackView = UIStackView(arrangedSubviews: [sproutImageView, plantLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            sproutImageView.setContentHuggingPriority(.required, for: .horizontal)
            sproutImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        let waterStackView = UIStackView(arrangedSubviews: [waterImageView, waterLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            waterImageView.setContentHuggingPriority(.required, for: .horizontal)
            waterImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        addSubview(plantStackView)
        addSubview(waterStackView)
        addSubview(separateBar)
        
        sproutImageView.snp.makeConstraints {
            $0.width.height.equalTo(32)
        }
        
        waterImageView.snp.makeConstraints {
            $0.width.height.equalTo(32)
        }
        
        plantStackView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(8)
            $0.leading.equalToSuperview().inset(17)
            $0.trailing.equalTo(separateBar.snp.leading).inset(32)
        }
        
        separateBar.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(16)
            $0.width.equalTo(1)
            $0.centerX.equalToSuperview()
        }
        
        waterStackView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(8)
            $0.leading.equalTo(separateBar.snp.trailing).offset(32)
            $0.trailing.equalToSuperview().inset(17)
        }
    }
}
