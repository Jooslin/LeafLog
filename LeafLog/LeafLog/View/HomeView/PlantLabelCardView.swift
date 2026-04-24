//
//  PlantLabelCardView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then

final class PlantLabelCardView: BaseCardView {
    let nameLabel = UILabel(text: "", config: .label14, lines: 2).then {
        $0.textAlignment = .center
    }
    
    private let recentLabel = UILabel(text: "최근 급수", config: .body12, color: .grayScale600, lines: 1)
    let recentDayLabel = UILabel(text: "N일 전", config: .body12, color: .subBlue, lines: 1)
    private let nextLabel = UILabel(text: "다음 급수까지", config: .label12, color: .grayScale800, lines: 1)
    let nextDayLabel = UILabel(text: "N일", config: .label12, color: .primary700, lines: 1)
    let waterButton = UIButton(config: .water, title: "물 줬어요")
    
    init() {
        super.init(frame: .zero, cornerRadius: 12)
        backgroundColor = .white
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlantLabelCardView {
    private func setLayout() {
        let recentStack = generateHorizontalStackView(of: [recentLabel, recentDayLabel])
        let nextStack = generateHorizontalStackView(of: [nextLabel, nextDayLabel])
        
        addSubview(nameLabel)
        addSubview(recentStack)
        addSubview(nextStack)
        addSubview(waterButton)
        
        nameLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview().inset(8)
        }
        
        recentStack.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().inset(8)
            $0.trailing.lessThanOrEqualToSuperview().inset(8)
        }
        
        nextStack.snp.makeConstraints {
            $0.top.equalTo(recentStack.snp.bottom).offset(2)
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().inset(8)
            $0.trailing.lessThanOrEqualToSuperview().inset(8)
        }
        
        waterButton.snp.makeConstraints {
            $0.top.equalTo(nextStack.snp.bottom).offset(4)
            $0.horizontalEdges.bottom.equalToSuperview().inset(8)
            $0.height.equalTo(28)
        }
    }
    
    private func generateHorizontalStackView(of views: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views).then {
            $0.axis = .horizontal
            $0.spacing = 2
        }
        
        views[1].setContentHuggingPriority(.required, for: .horizontal)
        views[1].setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return stackView
    }
}
