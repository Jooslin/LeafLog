//
//  UILabel+.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/10/26.
//
import UIKit

extension UILabel {
    func apply(
        _ config: LabelConfiguration,
        color: UIColor? = nil,
        lines: Int? = nil
    ) {
        self.font = UIFontMetrics(forTextStyle: config.textStyle).scaledFont(for: config.font)
        self.adjustsFontForContentSizeCategory = true
        self.textColor = color ?? config.color
        self.numberOfLines = lines ?? config.lines
    }
    
    convenience init(
        text: String = "",
        config: LabelConfiguration,
        color: UIColor? = nil,
        lines: Int? = nil
    ) {
        self.init()
        self.text = text
        apply(config, color: color, lines: lines)
    }
}
