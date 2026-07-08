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
    
    private let plusImageView = UIImageView(image: .plus).then {
        $0.tintColor = .primary800
    }
    
    private let pictureAddLabel = UILabel(text: "사진 추가", config: .label12, color: .primary800)
    
    private(set) lazy var addStack = UIStackView(arrangedSubviews: [plusImageView, pictureAddLabel]).then {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .center
    }
    
    override init(frame: CGRect = .zero, cornerRadius: CGFloat = 12) {
        super.init(frame: frame, cornerRadius: cornerRadius)
        
        backgroundColor = .grayScale50
        
        dashedBorderLayer.fillColor = UIColor.clear.cgColor
        dashedBorderLayer.strokeColor = UIColor.grayScale100.cgColor
        dashedBorderLayer.lineWidth = 1
        dashedBorderLayer.lineDashPattern = [6, 4]
        dashedBorderLayer.zPosition = 1
        
        layer.addSublayer(dashedBorderLayer)
        
        setLayout()
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

//MARK: Layout
extension PictureComposeView {
    private func setLayout() {
        addSubview(addStack)
        
        addStack.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        plusImageView.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
    }
}
