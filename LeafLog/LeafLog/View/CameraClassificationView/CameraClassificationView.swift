//
//  CameraClassificationView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/15/26.
//

import UIKit
import SnapKit
import Then

class CameraClassificationView: UIView {
    let cameraPreview = CameraPreview()
    let cameraFrame = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setCameraFrame()
    }
}

extension CameraClassificationView {
    private func setLayout() {
        addSubview(cameraPreview)
        layer.addSublayer(cameraFrame)
        
        cameraPreview.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func setCameraFrame() {
        cameraFrame.frame = self.bounds
        
        // 전체 영역
        let path = UIBezierPath(rect: self.bounds)
        
        // 프레임 영역
        let size: CGFloat = 224
        let bounds = self.bounds
        
        let frame = CGRect(
            x: bounds.midX - size / 2,
            y: bounds.midY - size / 2,
            width: size,
            height: size
            )
        let framePath = UIBezierPath(rect: frame)
        
        // path에 추가
        path.append(framePath)
        
        // evenOdd 설정 - 기본적으로는 path가 겹치는 부분을 채우지만, evenOdd의 경우 path가 겹치는 부분을 반대로 동작(없앰)
        cameraFrame.path = path.cgPath
        cameraFrame.fillRule = .evenOdd
        
        cameraFrame.fillColor = UIColor.grayScale600.withAlphaComponent(0.7).cgColor
    }
}
