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

protocol CameraServiceProtocol {
    func checkCameraAuthorization() async throws
    func connectSession(preview: CameraPreview)
    func startSession()
}

class CameraServicePreview: CameraServiceProtocol {
    func checkCameraAuthorization() {}
    func startSession() {}
    func connectSession(preview: CameraPreview) {}
}

// 프로토콜화
class CameraService: CameraServiceProtocol {
    //MARK: 캡처 서비스를 이용하기 위한 조건
    // session: 앱이 OS의 캡처 인프라와 캡처 장치에 독점적으로 접근할 수 있도록 하고, 입력 장치 ~ 미디어 출력까지의 데이터 흐름을 관리하는 객체
    private var session = AVCaptureSession()
    private var delegate: AVCapturePhotoCaptureDelegate?
    
    // input은 미디어 소스 - 카메라처럼 '기록하는 디바이스'
    private var device: AVCaptureDevice {
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
    
    private func setupSession() throws {
        do {
            guard session.inputs.isEmpty else { return }
            
            session.beginConfiguration() // configuration 시작
            defer { session.commitConfiguration() } // configuration 설정 사항 commit - 함수 종료 직전에 호출함
            
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
        } catch {
            throw CameraError.sessionSettingFailed
        }
    }
    
    func checkCameraAuthorization() async throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            try await requestCameraAuthorization()
            
        case .denied, .restricted:
            throw CameraError.authorizationDenied
            
        default:
            break
        }
    }
    
    private func requestCameraAuthorization() async throws {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        
        if granted {
            try setupSession()
        } else {
            throw CameraError.authorizationDenied
        }
    }
    
    func startSession() {
        DispatchQueue.global().async {
            self.session.startRunning()
        }
    }
    
    func connectSession(preview: CameraPreview) {
        preview.videoPreviewLayer.session = session
    }
}

//MARK: Dependencies
// Dependency에 사용할 키 열거형
private enum CameraServiceKey: DependencyKey {
    static let liveValue: any CameraServiceProtocol = CameraService() // 실제 구현체
    static let previewValue: any CameraServiceProtocol = CameraServicePreview() // 프리뷰용 목업
}

extension DependencyValues {
    // Key로 CameraServiceKey 열거형 타입을 사용
    var cameraService: CameraServiceProtocol {
        get { self[CameraServiceKey.self] }
        set { self[CameraServiceKey.self] = newValue}
    }
}
