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

final class AuthService {

    private enum Message {
        static let appleLoginFailed = "Apple 로그인에 실패했어요. 잠시 후 다시 시도해주세요."
        static let appleTokenStoreFailed = "Apple 로그인 정보를 저장하지 못했어요. 잠시 후 다시 시도해주세요."
        static let withdrawalFailed = "회원탈퇴를 처리하지 못했어요. 잠시 후 다시 시도해주세요."
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

        let _: StoreAppleTokenResponse = try await supabase.functions.invoke(
            "store-apple-token",
            options: .init(
                method: .post,
                headers: authorizationHeaders(accessToken: accessToken),
                body: request
            )
        )
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
        let user = try await supabase.auth.user()
        let session = try await supabase.auth.session

        do {
            let _: WithdrawResponse = try await supabase.functions.invoke(
                "delete-user", // DB에서 유저 데이터 삭제
                options: .init(
                    method: .post,
                    headers: authorizationHeaders(accessToken: session.accessToken)
                )
            )
        } catch FunctionsError.httpError {
            throw AuthError.withdrawalFailed(Message.withdrawalFailed)
        } catch {
            throw AuthError.withdrawalFailed(Message.withdrawalFailed)
        }

        // 로그아웃
        try? await supabase.auth.signOut(scope: .local)
        await signOutProvider(for: user)
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
