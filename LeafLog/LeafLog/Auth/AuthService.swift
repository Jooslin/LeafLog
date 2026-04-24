//
//  AuthService.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//  Updated by 김주희 on 4/16/26.
//

import UIKit
import Supabase
import Dependencies
import OSLog

final class AuthService {

    private enum Message {
        static let appleLoginFailed = "Apple 로그인에 실패했어요. 잠시 후 다시 시도해주세요."
        static let appleTokenStoreFailed = "Apple 로그인 정보를 저장하지 못했어요. 잠시 후 다시 시도해주세요."
        static let withdrawalFailed = "회원탈퇴를 처리하지 못했어요. 잠시 후 다시 시도해주세요."
    }

    private enum AppleLoginCooldown {
        static let userDefaultsKey = "appleLoginCooldownExpiresAt"
        static let duration: TimeInterval = 9 // 재가입 제한 시간
    }

    private struct WithdrawResponse: Decodable {
        let success: Bool
    }

    // Apple 토큰 저장 함수에 전달할 요청 모델
    private struct StoreAppleTokenRequest: Encodable {
        let authorizationCode: String
        let userIdentifier: String
    }

    // Edge Function의 응답
    private struct StoreAppleTokenResponse: Decodable {
        let success: Bool
    }
    
    @Dependency(\.profileDBManager) private var profileDBManager

    // MARK: - Properties
    @Dependency(\.supabaseManager) private var supabaseManager
    private lazy var supabase = supabaseManager.client
    private let logger = Logger(subsystem: "LeafLog", category: "AuthService") // 탈퇴 실패했을 때 콘솔에 로그 추가

    private let appleProvider: AppleAuthProvider
    private let googleProvider: GoogleAuthProvider
    private let kakaoProvider: KakaoAuthProvider
    private let kakaoTokenExchanger: any KakaoTokenExchanging

    // 세션 여부 확인
    func resolveInitialStep() async -> AppStep {
        do {
            _ = try await supabase.auth.session
            return .main
        } catch {
            return .loginRequired
        }
    }

