//
//  PaddingLabel.swift
//  LeafLog
//
//  Created by Yeseul Jang on 7/9/26.
//

import UIKit

final class PaddingLabel: UILabel {
    private let horizontalInset: CGFloat
    private let verticalInset: CGFloat
    
    init(horizontalInset: CGFloat, verticalInset: CGFloat) {
        self.horizontalInset = horizontalInset
        self.verticalInset = verticalInset
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + horizontalInset * 2,
            height: size.height + verticalInset * 2
        )
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
        super.drawText(in: rect.inset(by: insets))
    }
}

