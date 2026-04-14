//
//  MyPageViewController.swift
//  LeafLog
//
//  Created by 김주희 on 4/13/26.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import Dependencies

final class MyPageViewController: BaseViewController, View {

    @Dependency(\.supabaseManager) private var supabaseManager
    private let myPageView = MyPageView()
    private var imageLoadTask: Task<Void, Never>?

    override func loadView() {
        view = myPageView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "마이페이지"
        navigationItem.largeTitleDisplayMode = .never
    }

    func bind(reactor: MyPageReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }

    private func bindAction(reactor: MyPageReactor) {
        // 화면이 다시 보일 때마다 최신 프로필을 가져옴
        rx.viewWillAppear
            .map { _ in MyPageReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 수정 버튼 눌렀을때
        myPageView.editProfileButton.rx.tap
            .map { MyPageReactor.Action.editProfileTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 로그아웃
        myPageView.logoutButton.rx.tap
            .map { MyPageReactor.Action.logoutTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 회원 탈퇴
        myPageView.withdrawalButton.rx.tap
            .subscribe(onNext: { [weak self, weak reactor] in
                self?.presentWithdrawalAlert(reactor: reactor)
            })
            .disposed(by: disposeBag)
    }

    private func bindState(reactor: MyPageReactor) {
        // 프로필에 데이터 주입
        reactor.state
            .map(\.profile)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] profile in
                self?.render(profile: profile)
            })
            .disposed(by: disposeBag)

        // 버튼 비활성화
        reactor.state
            .map { $0.isLoading || $0.isSubmitting }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isBusy in
                guard let self else { return }
                self.myPageView.editProfileButton.isEnabled = !isBusy
                self.myPageView.logoutButton.isEnabled = !isBusy
                self.myPageView.withdrawalButton.isEnabled = !isBusy
            })
            .disposed(by: disposeBag)

        // 프로필 수정 화면으로 이동
        reactor.pulse(\.$routeToEdit)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.profileEdit)
            })
            .disposed(by: disposeBag)

        // 로그인 화면으로 이동
        reactor.pulse(\.$moveToLogin)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.loginRequired)
            })
            .disposed(by: disposeBag)

        // 에러 메세지
        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("오류", message))
            })
            .disposed(by: disposeBag)
    }

    private func render(profile: UserProfileModel?) {
        guard let profile else {
            myPageView.nicknameLabel.text = "프로필을 불러오는 중..."
            myPageView.emailLabel.text = nil
            myPageView.profileImageView.image = UIImage(named: "userEmpty") ?? UIImage(systemName: "person.crop.circle.fill")
            return
        }

        myPageView.nicknameLabel.text = profile.nickname
        myPageView.emailLabel.text = profile.email ?? "이메일 정보가 없습니다."
        loadProfileImage(from: profile.profileImageURL)
    }

    // 프로필 사진 불러오기
    private func loadProfileImage(from storedValue: String?) {
        imageLoadTask?.cancel()
        myPageView.profileImageView.image = UIImage(named: "userEmpty") ?? UIImage(systemName: "person.crop.circle.fill")

        imageLoadTask = Task { [weak self] in
            guard let self else { return }

            do {
                guard let resolvedURL = try await self.supabaseManager.resolveProfileImageURL(from: storedValue) else {
                    return
                }

                let (data, _) = try await URLSession.shared.data(from: resolvedURL)
                guard !Task.isCancelled, let image = UIImage(data: data) else { return }

                await MainActor.run {
                    self.myPageView.profileImageView.image = image
                }
            } catch {
                // 이미지 로딩 실패 시 기본 이미지를 그대로 유지
            }
        }
    }

    private func presentWithdrawalAlert(reactor: MyPageReactor?) {
        let alert = UIAlertController(
            title: "회원탈퇴",
            message: "정말 탈퇴하시겠어요?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "탈퇴", style: .destructive) { _ in
            reactor?.action.onNext(.withdrawalTapped)
        })

        present(alert, animated: true)
    }
}
