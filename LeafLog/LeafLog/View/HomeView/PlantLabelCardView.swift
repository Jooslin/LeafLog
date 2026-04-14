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
    let nameLabel = UILabel(text: "", config: .label14)
    
    private let recentLabel = UILabel(text: "최근 급수", config: .body12, color: .grayScale600)
    let recentDayLabel = UILabel(text: "N일 전", config: .body12, color: .subBlue)
    private let nextLabel = UILabel(text: "다음 급수까지", config: .label12, color: .grayScale800)
    let nextDayLabel = UILabel(text: "N일", config: .label12, color: .primary700)
    
    let waterButton = CornerRadius8Button(title: "물 줬어요", backgroundColor: .lightBlue).then {
        $0.snp.makeConstraints {
            $0.height.equalTo(28)
        }
    }
    
    init(image: String, text: String) {
//        super.init(cornerRadius: 12)
        super.init(frame: .zero)
        
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
            $0.horizontalEdges.equalToSuperview().inset(12)
        }
        
        nextStack.snp.makeConstraints {
            $0.top.equalTo(recentStack.snp.bottom)
            $0.horizontalEdges.equalToSuperview().inset(8)
        }
        
        waterButton.snp.makeConstraints {
            $0.top.equalTo(nextStack.snp.bottom).offset(4)
            $0.horizontalEdges.bottom.equalToSuperview().inset(8)
        }
    }
    
    private func generateHorizontalStackView(of views: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views).then {
            $0.axis = .horizontal
            $0.spacing = 2
        }
        
        views[0].setContentHuggingPriority(.defaultLow, for: .horizontal)
        views[0].setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return stackView
    }
}
