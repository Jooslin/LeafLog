//
//  LoginViewController.swift
//  LeafLog
//
//  Created by 김주희 on 4/3/26.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

class LoginViewController: BaseViewController, View {
    
    private let loginView = LoginView()
    
    
    // MARK: - Lifecycle
    override func loadView() {
        view = loginView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
    
    
    // MARK: - Bind
    func bind(reactor: LoginReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    
    private func bindAction(reactor: LoginReactor) {
        loginView.appleLoginButton.rx.tap
            .compactMap { [weak self] in
                guard let self else { return nil }
                return LoginReactor.Action.appleLoginTapped(self)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        loginView.googleLoginButton.rx.tap
            .compactMap { [weak self] in
                guard let self else { return nil }
                return LoginReactor.Action.googleLoginTapped(self)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        loginView.kakaoLoginButton.rx.tap
            .map { LoginReactor.Action.kakaoLoginTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    
    private func bindState(reactor: LoginReactor) {
        let state = reactor.state.asDriver(onErrorJustReturn: LoginReactor.State())
        
        state
            .map { !$0.isLoading }
            .distinctUntilChanged()
            .drive(onNext: { [weak self] isEnabled in
                self?.loginView.appleLoginButton.isEnabled = isEnabled
                self?.loginView.googleLoginButton.isEnabled = isEnabled
                self?.loginView.kakaoLoginButton.isEnabled = isEnabled
            })
            .disposed(by: disposeBag)

        
        reactor.pulse(\.$loginSuccess)
            .filter { $0 == true }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.main)
            })
            .disposed(by: disposeBag)

        
        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] message in
                self?.showAlert(message: message)
            })
            .disposed(by: disposeBag)
    }
}
