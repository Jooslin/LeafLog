//
//  KakoAuthProvider.swift
//  LeafLog
//
//  Created by 김주희 on 4/6/26.
//

import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser
import Foundation

final class KakaoAuthProvider {

    // MARK: - Login
    // 카카오 로그인 후 Supabase 교환에 필요한 ID 토큰을 반환
    @MainActor
    func fetchIDToken() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let handler: (OAuthToken?, Error?) -> Void = { oauthToken, error in
                self.handleResult(oauthToken: oauthToken, error: error, continuation: continuation)
            }

            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk(completion: handler)
            } else {
                UserApi.shared.loginWithKakaoAccount(completion: handler)
            }
        }
    }

    // MARK: - Logout
    func signOut() async {
        await withCheckedContinuation { continuation in
            UserApi.shared.logout { _ in
                continuation.resume()
            }
        }
    }

    
    // MARK: - Private
    private func handleResult(
        oauthToken: OAuthToken?,
        error: Error?,
        continuation: CheckedContinuation<String, Error>
    ) {
        if let error {
            if let sdkError = error as? SdkError, sdkError.isClientFailed,
               case .Cancelled = sdkError.getClientError().reason {
                continuation.resume(throwing: AuthError.cancelled)
            } else {
                continuation.resume(throwing: AuthError.loginFailed(error.localizedDescription))
            }
            return
        }

        guard let idToken = oauthToken?.idToken else {
            continuation.resume(throwing: AuthError.loginFailed("ID 토큰이 없습니다. OpenID Connect 활성화 여부를 확인하세요."))
            return
        }

        continuation.resume(returning: idToken)
    }
}
