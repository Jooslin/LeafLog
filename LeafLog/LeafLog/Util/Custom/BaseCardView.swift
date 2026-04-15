//
//  BaseCardView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/12/26.
//

import UIKit
import SnapKit

class BaseCardView: UIView {
    
    init(frame: CGRect = .zero, cornerRadius: CGFloat = 8) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.00) // HEX #F7F7F7
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
