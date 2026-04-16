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
    func connectSession(preview: CameraPreview) async
    func startSession() async
    func stopRunningSession() async
}

class CameraServicePreview: CameraServiceProtocol {
    func checkCameraAuthorization() {}
    func connectSession(preview: CameraPreview) {}
    func startSession() {}
    func stopRunningSession() {}
}

// 프로토콜화
actor CameraService: CameraServiceProtocol {
    //MARK: 캡처 서비스를 이용하기 위한 조건
    // session: 앱이 OS의 캡처 인프라와 캡처 장치에 독점적으로 접근할 수 있도록 하고, 입력 장치 ~ 미디어 출력까지의 데이터 흐름을 관리하는 객체
    private var session = AVCaptureSession()
    private var delegate: AVCapturePhotoCaptureDelegate?
    
    // 중복 세팅 방지 플래그
    private var isSettingUp = false
    
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
}

//MARK: Session Setup
extension CameraService {
    // 카메라 세션 설정 명령 메서드
    private func setupSession() throws {
        guard !isSettingUp && session.inputs.isEmpty else { return }
        isSettingUp = true
        
        // 세션 설정은 무거운 작업이므로 별도 태스크로 우선 분리 - 별도 태스크로 보냈으므로 setupSession을 호출한 리액터가 Task 내부 동작을 기다리지 않음
        Task.detached(priority: .userInitiated) { [weak self] in
            // 다시 액터로 진입하여 설정 진행
            try await self?.performSessionSetup()
        }
    }
    
    // 카메라 세션 설정 실행 메서드
    private func performSessionSetup() throws {
        session.beginConfiguration() // configuration 시작
        defer { session.commitConfiguration() } // configuration 설정 사항 commit - 함수 종료 직전에 호출함
        
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
        } catch {
            throw CameraError.sessionSettingFailed
        }
    }
}

//MARK: Authorization
extension CameraService {
    // 카메라 권한 확인 메서드 - 권한만 확인하고 리턴
    func checkCameraAuthorization() async throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            try setupSession() // await하지 않고 동작만 실행시키고 바로 리턴
            
        case .notDetermined:
            try await requestCameraAuthorization()
            
        case .denied, .restricted:
            throw CameraError.authorizationDenied
            
        default:
            break
        }
    }
    
    // 카메라 권한 요청 메서드
    private func requestCameraAuthorization() async throws {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        
        if granted {
            try setupSession() // 권한 허용 즉시 세션 설정 시작
        } else {
            throw CameraError.authorizationDenied
        }
    }
}

//MARK: Perform Session
extension CameraService {
    // 세션 시작 메서드
    func startSession() {
        guard !session.isRunning else { return }
        
        // startRunning은 동작에 시간이 오래 걸리는 함수이므로 스레드를 혼자 점유하지 않도록 비동기로 실행
        Task.detached(priority: .userInitiated) { [session] in
            session.startRunning()
        }
    }
    
    // 세션 연결 메서드
    func connectSession(preview: CameraPreview) async {
        let currentSession = self.session // 현재 카메라 서비스 액터에 있는 세션을 캡처
        
        // 카메라 세션 연결 작업은 UI작업이라 메인 액터에서 진행
        await MainActor.run {
            guard preview.videoPreviewLayer.session != currentSession else { return } // 세션이 동일하지 않을 경우에만 세션 연결 진행
            preview.videoPreviewLayer.session = currentSession
        }
    }
    
    // 세션 중단 메서드
    func stopRunningSession() {
        guard session.isRunning else { return }
        session.stopRunning()
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
