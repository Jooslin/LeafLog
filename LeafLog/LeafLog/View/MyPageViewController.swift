//
//  MyPageViewController.swift
//  LeafLog
//
//  Created by 김주희 on 4/4/26.
//

import UIKit
import SnapKit
import Then
import Supabase
import RxRelay
import Dependencies

class MyPageViewController: BaseViewController {
    
    @Dependency(\.authService) private var authService
    
    private lazy var signOutButton = UIButton().then {
        $0.setTitle("로그아웃", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 8
        $0.titleLabel?.font = .boldSystemFont(ofSize: 16)
        $0.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(signOutButton)
        signOutButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(50)
        }
    }
    
    // MARK: - Actions
    @objc private func logoutButtonTapped() {
        Task {
            do {
                try await authService.signOut()
                await MainActor.run {
                    self.steps.accept(AppStep.login)
                }
            } catch {
                await MainActor.run {
                    self.steps.accept(AppStep.alert("로그아웃 실패", "잠시 후 다시 시도해주세요."))
                }
            }
        }
    }
}
