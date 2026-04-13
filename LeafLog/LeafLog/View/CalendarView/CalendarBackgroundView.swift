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
        self.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.00) // HEX #F7F7F7
        self.layer.cornerRadius = 12
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
