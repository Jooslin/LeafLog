//
//  ProfileEditViewController.swift
//  LeafLog
//
//  Created by 김주희 on 4/13/26.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import PhotosUI
import Dependencies

final class ProfileEditViewController: BaseViewController, View {

    @Dependency(\.supabaseManager) private var supabaseManager
    private let profileEditView = ProfileEditView()
    private var imageLoadTask: Task<Void, Never>?

    var profileImagePickerSourceView: UIView {
        profileEditView.profileImageButton
    }

    var hasProfileImage: Bool {
        reactor?.currentState.selectedImage != nil
        || reactor?.currentState.profile?.profileImageURL?.isEmpty == false
    }

    func deleteProfileImage() {
        reactor?.action.onNext(.deleteImage)
    }
    
    override func loadView() {
        view = profileEditView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboardDismissGesture()
    }


    func bind(reactor: ProfileEditReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    

    private func bindAction(reactor: ProfileEditReactor) {
        rx.viewWillAppear
            .map { _ in ProfileEditReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        profileEditView.nameTextField.rx.text.orEmpty
            .skip(1)
            .map(ProfileEditReactor.Action.updateNickname)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        profileEditView.profileImageButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.steps.accept(AppStep.profileImageSourceSheet)
            })
            .disposed(by: disposeBag)

        profileEditView.saveButton.rx.tap
            .map { ProfileEditReactor.Action.saveTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        profileEditView.profileEditHeaderView.backButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func bindState(reactor: ProfileEditReactor) {
        reactor.state
            .map(\.profile)
            .distinctUntilChanged(Self.isSameRenderedProfile)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] profile in
                self?.renderProfile(profile)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.nickname)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] nickname in
                guard let self, self.profileEditView.nameTextField.text != nickname else { return }
                self.profileEditView.nameTextField.text = nickname
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.selectedImage)
            .distinctUntilChanged { lhs, rhs in
                switch (lhs, rhs) {
                    // 둘다 nil일때
                case (nil, nil):
                    return true
                    // 둘이 같을때
                case let (lhs?, rhs?):
                    return lhs === rhs
                    // 그 외
                default:
                    return false
                }
            }
            .skip(1)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] image in
                self?.imageLoadTask?.cancel()
                self?.applyProfileImage(image)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading || $0.isSaving }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isBusy in
                self?.setControlsEnabled(!isBusy)
            })
            .disposed(by: disposeBag)

        reactor.pulse(\.$saveCompleted)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("오류", message))
            })
            .disposed(by: disposeBag)
    }

    private func renderProfile(_ profile: UserProfileModel?) {
        guard let profile else { return }

        let providerName = providerDisplayName(from: profile.provider)
        profileEditView.providerValueLabel.text = providerName
        profileEditView.providerDescriptionLabel.text = profile.email ?? "\(providerName)로 로그인됨"
        profileEditView.providerIconImageView.image = providerIcon(from: profile.provider)
        loadProfileImage(
            from: profile.profileImageURL,
            updatedAt: profile.updatedAt
        )
    }

    private func loadProfileImage(from storedValue: String?, updatedAt: Date?) {
        imageLoadTask?.cancel()

        let normalizedValue = storedValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let cacheKey = makeImageCacheKey(
            from: normalizedValue,
            updatedAt: updatedAt
        )
        
        guard let normalizedValue, !normalizedValue.isEmpty else {
            profileEditView.setProfileImageURL(nil, cacheKey: nil)
            return
        }

        imageLoadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let resolvedURL = try await self.supabaseManager.resolveProfileImageURL(from: normalizedValue)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.profileEditView.setProfileImageURL(
                        resolvedURL,
                        cacheKey: cacheKey
                    )
                }
            } catch {
                // 실패 시 기본 이미지를 유지한다.
            }
        }
    }

    private func applyProfileImage(_ image: UIImage?) {
        profileEditView.setProfileImage(image)
    }

    private func makeImageCacheKey(from path: String?, updatedAt: Date?) -> String? {
        guard let path, !path.isEmpty else {
            return nil
        }

        guard let updatedAt else {
            return path
        }

        return "\(path)?updatedAt=\(updatedAt.timeIntervalSince1970)"
    }

    nonisolated private static func isSameRenderedProfile(_ lhs: UserProfileModel?, _ rhs: UserProfileModel?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true

        case let (lhs?, rhs?):
            return lhs.id == rhs.id
            && lhs.profileImageURL == rhs.profileImageURL
            && lhs.updatedAt == rhs.updatedAt
            && lhs.email == rhs.email
            && lhs.provider == rhs.provider

        default:
            return false
        }
    }

    private func setControlsEnabled(_ isEnabled: Bool) {
        profileEditView.nameTextField.isEnabled = isEnabled
        profileEditView.profileImageButton.isEnabled = isEnabled
        profileEditView.saveButton.isEnabled = isEnabled
        profileEditView.saveButton.alpha = isEnabled ? 1.0 : 0.6
    }

    private func providerDisplayName(from provider: String) -> String {
        switch provider.lowercased() {
        case let value where value.contains("kakao"):
            return "Kakao"
        case let value where value.contains("google"):
            return "Google"
        case let value where value.contains("apple"):
            return "Apple"
        default:
            return provider
        }
    }

    private func providerIcon(from provider: String) -> UIImage? {
        switch provider.lowercased() {
        case let value where value.contains("kakao"):
            return .kakao
        case let value where value.contains("google"):
            return .google
        case let value where value.contains("apple"):
            return UIImage(systemName: "apple.logo")?.withTintColor(.black, renderingMode: .alwaysOriginal)
        default:
            return .sprout
        }
    }
}

extension ProfileEditViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard
            let result = results.first,
            let reactor,
            result.itemProvider.canLoadObject(ofClass: UIImage.self)
        else {
            return
        }

        result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
            guard let image = image as? UIImage else { return }

            DispatchQueue.main.async {
                reactor.action.onNext(.updateImage(image))
            }
        }
    }
}

extension ProfileEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)

        guard
            let image = info[.originalImage] as? UIImage,
            let reactor
        else {
            return
        }

        reactor.action.onNext(.updateImage(image))
    }
}
