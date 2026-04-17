//
//  CameraPreview.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/15/26.
//

import UIKit
import AVFoundation

class CameraPreview: UIView {
    // 기본적으로 layer에 사용되는 CALayer 타입을 AVCaptureVideoPreviewLayer 타입으로 변경
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    /* AVCaptureVideoPreviewLayer로 인식하는 videoPreviewLayer 변수 생성
        - override 코드를 통해 기본 제공되는 layer를 AVCaptureVideoPreviewLayer 타입으로 변경해줬지만 컴파일러는 여전히 layer를 CALayer로 인식함
            -> 매번 타입 캐스팅하지 않고 AVCaptureVideoPreviewLayer 타입으로 사용 가능하도록 변수 선언
            -> AVCaptureVideoPreviewLayer는 CALayer를 상속하므로 UIView의 layer(CALayer)가 제공하는 기능 모두 사용 가능
     */
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = bounds // 오토레이아웃 설정이 모두 끝난 크기로 레이어 크기 설정
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }
}
