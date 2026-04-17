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
import RxSwift

protocol CameraServiceProtocol {
    func checkCameraAuthorization() async throws
    func connectPreview(_ preview: CameraPreview) async throws
    
    func runSession() async
    func stopRunningSession() async
    
    func capturePhoto() -> Single<Data>
}

class CameraServicePreview: CameraServiceProtocol {
    func checkCameraAuthorization() {}
    func connectPreview(_ preview: CameraPreview) async {}

    func runSession() {}
    func stopRunningSession() {}
    
    func capturePhoto() -> Single<Data> { return Single.just(Data())}
}

// 프로토콜화
actor CameraService: NSObject, CameraServiceProtocol {
    //MARK: 캡처 서비스를 이용하기 위한 조건
    // session: 앱이 OS의 캡처 인프라와 캡처 장치에 독점적으로 접근할 수 있도록 하고, 입력 장치 ~ 미디어 출력까지의 데이터 흐름을 관리하는 객체
    private var session = AVCaptureSession()
    private var delegate: AVCapturePhotoCaptureDelegate?
    
    private let output = AVCapturePhotoOutput() // 사진 캡처 결과물
    private var capturedSubject: AsyncSubject<Data>? // 촬영이 끝날 때까지 결과를 잠시 보관할 객체 - 매 촬영마다 새로운 값
    
}

//MARK: Authorization
extension CameraService {
    // 카메라 권한 확인 메서드 - 권한만 확인하고 리턴
    func checkCameraAuthorization() async throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video) // 카메라 권한 요청
            if !granted {
                throw CameraError.authorizationDenied
            }
        case .denied, .restricted:
            throw CameraError.authorizationDenied
        @unknown default:
            throw CameraError.authorizationDenied
        }
    }
    
    // 카메라 권한 요청 메서드
    private func requestCameraAuthorization() async throws {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        
        if granted {
            try prepareSession()
        } else {
            throw CameraError.authorizationDenied
        }
    }
}

//MARK: Session Setup
extension CameraService {
    func prepareSession() throws {
        guard session.inputs.isEmpty else { return } // 세션 중복 설정 방지
        
        session.beginConfiguration() // configuration 시작
        defer { session.commitConfiguration() } // configuration 설정 사항 commit - 함수 종료 직전에 호출
        
        // 데이터를 기록할 카메라 디바이스
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) // 1구 후면 카메라
        else {
            throw CameraError.sessionSettingFailed
        }
        
        // 입력받을 미디어 소스
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraError.sessionSettingFailed
        }
        session.addInput(input)
        

        let videoOutput = AVCaptureVideoDataOutput() // 프레임별로 생성하는 사진 캡처 결과물
        guard session.canAddOutput(output),
              session.canAddOutput(videoOutput) else {
            throw CameraError.sessionSettingFailed
        }
        
        session.addOutput(output)
        session.addOutput(videoOutput)
        
        session.sessionPreset = .high // output 퀄리티 설정 - 사진의 화질을 설정하는 느낌
    }
    
    // 프리뷰 - 세션 연결 메서드
    func connectPreview(_ preview: CameraPreview) async throws {
        try prepareSession() // 세션 준비
        let currentSession = session // 현재 카메라 서비스 액터에 있는 세션을 캡처
        
        // 카메라 세션 연결 작업은 UI작업이라 메인 액터에서 진행
        await MainActor.run {
            guard preview.videoPreviewLayer.session != currentSession else { return } // 세션이 동일하지 않을 경우에만 세션 연결 진행
            preview.videoPreviewLayer.session = currentSession
        }
    }
}

//MARK: Perform Session
extension CameraService {
    // 세션 시작 메서드
    func runSession() async {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
              !session.isRunning else { return }
        
        // withCheckedContinuation: startRunning()이 끝나면 resume을 통해 신호를 보냄
        // -> startSession()을 await한 쪽에서 startSession 작업이 끝났다는 것을 알 수 있음
        await withCheckedContinuation { continuation in
            // startRunning은 동작에 시간이 오래 걸리는 함수이므로 스레드를 혼자 점유하지 않도록 비동기로 실행
            Task.detached(priority: .userInitiated) { [session] in
                session.startRunning()
                continuation.resume()
            }
        }
    }
    
    // 세션 중단 메서드
    func stopRunningSession() async {
        guard session.isRunning else { return }
        
        await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) { [session] in
                session.stopRunning()
                continuation.resume()
            }
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func capturePhoto() -> Single<Data> {
        let subject = AsyncSubject<Data>() // 현재 촬영 결과로 사용할 새로운 subject 생성 - AsyncSubject는 onCompleted()가 호출된 시점에 가장 최근값을 방출
        self.capturedSubject = subject // 현재 촬영 결과를 관찰
        
        let photoSettings = AVCapturePhotoSettings()
        output.capturePhoto(with: photoSettings, delegate: self)
        
        return subject.asSingle()
    }
    
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        Task { [weak self] in
            guard let self else { return }
            
            if let error {
                await self.finishCapture(result: .failure(error))
                return
            }
            
            guard let imageData = photo.fileDataRepresentation() else {
                await self.finishCapture(result: .failure(CameraError.captureDataFailed))
                return
            }
            
            await self.finishCapture(result: .success(imageData))
        }
    }
    
    // 캡처 결과 -> PublishSubject로 방출
    private func finishCapture(result: Result<Data, Error>) {
        switch result {
        case .success(let data):
            capturedSubject?.onNext(data)
            capturedSubject?.onCompleted()
            capturedSubject = nil
        case .failure(let error):
            capturedSubject?.onError(error)
            capturedSubject = nil
        }
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
