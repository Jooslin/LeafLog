//
//  CalendarBackgroundView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/13/26.
//

import UIKit

class CalendarBackgroundView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .grayScale50
        self.layer.cornerRadius = 12
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
