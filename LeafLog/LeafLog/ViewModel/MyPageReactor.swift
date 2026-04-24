//
//  MyPageReactor.swift
//  LeafLog
//
//  Created by OpenAI Codex on 4/13/26.
//

import Foundation
import ReactorKit
import RxSwift
import Dependencies
import OSLog

final class MyPageReactor: Reactor {
    
    @Dependency(\.authService) private var authService
    @Dependency(\.profileDBManager) private var profileDBManager
    @Dependency(\.notificationManager) private var notificationManager
    private let logger = Logger.init(subsystem: "LeafLog", category: "MyPageReactor")
    
    enum Action {
        case viewWillAppear // 최신 프로필 불러오기
        case editProfileTapped
        case logoutTapped
        case withdrawalTapped
        case inquiryTapped
        case reportErrorTapped
        case pushAlertSwitchTapped(Bool)
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setSubmitting(Bool)
        case setProfile(UserProfileModel)
        case setRouteToEdit(UserProfileModel?)
        case setMoveToLogin(Bool)
        case setErrorMessage(String?)
        case setRouteToMail(isError: Bool)
        case setPushAlert(Bool)
    }
    
    struct State {
        var isLoading = false
        var isSubmitting = false
        var profile: UserProfileModel? // 유저 프로필 데이터
        @Pulse var routeToEdit: UserProfileModel?
        @Pulse var moveToLogin = false
        @Pulse var errorMessage: String?
        @Pulse var routeToMail: Bool? // true면 오류 신고, false면 일반 문의 버전
        @Pulse var pushAlertIsOn: Bool = true
    }
    
    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return loadProfile() // 프로필 로드
            
        case .editProfileTapped:
            guard let profile = currentState.profile else {
                return .just(.setErrorMessage("프로필 정보를 먼저 불러와주세요."))
            }
            return .just(.setRouteToEdit(profile))
            
        case .logoutTapped:
            return runAccountAction {
                try await self.authService.signOut()
            }
            
        case .withdrawalTapped:
            return runAccountAction {
                try await self.authService.withdrawAccount()
            }
            
        case .inquiryTapped:
            return .just(.setRouteToMail(isError: false))
            
        case .reportErrorTapped:
            return .just(.setRouteToMail(isError: true))
            
        case .pushAlertSwitchTapped(let isOn):
            return updateNotificationAllowance(isOn: isOn)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
            
        case .setSubmitting(let isSubmitting):
            newState.isSubmitting = isSubmitting
            
        case .setProfile(let profile):
            newState.isLoading = false
            newState.profile = profile
            
        case .setRouteToEdit(let profile):
            newState.routeToEdit = profile
            
        case .setMoveToLogin(let moveToLogin):
            newState.isSubmitting = false
            newState.moveToLogin = moveToLogin
            
        case .setErrorMessage(let message):
            newState.isLoading = false
            newState.isSubmitting = false
            newState.errorMessage = message
            
        case .setRouteToMail(let isError):
            newState.routeToMail = isError
            
        case .setPushAlert(let isOn):
            newState.pushAlertIsOn = isOn
        }
        
        return newState
    }
    
    /// 마이페이지 진입 시 프로필을 읽고, 없으면 기본 프로필을 만들기
    private func loadProfile() -> Observable<Mutation> {
        Observable.create { observer in
            observer.onNext(.setLoading(true))
            
            let task = Task {
                do {
                    let profile: UserProfileModel
                    if let existingProfile = try await self.profileDBManager.fetchMyProfile() {
                        profile = existingProfile
                    } else {
                        profile = try await self.profileDBManager.createProfileIfNeeded()
                    }
                    
                    observer.onNext(.setProfile(profile))
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage("프로필을 불러오지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    /// 로그아웃/회원탈퇴처럼 세션을 바꾸는 작업은 동일한 흐름으로 처리
    private func runAccountAction(_ work: @escaping () async throws -> Void) -> Observable<Mutation> {
        Observable.create { observer in
            observer.onNext(.setSubmitting(true))
            
            let task = Task {
                do {
                    try await work()
                    observer.onNext(.setMoveToLogin(true))
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage(error.localizedDescription))
                    observer.onCompleted()
                }
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    private func updateNotificationAllowance(isOn: Bool) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            let task = Task {
                guard let self else { return }
                
                do {
                    try await self.notificationManager.updateIsNotificationEnabled(to: isOn)
                    self.logger.log("✅ Supabase DB에 알림 허용 여부가 성공적으로 저장되었습니다.")
                    
                    observer.onNext(.setPushAlert(isOn))
                    observer.onCompleted()
                } catch {
                    self.logger.error("알림 허용 여부 저장 시 오류 발생: \(error.localizedDescription, privacy: .private)")
                    observer.onNext(.setErrorMessage("알림 허용 여부를 저장하지 못했어요. 잠시 후 다시 시도해주세요."))
                    observer.onCompleted()
                }
            }
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
