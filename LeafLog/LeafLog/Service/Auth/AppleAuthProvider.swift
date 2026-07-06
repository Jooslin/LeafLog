//
//  appleAuthProvider.swift
//  LeafLog
//
//  Created by 김주희 on 4/8/26.
//


import UIKit
import AuthenticationServices

final class AppleAuthProvider {

    // MARK: - Types
    // 서버에 넘겨줄 데이터 바구니
    struct AppleCredential {
        let idToken: String
        let authorizationCode: String
        let userIdentifier: String
        let rawNonce: String
        let email: String? // 이메일, 이름은 최초 로그인 시에만 제공
        let fullName: PersonNameComponents?
    }

    private var currentCoordinator: AppleSignInCoordinator?


    // MARK: - Login
    // Apple 로그인 UI를 띄우고, Supabase에 넘길 credential을 반환
    @MainActor
    func fetchCredential(presentingViewController: UIViewController) async throws -> AppleCredential {
        guard let presentationAnchor = presentingViewController.view.window else {
            throw AuthError.loginFailed("Apple 로그인 창을 표시할 수 없습니다.")
        }

        let rawNonce = NonceGenerator.randomNonceString()
        let hashedNonce = NonceGenerator.sha256(rawNonce)

        // delegate 패턴(call back)을 async/await으로 변환
        return try await withCheckedThrowingContinuation { continuation in
            let coordinator = AppleSignInCoordinator(
                presentationAnchor: presentationAnchor,
                rawNonce: rawNonce,
                hashedNonce: hashedNonce
            ) { [weak self] result in
                self?.currentCoordinator = nil // 메모리 해제
                continuation.resume(with: result) // 결과 반환
            }

            currentCoordinator = coordinator
            coordinator.start() // 로그인 창 띄우기
        }
    }
}

private final class AppleSignInCoordinator: NSObject {
    typealias Completion = (Result<AppleAuthProvider.AppleCredential, Error>) -> Void

    private let presentationAnchor: ASPresentationAnchor
    private let rawNonce: String
    private let hashedNonce: String
    private let completion: Completion

    private var authorizationController: ASAuthorizationController?
    private var isFinished = false

    init(
        presentationAnchor: ASPresentationAnchor,
        rawNonce: String,
        hashedNonce: String,
        completion: @escaping Completion
    ) {
        self.presentationAnchor = presentationAnchor
        self.rawNonce = rawNonce
        self.hashedNonce = hashedNonce
        self.completion = completion
    }

    func start() {
        // Apple ID로 로그인 하겠다는 request 생성
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        
        // 이름, 이메일 요청
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        // request를 들고 실제 로그인 창 띄워줄 controller 생성
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        authorizationController = controller
        controller.performRequests() // 애플 로그인 창 띄우기
    }

    private func finish(with result: Result<AppleAuthProvider.AppleCredential, Error>) {
        guard isFinished == false else { return } // 중복 호출 방지
        isFinished = true
        authorizationController = nil //메모리 해제
        completion(result)
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    // 성공했을 때
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(with: .failure(AuthError.loginFailed("Apple 자격 증명을 가져올 수 없습니다.")))
            return
        }

        guard let identityToken = appleIDCredential.identityToken,
              let idToken = String(data: identityToken, encoding: .utf8),
              let authorizationCodeData = appleIDCredential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8)
        else {
            finish(with: .failure(AuthError.loginFailed("Apple 인증 정보를 가져올 수 없습니다.")))
            return
        }
        
        let userIdentifier = appleIDCredential.user

        finish(with: .success(
            AppleAuthProvider.AppleCredential(
                idToken: idToken,
                authorizationCode: authorizationCode,
                userIdentifier: userIdentifier,
                rawNonce: rawNonce,
                email: appleIDCredential.email,
                fullName: appleIDCredential.fullName
            )
        ))
    }

    func authorizationController(
        // 실패했을 때
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let nsError = error as NSError
        let isUserStoppedLogin = [
            ASAuthorizationError.Code.canceled.rawValue,
            ASAuthorizationError.Code.unknown.rawValue
        ].contains(nsError.code)

        if nsError.domain == ASAuthorizationError.errorDomain,
           isUserStoppedLogin {
            finish(with: .failure(AuthError.cancelled))
            return
        }

        finish(with: .failure(AuthError.loginFailed(error.localizedDescription)))
    }
}

// 로그인창 Anchor 지정
extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presentationAnchor
    }
}
