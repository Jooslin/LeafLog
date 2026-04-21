//
//  CalendarDateFooterView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/13/26.
//

import UIKit
import SnapKit
import Then

class CalendarDateLabelCell: UICollectionViewCell {
    let label = UILabel(text: "", config: .label16)
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(label)
        
        label.snp.makeConstraints {

            $0.leading.equalToSuperview()
            $0.top.equalToSuperview().offset(32)
            $0.bottom.equalToSuperview().inset(16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarDateLabelCell {
    func configure(_ dateString: String) {
        label.text = dateString
    }
}
