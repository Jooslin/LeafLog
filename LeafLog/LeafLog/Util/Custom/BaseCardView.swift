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

        backgroundColor = .grayScale50
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
