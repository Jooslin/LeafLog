//
//  GoogleAuthProvider.swift
//  LeafLog
//
//  Created by 김주희 on 4/6/26.
//

import UIKit
import GoogleSignIn

final class GoogleAuthProvider {

    // MARK: - Types
    struct GoogleCredential {
        let idToken: String
        let rawNonce: String
    }

    
    // MARK: - Login
    // Google 로그인 UI를 띄우고, Supabase에 넘길 credential을 반환
    @MainActor
    func fetchCredential(presentingViewController: UIViewController) async throws -> GoogleCredential {
        let rawNonce = NonceGenerator.randomNonceString()
        let hashedNonce = NonceGenerator.sha256(rawNonce)
        let hint = GIDSignIn.sharedInstance.currentUser?.profile?.email

        return try await withCheckedThrowingContinuation { continuation in
            // 구글 서버에 로그인 요청하기
            GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingViewController,
                hint: hint,
                additionalScopes: nil,
                nonce: hashedNonce
            ) { result, error in
                // error가 발생한 경우
                if let error {
                    let authError: AuthError = error.localizedDescription.contains("cancel")
                        ? .cancelled
                        : .loginFailed(error.localizedDescription)
                    continuation.resume(throwing: authError)
                    return
                }

                // 토큰 꺼내기
                guard let idToken = result?.user.idToken?.tokenString else {
                    continuation.resume(throwing: AuthError.loginFailed("Google ID Token을 가져올 수 없습니다."))
                    return
                }

                // 성공 반환
                continuation.resume(returning: GoogleCredential(idToken: idToken, rawNonce: rawNonce))
            }
        }
    }

    
    // MARK: - Logout
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}
