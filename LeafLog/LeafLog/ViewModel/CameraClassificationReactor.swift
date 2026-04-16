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

final class CameraClassificationReactor: Reactor {
    // 행동(트리거)
    enum Action {
        case viewWillAppear(CameraClassificationView)
    }
    
    // State를 변경시킬 값
    enum Mutation {
        case successSetup
        
        case cameraReady
        case error(String)
    }
    
    // (화면의) 상태
    struct State {
        @Pulse var isCameraAvailable: Bool = false
        @Pulse var errorMessage: String? = nil
        @Pulse var isCameraReady: Bool = false
    }
    
    // 최초 상태
    let initialState = State()
    
    //MARK: Properties
    @Dependency(\.cameraService) private var cameraService
    
    // Action -> Mutation -> State
    // Action을 Mutation으로 변환
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear(let cameraView):
//            return checkCameraAuthorization()
            return prepareCamera(view: cameraView)
        }
    }
    
    // Mutation을 State로 변환
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .successSetup:
            newState.isCameraAvailable = true
            
        case .cameraReady:
            newState.isCameraReady = true
            
        case .error(let message):
            newState.isCameraAvailable = false
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
                    try await self.cameraService.checkCameraAuthorization()
                    try await self.cameraService.connectPreview(view.cameraPreview)
                    await self.cameraService.runSession()
                    
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
    
    private func checkCameraAuthorization() -> Observable<Mutation> {
        return Observable.create { [weak self] observer in
            guard let self else {
                return Disposables.create()
            }
            
            Task {
                do {
                    try await self.cameraService.checkCameraAuthorization() // 카메라 권한만 확인하고 리턴
                    observer.onNext(.successSetup)
                    observer.onCompleted()
                } catch {
                    if let cameraError = error as? CameraError {
                        observer.onNext(.error(cameraError.message))
                    } else {
                        observer.onNext(.error("알 수 없는 에러입니다."))
                    }
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
}
