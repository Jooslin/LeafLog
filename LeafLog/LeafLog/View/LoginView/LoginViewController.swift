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
import SafariServices

class LoginViewController: BaseViewController, View {
    
    private let loginView = LoginView()
    private let privacyPolicyURLString = "https://leaflog.notion.site/LeafLog-34c4589f9d0f803eb977fb600be7bf94"
    private let termsURLString = "https://leaflog.notion.site/LeafLog-34c4589f9d0f80b59f9fcc02fd11ca78?source=copy_link"
    
    
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
        Observable.just(LoginReactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        loginView.appleLoginButton.rx.controlEvent(.touchUpInside)
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

        loginView.termsButton.rx.tap
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.presentWebPage(urlString: self?.termsURLString)
            })
            .disposed(by: disposeBag)

        loginView.privacyPolicyButton.rx.tap
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.presentWebPage(urlString: self?.privacyPolicyURLString)
            })
            .disposed(by: disposeBag)
    }
    
    
    private func bindState(reactor: LoginReactor) {
        let state = reactor.state.asDriver(onErrorJustReturn: LoginReactor.State())
        
        state
            .map { !$0.isLoading }
            .distinctUntilChanged()
            .drive(onNext: { [weak self] isEnabled in
                self?.loginView.googleLoginButton.isEnabled = isEnabled
                self?.loginView.kakaoLoginButton.isEnabled = isEnabled
            })
            .disposed(by: disposeBag)

        state
            .map { $0.isLoading == false && $0.isAppleLoginBlocked == false }
            .distinctUntilChanged()
            .drive(loginView.appleLoginButton.rx.isEnabled)
            .disposed(by: disposeBag)

        state
            .map(\.isAppleLoginBlocked)
            .distinctUntilChanged()
            .drive(onNext: { [weak self] isBlocked in
                self?.loginView.setAppleLoginCooldownVisible(isBlocked)
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
                self?.steps.accept(AppStep.alert("에러", message))
            })
            .disposed(by: disposeBag)
    }

    private func presentWebPage(urlString: String?) {
        guard let urlString,
              let url = URL(string: urlString) else {
            steps.accept(AppStep.alert("오류", "페이지 주소를 열 수 없습니다."))
            return
        }

        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true)
    }
}
