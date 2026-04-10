//
//  SplashViewController.swift
//  LeafLog
//
//  Created by 김주희 on 4/8/26.
//

import SnapKit
import Then
import UIKit
import RxRelay
import Dependencies

final class SplashViewController: BaseViewController {

    @Dependency(\.authService) private var authService
    
    private var didStartSessionCheck = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 중복 검사 방지
        guard didStartSessionCheck == false else { return }
        didStartSessionCheck = true
        validateSession()
    }

    // 로그인 세션 확인
    private func validateSession() {
        Task {
            let nextStep = await authService.resolveInitialStep()

            await MainActor.run {
                self.steps.accept(nextStep)
            }
        }
    }
}
