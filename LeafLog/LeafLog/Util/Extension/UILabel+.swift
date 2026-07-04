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
    
    // 줄 간격 설정
    func setTextWithLineHeight(text: String, height: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = height
        paragraphStyle.maximumLineHeight = height
        
        var attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle
        ]
        
        if let font = font {
            attributes[.font] = font
        }
        if let textColor = textColor {
            attributes[.foregroundColor] = textColor
        }
        
        attributedText = NSAttributedString(
            string: text,
            attributes: attributes
        )
    }
}
