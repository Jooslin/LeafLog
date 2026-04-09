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

final class SplashViewController: BaseViewController {

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
            let nextStep = await AuthService.shared.resolveInitialStep()

            await MainActor.run {
                self.steps.accept(nextStep)
            }
        }
    }
}
