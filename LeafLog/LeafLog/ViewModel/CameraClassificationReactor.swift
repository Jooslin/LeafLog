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

final class CameraClassificationReactor: Reactor {
    // 행동(트리거)
    enum Action {
        case viewWillAppear(CameraClassificationView)
        case capture(CGRect) // normalized guide frame
    }
    
    // State를 변경시킬 값
    enum Mutation {
        case cameraReady
        case captureImageData(CGRect, Data) // normalized guide frame, image data
        case error(String)
    }
    
    // (화면의) 상태
    struct State {
        @Pulse var isCameraReady: Bool = false
    
        @Pulse var classificationResult: UIImage? = nil
        
        @Pulse var errorMessage: String? = nil
    }
    
    // 최초 상태
    let initialState = State()
    
    //MARK: Properties
    @Dependency(\.cameraService) private var cameraService
    @Dependency(\.plantClassificationService) private var plantClassificationService
    
    // Action -> Mutation -> State
    // Action을 Mutation으로 변환
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear(let cameraView):
            return prepareCamera(view: cameraView)
            
        case .capture(let normalizedRect):
            return cameraService.capturePhoto()
                .asObservable()
                .map { .captureImageData(normalizedRect, $0) }
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
        case .cameraReady:
            newState.isCameraReady = true

        case .captureImageData(let normalizedRect, let data):
            
            newState.classificationResult = plantClassificationService.cropCapturedImage(
                data,
                normalizedRect: normalizedRect
            )
            
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
                } catch let error as CameraError {
                    observer.onNext(.error(error.message))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.error("알 수 없는 에러입니다."))
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
}
