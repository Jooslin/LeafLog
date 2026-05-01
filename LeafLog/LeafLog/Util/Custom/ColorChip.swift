//
//  ColorChip.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/30/26.
//

import UIKit
import SnapKit
import Then

class ColorChip: UIView {
    private let size: CGFloat
    
    init(frame: CGRect, size: CGFloat = 8) {
        self.size = size
        super.init(frame: frame)
                
        let cornerRadius = size / 2
        
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        .init(width: size, height: size)
    }
    
}
