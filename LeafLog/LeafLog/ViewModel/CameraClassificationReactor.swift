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
        case error(String)
    }
    
    // (화면의) 상태
    struct State {
        @Pulse var isCameraAvailable: Bool = false
        @Pulse var errorMessage: String? = nil
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
            return checkCameraAuthorization()
        }
    }
    
    // Mutation을 State로 변환
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .successSetup:
            newState.isCameraAvailable = true
            
        case .error(let message):
            newState.isCameraAvailable = false
            newState.errorMessage = message
        }
        
        return newState
    }
}

extension CameraClassificationReactor {
    /* 기존 코드 보충 (setupSession이 완료될 때까지 기다리던 버전 - 느림)
    private func checkCameraAuthorization() -> Observable<Mutation> {
        return Observable.create { [weak self] observer in
            guard let self else {
                return Disposables.create()
            }
            
            Task {
                do {
                    try await self.cameraService.checkCameraAuthorization()
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
    */
    
    // 🚀 속도 최적화: 서비스의 checkCameraAuthorization이 이제 하드웨어 설정을 기다리지 않고 
    // 권한 확인 즉시 리턴하므로, 리액터도 매우 빠르게 .successSetup을 보낼 수 있습니다.
    private func checkCameraAuthorization() -> Observable<Mutation> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            Task {
                do {
                    // 이제 Service의 이 함수는 권한만 확인하고 하드웨어 세팅은 백그라운드 태스크로 넘긴 뒤 즉시 리턴합니다.
                    try await self.cameraService.checkCameraAuthorization()
                    
                    // 따라서 지연 없이 즉시 성공 신호를 뷰에 보낼 수 있습니다.
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
