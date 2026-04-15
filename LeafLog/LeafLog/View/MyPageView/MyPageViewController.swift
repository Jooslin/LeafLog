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
import MessageUI

final class MyPageViewController: BaseViewController, View {

    @Dependency(\.supabaseManager) private var supabaseManager
    private let myPageView = MyPageView()
    private var imageLoadTask: Task<Void, Never>?

    override func loadView() {
        view = myPageView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
            .subscribe(onNext: { [weak self, weak reactor] in
                self?.UserSettingAlert(reactor: reactor, title: "로그아웃", message: "로그아웃 하시겠습니까?", okMessage: "로그아웃", action: .logoutTapped)
            })
            .disposed(by: disposeBag)

        // 회원 탈퇴
        myPageView.withdrawalButton.rx.tap
            .subscribe(onNext: { [weak self, weak reactor] in
                self?.UserSettingAlert(reactor: reactor, title: "회원 탈퇴", message: "정말 탈퇴 하시겠습니까?", okMessage: "탈퇴", action: .withdrawalTapped)
            })
            .disposed(by: disposeBag)
        
        // 문의하기 버튼
        myPageView.inquiryButton.rx.tap
            .map { MyPageReactor.Action.inquiryTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // 오류 신고 버튼
        myPageView.reportErrorButton.rx.tap
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.presentMailComposeViewController(isError: true)
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
        
        reactor.pulse(\.$routeToMail)
                    .compactMap { $0 }
                    .observe(on: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] isError in
                        self?.presentMailComposeViewController(isError: isError)
                    })
                    .disposed(by: disposeBag)
    }

    private func render(profile: UserProfileModel?) {
        guard let profile else {
            return
        }

        myPageView.nicknameLabel.text = profile.nickname
        myPageView.emailLabel.text = profile.email ?? "이메일 정보가 없습니다."
        loadProfileImage(from: profile.profileImageURL)
    }

    // 프로필 사진 불러오기
    private func loadProfileImage(from storedValue: String?) {
        imageLoadTask?.cancel()

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

    private func userSettingAlert(reactor: MyPageReactor?, title: String, message: String, okMessage: String, action: MyPageReactor.Action) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: okMessage, style: .destructive) { _ in
            reactor?.action.onNext(action)
        })

        present(alert, animated: true)
    }
}


// MARK: - Mail Compose
extension MyPageViewController: MFMailComposeViewControllerDelegate {
    
    // 메일 작성 화면 띄우기
    private func presentMailComposeViewController(isError: Bool) {
        // 기기에 메일 계정이 설정되어 있는지 확인
        guard MFMailComposeViewController.canSendMail() else {
            // 메일 앱을 사용할 수 없을 때 알림
            self.steps.accept(AppStep.alert("메일 설정 오류", "기본 메일 앱이 설정되어 있지 않습니다. leaflogapp@gmail.com으로 직접 문의해 주세요."))
            return
        }
        
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        
        // 받는 사람 지정
        mailVC.setToRecipients(["leaflogapp@gmail.com"])
        
        // 문의/오류신고에 따라 제목과 본문 양식 다르게 지정
        if isError {
            mailVC.setSubject("[LeafLog] 오류 신고")
            mailVC.setMessageBody("발생한 오류에 대해 적어주세요.\n\n- 발생 일시:\n- 오류 내용:\n", isHTML: false)
        } else {
            mailVC.setSubject("[LeafLog] 서비스 문의")
            mailVC.setMessageBody("문의하실 내용을 적어주세요.\n\n", isHTML: false)
        }
        
        present(mailVC, animated: true)
    }
    
    // 메일 작성 화면에서 '취소' 또는 '보내기'를 눌렀을 때 화면을 닫아주는 델리게이트 메서드
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
