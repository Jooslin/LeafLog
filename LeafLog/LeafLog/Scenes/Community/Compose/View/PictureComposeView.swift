//
//  PictureComposeView.swift
//  LeafLog
//
//  Created by 변예린 on 7/8/26.
//

import UIKit
import SnapKit
import Then

final class PictureComposeView: BaseCardView {
    private let dashedBorderLayer = CAShapeLayer()
    
    override init(frame: CGRect = .zero, cornerRadius: CGFloat = 12) {
        super.init(frame: frame, cornerRadius: cornerRadius)
        
        backgroundColor = .grayScale50
        
        dashedBorderLayer.fillColor = UIColor.clear.cgColor
        dashedBorderLayer.strokeColor = UIColor.grayScale100.cgColor
        dashedBorderLayer.lineWidth = 1
        dashedBorderLayer.lineDashPattern = [6, 4]
        dashedBorderLayer.zPosition = 1
        
        layer.addSublayer(dashedBorderLayer)
        
    }
    
    @available(*, unavailable)
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        dashedBorderLayer.frame = bounds
        dashedBorderLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: layer.cornerRadius
        ).cgPath
    }
}
