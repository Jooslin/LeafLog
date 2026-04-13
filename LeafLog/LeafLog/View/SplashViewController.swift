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
    
    private let logoImageView = UIImageView(image: UIImage(named: "launch_logo"))

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 중복 검사 방지
        guard didStartSessionCheck == false else { return }
        didStartSessionCheck = true
        validateSession()
    }

    private func setupUI() {
        view.addSubview(logoImageView)
        
        logoImageView.snp.makeConstraints {
            $0.width.equalTo(248)
            $0.height.equalTo(183)
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-70)
        }
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
