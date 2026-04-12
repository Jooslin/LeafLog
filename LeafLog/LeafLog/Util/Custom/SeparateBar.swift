//
//  SeparateBar.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/12/26.
//

import UIKit
import SnapKit

class SeparateBar: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(red: 0.89, green: 0.89, blue: 0.89, alpha: 1.00) // HEX #E3E3E3
        
        self.snp.makeConstraints {
            $0.height.equalTo(1)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
