//
//  CalendarFilterCell.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then

final class CalendarFilterCell: UICollectionViewCell {
    
    //TODO: 추후 component 교체 필요
    private let buttons = [
        UIButton(configuration: .plain()),
        UIButton(configuration: .plain()),
        UIButton(configuration: .plain()),
        UIButton(configuration: .plain()),
        UIButton(configuration: .plain())
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setButtonAttributes()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarFilterCell {
    private func setButtonAttributes() {
        for i in 0..<buttons.count {
            buttons[i].tag = i
        }
    }
    
    private func setLayout() {
        let buttonStack = generateButtonStack()
        
        contentView.addSubview(buttonStack)
        
        buttonStack.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }
    
    private func generateButtonStack() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: buttons).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.distribution = .fill
        }
        
        return stackView
    }
}

extension CalendarFilterCell {
    func configure(_ data: [String]) {
        buttons.forEach {
            $0.setTitle(data[$0.tag], for: .normal)
        }
    }
}
