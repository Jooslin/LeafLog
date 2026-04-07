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

final class LoginReactor: Reactor {
    
    enum Action {
        case googleLoginTapped(UIViewController)
        case kakaoLoginTapped
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setLoginSuccess
        case setError(String)
    }
    
    struct State {
        var isLoading: Bool = false
        @Pulse var loginSuccess: Bool = false
        @Pulse var errorMessage: String? = nil
    }
    
    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .googleLoginTapped(let presentingViewController):
            return loginFlow {
                try await AuthService.shared.startGoogleNativeLogin(
                    presentingViewController: presentingViewController
                )
            }
            
        case .kakaoLoginTapped:
            return loginFlow { try await AuthService.shared.startKakaoNativeLogin() }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
            
        case .setLoginSuccess:
            newState.isLoading = false
            newState.loginSuccess = true
            
        case .setError(let message):
            newState.isLoading = false
            newState.errorMessage = message
        }
        return newState
    }
    
    private func loginFlow(_ login: @escaping () async throws -> Supabase.User) -> Observable<Mutation> {
        return Observable.create { observer in
            observer.onNext(.setLoading(true))
            let task = Task {
                do {
                    _ = try await login()
                    observer.onNext(.setLoginSuccess)
                    observer.onCompleted()
                } catch let error as AuthError {
                    switch error {
                    case .cancelled:
                        // 취소는 조용히 로딩만 해제
                        observer.onNext(.setLoading(false))
                    case .loginFailed(let message),
                         .sessionFailed(let message):
                        observer.onNext(.setError(message))
                    case .invalidCallbackURL:
                        observer.onNext(.setError("잘못된 로그인 URL입니다."))
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
