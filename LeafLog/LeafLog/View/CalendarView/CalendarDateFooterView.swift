//
//  CalendarDateFooterView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/13/26.
//

import UIKit
import SnapKit
import Then

class CalendarDateFooterView: UICollectionReusableView {    
    let label = UILabel(text: "", config: .label14)
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(label)
        
        label.snp.makeConstraints {

            $0.leading.equalToSuperview().offset(-24)
            $0.top.equalToSuperview().offset(44)
            $0.bottom.equalToSuperview().inset(4)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarDateFooterView {
    func configure(_ dateString: String) {
        label.text = dateString
    }
}
