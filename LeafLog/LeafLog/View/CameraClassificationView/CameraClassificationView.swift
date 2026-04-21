//
//  CameraClassificationView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/15/26.
//

import UIKit
import SnapKit
import Then
import AVFoundation
import Dependencies
import RxSwift
import RxCocoa

class CameraClassificationView: UIView {
    fileprivate let titleView = TitleHeaderView(text: "AI 검색", hasBackButton: true).then {
        $0.apply(color: .white)
        $0.backgroundColor = .clear
    }
    
    let cameraPreview = CameraPreview()
    private let cameraFrame = CAShapeLayer()
    private(set) var guideFrameSize: CGRect = .zero // 가이드 프레임 사이즈
    
    private let guideBackground = BaseCardView(cornerRadius: 8).then {
        $0.backgroundColor = .white.withAlphaComponent(0.6)
    }
    
    private let guideLabel = UILabel(
        text: """
            프레임의 중앙에 하나의 식물을 놓아주세요.
            AI 검색 결과는 정확하지 않을 수 있습니다.
            """,
        config: .label14,
        color: .grayScale800
    )
    
    //TODO: 병합 후 주석 해제
    let shootButton = BottomSaveButton(title: "촬영하기").then { button in
        button.addAction(
            UIAction { _ in button.isEnabled = false },
            for: .touchUpInside
        )
    }
//    let shootButton = UIButton(configuration: .filled()).then { button in
//        button.setTitle("촬영하기", for: .normal)
//        button.addAction(
//            UIAction { _ in button.isEnabled = false },
//            for: .touchUpInside
//        )
//    }
    
    fileprivate let authDeniedView = CameraAuthNoticeView().then {
        $0.isHidden = true
    }
    
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
        addSubview(titleView)
        addSubview(guideBackground)
        addSubview(shootButton)
        addSubview(authDeniedView)
        
        guideBackground.addSubview(guideLabel)
        
        cameraPreview.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        titleView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.top.equalTo(safeAreaLayoutGuide)
        }
        
        guideBackground.snp.makeConstraints {
            $0.bottom.equalTo(shootButton.snp.top).offset(-32)
            $0.centerX.equalToSuperview()
        }
        
        shootButton.snp.makeConstraints {
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.height.equalTo(48)
        }
        
        guideLabel.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.verticalEdges.equalToSuperview().inset(8)
        }
        
        authDeniedView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    private func setCameraFrame() {
        cameraFrame.frame = self.bounds
        
        // 전체 영역
        let path = UIBezierPath(rect: self.bounds)
        
        // 프레임 영역
        let size: CGFloat = 280
        
        let topY = titleView.frame.maxY // titleView의 bottom Y 좌표
        let bottomY = guideBackground.frame.minY // guideBackground의 top Y좌표
        let centerY = (topY + bottomY) / 2.0 // Y 중앙값
        
        let frame = CGRect(
            x: self.bounds.midX - (size / 2.0),
            y: centerY - (size / 2.0),
            width: size,
            height: size
        )
        guideFrameSize = frame
        
        let framePath = UIBezierPath(rect: frame)
        
        // path에 추가
        path.append(framePath)
        
        // evenOdd 설정 - 기본적으로는 path가 겹치는 부분을 채우지만, evenOdd의 경우 path가 겹치는 부분을 반대로 동작(없앰)
        cameraFrame.path = path.cgPath
        cameraFrame.fillRule = .evenOdd
    }
    
    func configure(isAuthorized: Bool, isCameraReady: Bool) {
        if isAuthorized && isCameraReady {
            cameraFrame.fillColor = UIColor.grayScale600.withAlphaComponent(0.7).cgColor
            
            titleView.backgroundColor = .clear
            titleView.apply(color: .white)
            
            authDeniedView.isHidden = true
        } else {
            cameraFrame.fillColor = UIColor.white.cgColor
            
            titleView.backgroundColor = .white
            titleView.apply(color: .black)
            
            authDeniedView.isHidden = false
            
            isAuthorized ?
            authDeniedView.configure(with: .cameraNotReady)
            : authDeniedView.configure(with: .authorizationDenied)
        }
    }
}

extension Reactive where Base: CameraClassificationView {
    var backButtonTap: ControlEvent<Void> {
        base.titleView.rx.backButtonTap
    }
    
    var settingButtonTap: ControlEvent<Void> {
        base.authDeniedView.rx.settingButtonTap
    }
}
