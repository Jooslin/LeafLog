//
//  CameraClassificationReactor.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/15/26.
//

import UIKit
import ReactorKit
import RxSwift
import Dependencies
import AVFoundation
import OSLog

final class CameraClassificationReactor: Reactor {
    // 행동(트리거)
    enum Action {
        case viewWillAppear(CameraClassificationView)
        case capture(CGRect) // normalized guide frame
    }
    
    // State를 변경시킬 값
    enum Mutation {
        case authDenied
        case cameraReady
        case cameraNotReady
        case analyzeResult([String: PlantClassificationService.Confidence]) // [식물 학명: 일치율]
        case error(String)
    }
    
    // (화면의) 상태
    struct State {
        @Pulse var isAuthorized: Bool = false
        @Pulse var isCameraReady: Bool = false
    
        var classificationResult: [String: PlantClassificationService.Confidence] = [:]
        
        @Pulse var errorMessage: String? = nil
    }
    
    // 최초 상태
    let initialState = State()
    
    //MARK: Properties
    @Dependency(\.cameraService) private var cameraService
    @Dependency(\.plantClassificationService) private var plantClassificationService
    private let logger = Logger.init(subsystem: "LeafLog", category: "CameraClassificationReactor")
    
    // Action -> Mutation -> State
    // Action을 Mutation으로 변환
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear(let cameraView):
            return prepareCamera(view: cameraView)
            
        case .capture(let normalizedRect):
            return cameraService.capturePhoto()
                .asObservable()
                .withUnretained(self)
                .flatMap { `self`, data in
                    return self.analyzeImage(data, normalizedRect: normalizedRect)
                }
                .catch { error in
                    if let cameraError = error as? CameraError {
                        return Observable.just(.error(cameraError.message))
                    } else {
                        return Observable.just(.error("알 수 없는 오류입니다."))
                    }
                }
        }
    }
    
    // Mutation을 State로 변환
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .authDenied:
            newState.isAuthorized = false
            newState.isCameraReady = false
            
        case .cameraReady:
            newState.isAuthorized = true
            newState.isCameraReady = true
            
        case .cameraNotReady:
            newState.isCameraReady = false

        case .analyzeResult(let results):
            newState.classificationResult = results
            
        case .error(let message):
            newState.isCameraReady = false
            newState.errorMessage = message
        }
        
        return newState
    }
}

extension CameraClassificationReactor {
    private func prepareCamera(view: CameraClassificationView) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            
            Task {
                do {
                    try await self.cameraService.checkCameraAuthorization() // 카메라 권한 확인
                    try await self.cameraService.connectPreview(view.cameraPreview) // 프리뷰 - 세션 연결
                    await self.cameraService.runSession() // 세션 시작
                    
                    observer.onNext(.cameraReady)
                    observer.onCompleted()
                } catch {
                    if let cameraError = error as? CameraError {
                        switch cameraError {
                        case .authorizationDenied:
                            observer.onNext(.authDenied)
                            observer.onCompleted()
                        case .sessionSettingFailed:
                            observer.onNext(.cameraNotReady)
                            observer.onCompleted()
                        case .captureDataFailed:
                            break
                        }
                    } else {
                        observer.onNext(.error("알 수 없는 에러입니다."))
                        observer.onCompleted()
                    }
                }
            }
            return Disposables.create()
        }
    }
}

extension CameraClassificationReactor {
    private func analyzeImage(_ imageData: Data, normalizedRect: CGRect) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            
            let cropImage = self.plantClassificationService.cropCapturedImage(imageData, normalizedRect: normalizedRect)
            guard let cropImage else {
                observer.onNext(.analyzeResult([:]))
                observer.onCompleted()
                return Disposables.create()
            }
            
            Task { [weak self] in
                guard let self else { return }
                do {
                    let classificationResult = try self.plantClassificationService.analyzeImage(image: cropImage)
                    observer.onNext(.analyzeResult(classificationResult))
                    observer.onCompleted()
                } catch {
                    self.logger.error("이미지 분석 실패: \(error.localizedDescription)")
                    observer.onNext(.analyzeResult([:]))
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}
