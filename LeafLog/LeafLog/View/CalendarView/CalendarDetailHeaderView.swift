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
        $0.image = .badgeWater
    }
    
    //TODO: LabelConfiguration 적용 시 주석 해제
//    private let nameLabel = UILabel(text: "물주기", config: .title14)
    private let manageLabel = UILabel().then {
        $0.text = "물주기"
        $0.font = .systemFont(ofSize: 14, weight: .bold)
        $0.textAlignment = .left
    }
    
    //TODO: 추후 colorchip label로 교체 필요
    private let completeLabel = UILabel().then {
        $0.text = "완료"
        $0.backgroundColor = .systemGray
        $0.layer.cornerRadius = 8
    }
    
    private let separateBar = SeparateBar()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarDetailHeaderView {
    private func setLayout() {
        let stackView = generateStackView()
        
        addSubview(stackView)
        addSubview(separateBar)
        
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.top.equalToSuperview().offset(12)
        }
        
        separateBar.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.top.equalTo(stackView.snp.bottom).offset(12)
            $0.bottom.equalToSuperview()
        }
    }
    
    private func generateStackView() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [badge, manageLabel, completeLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }
        
        manageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        manageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return stackView
    }
}

extension CalendarDetailHeaderView {
    //TODO: Badge 열거형 및 configure 함수 수정 필요
    func configure(_ manageCategory: CalendarView.Badge) {
        badge.image = UIImage(named: manageCategory.rawValue)
        manageLabel.text = manageCategory.rawValue
    }
}
