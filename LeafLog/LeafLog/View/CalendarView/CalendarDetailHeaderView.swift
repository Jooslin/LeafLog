//
//  CalendarDetailHeaderView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/13/26.
//

import UIKit
import SnapKit
import Then

class CalendarDetailHeaderView: UICollectionReusableView {
    
    private let badge = UIImageView().then {
        $0.image = .badgeWaterBig
        $0.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
    }
    
    private let manageLabel = UILabel(text: "", config: .title14)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarDetailHeaderView {
    private func setLayout() {
        let stackView = generateStackView()
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.top.equalToSuperview().offset(39)
        }
    }
    
    private func generateStackView() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [badge, manageLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }
        
        manageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        manageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        badge.setContentHuggingPriority(.required, for: .horizontal)
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return stackView
    }
}

extension CalendarDetailHeaderView {
    func configure(_ manageCategory: Badge) {
        badge.image = UIImage(named: manageCategory.bigImage)
        manageLabel.text = manageCategory.rawValue
    }
}
