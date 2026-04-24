//
//  LoginReactor.swift
//  LeafLog
//
//  Created by 김주희 on 4/5/26.
//

import Foundation
import UIKit
import ReactorKit
import Supabase
import Dependencies

final class LoginReactor: Reactor {
    
    @Dependency(\.authService) private var authService
    @Dependency(\.fcmManager) private var fcmManager
    
    enum Action {
        case viewDidLoad
        case appleLoginTapped(UIViewController)
        case googleLoginTapped(UIViewController)
        case kakaoLoginTapped
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setAppleLoginBlocked(Bool)
        case setLoginSuccess
        case setError(String)
    }
    
    struct State {
        var isLoading: Bool = false
        var isAppleLoginBlocked = false
        @Pulse var loginSuccess: Bool = false
        @Pulse var errorMessage: String? = nil
    }
    
    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return observeAppleLoginCooldown()

        case .appleLoginTapped(let presentingViewController):
            guard currentState.isAppleLoginBlocked == false else {
                return .just(.setError("Apple 계정 연결 해제 처리 중입니다. 잠시 후 다시 시도해주세요."))
            }

            return loginFlow {
                try await self.authService.startAppleNativeLogin(
                    presentingViewController: presentingViewController
                )
            }

        case .googleLoginTapped(let presentingViewController):
            return loginFlow {
                try await self.authService.startGoogleNativeLogin(
                    presentingViewController: presentingViewController
                )
            }
            
        case .kakaoLoginTapped:
            return loginFlow { try await self.authService.startKakaoNativeLogin() }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setAppleLoginBlocked(let isBlocked):
            newState.isAppleLoginBlocked = isBlocked
            
        case .setLoginSuccess:
            newState.isLoading = false
            newState.loginSuccess = true
            
        case .setError(let message):
            newState.isLoading = false
            newState.errorMessage = message
        }
        return newState
    }

    private func observeAppleLoginCooldown() -> Observable<Mutation> {
        Observable.create { observer in
            let task = Task {
                // 1초마다 상태 확인하기
                while Task.isCancelled == false {
                    let isBlocked = self.authService.isAppleLoginCooldownActive()
                    observer.onNext(.setAppleLoginBlocked(isBlocked))

                    guard isBlocked else { break }

                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }

                observer.onCompleted()
            }

            // 화면이 꺼졌을때
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    private func loginFlow(_ login: @escaping () async throws -> Supabase.User) -> Observable<Mutation> {
        return Observable.create { [weak self] observer in
            observer.onNext(.setLoading(true))
            let task = Task {
                do {
                    _ = try await login()
                    self?.fcmManager.syncCurrentFCMTokenIfPossible()
                    observer.onNext(.setLoginSuccess)
                    observer.onCompleted()
                } catch let error as AuthError {
                    if case .cancelled = error {
                        // 취소는 조용히 로딩만 해제
                        observer.onNext(.setLoading(false))
                    } else {
                        observer.onNext(.setError(error.userMessage))
                    }
                    observer.onCompleted()
                } catch {
                    // AuthError 외의 예상치 못한 에러
                    observer.onNext(.setError(error.localizedDescription))
                    observer.onCompleted()
                }
            }
            return Disposables.create() {
                task.cancel()
            }
            
        }
    }
}
