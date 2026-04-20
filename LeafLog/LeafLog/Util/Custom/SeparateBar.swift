//
//  SeparateBar.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/12/26.
//

import UIKit

class SeparateBar: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .grayScale100
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
            return CGSize(width: UIView.noIntrinsicMetric, height: 1)
    }
}
