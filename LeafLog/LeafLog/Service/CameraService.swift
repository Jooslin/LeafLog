//
//  CameraService.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/15/26.
//

import Foundation
import AVFoundation
import UIKit
import Dependencies

class CameraService {
    //MARK: 캡처 서비스를 이용하기 위한 조건
    // session: 앱이 OS의 캡처 인프라와 캡처 장치에 독점적으로 접근할 수 있도록 하고, 입력 장치 ~ 미디어 출력까지의 데이터 흐름을 관리하는 객체
    var session = AVCaptureSession()
    var delegate: AVCapturePhotoCaptureDelegate?
    
    // input은 미디어 소스 - 카메라처럼 '기록하는 디바이스'
    var device: AVCaptureDevice {
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) { // 3구 후면 카메라
            return device
        } else if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) { // 2구 후면 카메라
            return device
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) { // 1구 후면 카메라
            return device
        } else {
            fatalError("후면 카메라 기기를 찾을 수 없습니다.")
        }
    }
    
    func setupSession() throws {
        do {
            // set Input
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else { return } // 유효한 input일 경우에만 계속
            session.addInput(input)
            
            // set Output
            let output = AVCapturePhotoOutput() // 사진 캡처 결과물
            let videoOutput = AVCaptureVideoDataOutput() // 프레임별로 생성하는 사진 캡처 결과물
            guard session.canAddOutput(output),
                  session.canAddOutput(videoOutput) else { return }
            
            session.sessionPreset = .photo // output 퀄리티 설정 - 사진의 화질을 설정하는 느낌
            session.addOutput(output)
            session.addOutput(videoOutput)
            session.commitConfiguration()
        } catch {
            throw CameraError.sessionSettingFailed
        }
    }
}

//MARK: Error 타입
extension CameraService {
    enum CameraError: Error {
        case sessionSettingFailed
    }
}

//MARK: Dependencies
extension CameraService: DependencyKey {
    static var liveValue: CameraService {
        CameraService()
    }
}

extension DependencyValues {
    var cameraService: CameraService {
        get { self[CameraService.self] }
        set { self[CameraService.self] = newValue }
    }
}
