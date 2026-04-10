//
//  AuthService.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import Supabase
import Dependencies

final class AuthService {
    
    @Dependency(\.profileDBManager) private var profileDBManager
    
    // MARK: - Properties
    let supabase = SupabaseManager.shared.client

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
            return .login
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
        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: credential.idToken, nonce: credential.rawNonce)
        )
        return try await supabase.auth.user()
    }

    
    // MARK: - Google Login
    func startGoogleNativeLogin(presentingViewController: UIViewController) async throws -> Supabase.User {
        let credential = try await googleProvider.fetchCredential(presentingViewController: presentingViewController)
        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: credential.idToken, nonce: credential.rawNonce)
        )
        let user = try await supabase.auth.user()
        try await ensureProfileExists()
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
        try await ensureProfileExists()
        return user
    }

    
    // MARK: - 로그인 성공 후 profiles 테이블에 사용자 프로필 row가 존재하도록 보장
    private func ensureProfileExists() async throws {
        do {
            _ = try await profileDBManager.createProfileIfNeeded()
        } catch let error as AuthError {
            await rollbackSession()
            throw error
        } catch {
            await rollbackSession()
            throw AuthError.profileFailed("사용자 프로필을 저장하지 못했어요. 잠시 후 다시 시도해주세요.")
        }
    }

    private func rollbackSession() async {
        try? await supabase.auth.signOut()
        googleProvider.signOut()
    }
    
    
    // MARK: - Sign Out
    func signOut() async throws {
        try await supabase.auth.signOut()
        googleProvider.signOut()
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
