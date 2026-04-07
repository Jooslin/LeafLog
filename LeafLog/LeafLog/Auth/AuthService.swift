//
//  AuthService.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import Supabase

final class AuthService {
    static let shared = AuthService()

    
    // MARK: - Properties
    let supabase = SupabaseManager.shared.client

    private let googleProvider = GoogleAuthProvider()
    private let kakaoProvider = KakaoAuthProvider()

    @MainActor
    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .keyWindow?
            .rootViewController
    }

    
    // MARK: - Initialization
    private init() {}

    
    // MARK: - Google Login
    func startGoogleNativeLogin() async throws -> Supabase.User {
        guard let rootVC = rootViewController else {
            throw AuthError.loginFailed("rootViewController를 찾을 수 없습니다.")
        }
        let credential = try await googleProvider.fetchCredential(presentingViewController: rootVC)
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
        let exchanger = KakaoSupabaseTokenExchanger(
            supabaseURL: AppSecrets.supabaseURL,
            anonKey: AppSecrets.supabaseAnonKey
        )
        let tokens = try await exchanger.exchange(idToken: idToken)
        try await supabase.auth.setSession(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
        return try await supabase.auth.user()
    }
    
    
    // MARK: - Sign Out
    func signOut() async throws {
        try await supabase.auth.signOut()
        googleProvider.signOut()
    }
}
