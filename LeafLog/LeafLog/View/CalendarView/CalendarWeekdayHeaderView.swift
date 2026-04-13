//
//  CalendarWeekdayHeaderView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/13/26.
//

import UIKit
import SnapKit
import Then

class CalendarWeekdayHeaderView: UICollectionReusableView {
    init() {
        super.init(frame: .zero)
        
        let stackView = generateLabelStack()
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarWeekdayHeaderView {
    private func generateLabelStack() -> UIStackView {
        let labels = ["월", "화", "수", "목", "금", "토", "일"].reduce([UILabel]()) {
//            let label = UILabel(text: $1, config: .body12)
            let label = UILabel()
            label.text = $1
            label.font = .systemFont(ofSize: 12)
            
            return $0 + [label]
        }
        
        let stackView = UIStackView(arrangedSubviews: labels).then {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
        }
        
        return stackView
    }
}