    // MARK: - Initialization
    init(
        appleProvider: AppleAuthProvider = AppleAuthProvider(),
        googleProvider: GoogleAuthProvider = GoogleAuthProvider(),
        kakaoProvider: KakaoAuthProvider = KakaoAuthProvider(),
        kakaoTokenExchanger: any KakaoTokenExchanging = KakaoSupabaseTokenExchanger(
            supabaseURL: AppSecrets.supabaseURL,
            anonKey: AppSecrets.supabaseAnonKey
        ),
    ) {
        self.appleProvider = appleProvider
        self.googleProvider = googleProvider
        self.kakaoProvider = kakaoProvider
        self.kakaoTokenExchanger = kakaoTokenExchanger
    }

    
    // MARK: - Apple Login
    func startAppleNativeLogin(presentingViewController: UIViewController) async throws -> Supabase.User {
        let credential = try await appleProvider.fetchCredential(presentingViewController: presentingViewController)

        do {
            try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: credential.idToken, nonce: credential.rawNonce)
            )
        } catch {
            throw AuthError.sessionFailed(Message.appleLoginFailed)
        }

        let session = try await supabase.auth.session
        
        do {
            try await storeAppleToken(credential: credential, accessToken: session.accessToken)
        } catch FunctionsError.httpError {
            await signOutLocalSession()
            throw AuthError.sessionFailed(Message.appleTokenStoreFailed)
        } catch {
            await signOutLocalSession()
            throw AuthError.sessionFailed(Message.appleTokenStoreFailed)
        }

        let user = try await supabase.auth.user()
        try await ensureProfileExists(for: user)
        return user
    }

    private func storeAppleToken(
        credential: AppleAuthProvider.AppleCredential,
        accessToken: String
    ) async throws {
        let request = StoreAppleTokenRequest(
            authorizationCode: credential.authorizationCode,
            userIdentifier: credential.userIdentifier
        )

        let response: StoreAppleTokenResponse = try await supabase.functions.invoke(
            "store-apple-token",
            options: .init(
                method: .post,
                headers: authorizationHeaders(accessToken: accessToken),
                body: request
            )
        )

        guard response.success else {
            throw AuthError.sessionFailed(Message.appleTokenStoreFailed)
        }
    }

    
    // MARK: - Google Login
    func startGoogleNativeLogin(presentingViewController: UIViewController) async throws -> Supabase.User {
        let credential = try await googleProvider.fetchCredential(presentingViewController: presentingViewController)

        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: credential.idToken, nonce: credential.rawNonce)
        )

        let user = try await supabase.auth.user()
        try await ensureProfileExists(for: user)
        return user
    }

    
    // MARK: - Kakao Login
    func startKakaoNativeLogin() async throws -> Supabase.User {
        let idToken = try await kakaoProvider.fetchIDToken()
        return try await exchangeKakaoTokenWithSupabase(idToken: idToken)
    }

    
    // MARK: - Exchange Kakao Token With Supabase
    private func exchangeKakaoTokenWithSupabase(idToken: String) async throws -> Supabase.User {
        let tokens = try await kakaoTokenExchanger.exchange(idToken: idToken)
        try await supabase.auth.setSession(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
        let user = try await supabase.auth.user()
        try await ensureProfileExists(for: user)
        return user
    }

    
    // MARK: - 로그인 성공 후 profiles 테이블에 사용자 프로필 row가 존재하도록 보장
    private func ensureProfileExists(for user: Supabase.User) async throws {
        do {
            _ = try await profileDBManager.createProfileIfNeeded()
        } catch let error as AuthError {
            await rollbackSession(for: user)
            throw error
        } catch {
            await rollbackSession(for: user)
            throw AuthError.profileFailed("사용자 프로필을 저장하지 못했어요. 잠시 후 다시 시도해주세요.")
        }
    }

    private func rollbackSession(for user: Supabase.User) async {
        await signOutProvider(for: user)
        try? await supabase.auth.signOut()
    }
    
    
    // MARK: - Sign Out
    func signOut() async throws {
        let user = try await supabase.auth.user()
        try await supabase.auth.signOut()
        await signOutProvider(for: user)
    }

    // MARK: - 회원 탈퇴
    func withdrawAccount() async throws {
        let cachedUser = supabase.auth.currentUser // 앱에 저장되어있는 마지막 유저 정보
        let context: (user: Supabase.User, accessToken: String)

        do {
            // 탈퇴 시작 전에 유저, 세션 가져오기
            let user = try await supabase.auth.user()
            let session = try await supabase.auth.session
            context = (user: user, accessToken: session.accessToken)
        } catch {
            // 실패하면 로그아웃
            await completeLocalWithdrawal(for: cachedUser)
            return
        }

        do {
            let response: WithdrawResponse = try await supabase.functions.invoke(
                "delete-user", // DB에서 유저 데이터 삭제
                options: .init(
                    method: .post,
                    headers: authorizationHeaders(accessToken: context.accessToken)
                )
            )

            guard response.success else {
                throw AuthError.withdrawalFailed(Message.withdrawalFailed)
            }
        } catch FunctionsError.httpError(let code, let data) {
            // 에러가 발생해도 탈퇴된 상태면 로컬 로그아웃
            if await shouldCompleteWithdrawalAfterFailure(code: code, data: data, accessToken: context.accessToken) {
                await completeLocalWithdrawal(for: context.user)
                return
            }

            // 탈퇴된 상태가 아니면 에러 로그 + 팝업
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            logger.error("회원탈퇴 Edge Function 실패 - status: \(code, privacy: .public), body: \(responseBody, privacy: .public)")
            throw AuthError.withdrawalFailed(Message.withdrawalFailed)
        } catch {
            // 탈퇴 됐는지 확인
            if await isRemoteAccountDeleted(accessToken: context.accessToken) {
                await completeLocalWithdrawal(for: context.user)
                return
            }

            logger.error("회원탈퇴 실패 - \(error.localizedDescription, privacy: .public)")
            throw AuthError.withdrawalFailed(Message.withdrawalFailed)
        }

        // 정상 성공 처리
        await completeLocalWithdrawal(for: context.user)
    }

    // 대기 시간이 남아있는지 확인
    func isAppleLoginCooldownActive() -> Bool {
        let expiresAt = UserDefaults.standard.double(forKey: AppleLoginCooldown.userDefaultsKey) // 기다림이 끝나는 시간
        // 시간이 지났으면 쿨다운 종료
        guard expiresAt > Date().timeIntervalSince1970 else {
            // 저장된 시간 기록 삭제
            UserDefaults.standard.removeObject(forKey: AppleLoginCooldown.userDefaultsKey)
            return false
        }

        return true
    }

    // 앱 안에있는 로그인 흔적 지우기
    private func completeLocalWithdrawal(for user: Supabase.User?) async {
        if isAppleUser(user) {
            startAppleLoginCooldown()
        }

        try? await supabase.auth.signOut(scope: .local)
        if let user {
            await signOutProvider(for: user)
        }
    }

    // 대기 시간 타이머 작동
    private func startAppleLoginCooldown() {
        let expiresAt = Date().addingTimeInterval(AppleLoginCooldown.duration).timeIntervalSince1970
        UserDefaults.standard.set(expiresAt, forKey: AppleLoginCooldown.userDefaultsKey)
    }

    // 애플 유저인지 확인
    private func isAppleUser(_ user: Supabase.User?) -> Bool {
        user?.appMetadata["provider"]?.stringValue == "apple"
    }

    // 실패 응답을 받아도 회원탈퇴 되었는지 판단
    private func shouldCompleteWithdrawalAfterFailure(code: Int, data: Data, accessToken: String) async -> Bool {
        // 응답 메시지가 이미 탈퇴, 세션 없음인지
        if isAlreadyWithdrawnResponse(code: code, data: data) {
            return true
        }

        // 슈파베이스 Auth 유저가 이미 삭제 되었는지
        if await isRemoteAccountDeleted(accessToken: accessToken) {
            return true
        }

        // profile row가 이미 삭제 되었는지
        return await isProfileAlreadyDeleted()
    }

    // access 토큰으로 유저 정보 가져올수있는지
    private func isRemoteAccountDeleted(accessToken: String) async -> Bool {
        do {
            _ = try await supabase.auth.user(jwt: accessToken)
            return false
        } catch {
            return true
        }
    }

    // 프로필 row가 이미 삭제되었는지
    private func isProfileAlreadyDeleted() async -> Bool {
        do {
            let profile = try await profileDBManager.fetchMyProfile()
            return profile == nil
        } catch {
            return false
        }
    }

    // 탈퇴 상태인지 확인
    private func isAlreadyWithdrawnResponse(code: Int, data: Data) -> Bool {
        guard [401, 403, 404, 500].contains(code) else {
            return false
        }

        let message = String(data: data, encoding: .utf8)?.lowercased() ?? ""
        return message.contains("unauthorized")
            || message.contains("not found")
            || message.contains("session")
            || message.contains("user")
    }

    private func authorizationHeaders(accessToken: String) -> [String: String] {
        ["Authorization": "Bearer \(accessToken)"]
    }

    private func signOutLocalSession() async {
        try? await supabase.auth.signOut(scope: .local)
    }

    
    private func signOutProvider(for user: Supabase.User) async {
        switch user.appMetadata["provider"]?.stringValue {
        case "google":
            googleProvider.signOut()
        case "kakao":
            await kakaoProvider.signOut()
        default:
            break
        }
    }
}

//MARK: Dependencies
extension AuthService: DependencyKey {
    static var liveValue: AuthService {
        AuthService()
    }
}

extension DependencyValues {
    var authService: AuthService {
        get { self[AuthService.self] }
        set { self[AuthService.self] = newValue }
    }
}
