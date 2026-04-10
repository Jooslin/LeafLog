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
    static let shared = AuthService()

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
        )
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
        return try await supabase.auth.user()
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
        return try await supabase.auth.user()
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
