//
//  UISegmentedControl+.swift
//  LeafLog
//
//  Created by 변예린 on 8/10/26.
//

import UIKit

extension UISegmentedControl {
    convenience init(categories: [String]) {
        self.init(items: categories)
        
        selectedSegmentIndex = 0
        
        backgroundColor = .grayScale100
        selectedSegmentTintColor = .primary600
        
        setTitleTextAttributes(
            [.foregroundColor: UIColor.grayScale400,
             .font: UIFont.systemFont(ofSize: 14, weight: .regular)],
            for: .normal)
        
        setTitleTextAttributes(
            [.foregroundColor: UIColor.white,
             .font: UIFont.systemFont(ofSize: 14, weight: .medium)],
            for: .selected)
    }
}
