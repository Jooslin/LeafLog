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

    override func loadView() {
        view = profileEditView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "정보 수정"
        navigationItem.largeTitleDisplayMode = .never
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

        profileEditView.nicknameTextField.rx.text.orEmpty
            .skip(1)
            .map(ProfileEditReactor.Action.updateNickname)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        Observable.merge(
            profileEditView.imageButton.rx.tap.asObservable(),
            profileEditView.cameraButton.rx.tap.asObservable()
        )
        .subscribe(onNext: { [weak self] in
            self?.presentImageActionSheet()
        })
        .disposed(by: disposeBag)

        profileEditView.saveButton.rx.tap
            .map { ProfileEditReactor.Action.saveTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }

    private func bindState(reactor: ProfileEditReactor) {
        reactor.state
            .map(\.profile)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] profile in
                self?.renderProfile(profile)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.nickname)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] nickname in
                guard let self, self.profileEditView.nicknameTextField.text != nickname else { return }
                self.profileEditView.nicknameTextField.text = nickname
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.selectedImage)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] image in
                guard let image else { return }
                self?.imageLoadTask?.cancel()
                self?.profileEditView.profileImageView.image = image
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading || $0.isSaving }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isBusy in
                guard let self else { return }
                self.profileEditView.nicknameTextField.isEnabled = !isBusy
                self.profileEditView.imageButton.isEnabled = !isBusy
                self.profileEditView.cameraButton.isEnabled = !isBusy
                self.profileEditView.saveButton.isEnabled = !isBusy
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

        profileEditView.providerValueLabel.text = profile.provider
        profileEditView.emailValueLabel.text = profile.email ?? "이메일 정보가 없습니다."
        loadProfileImage(from: profile.profileImageURL)
    }

    private func loadProfileImage(from storedValue: String?) {
        imageLoadTask?.cancel()

        profileEditView.profileImageView.image = UIImage(named: "userEmpty") ?? UIImage(systemName: "person.crop.circle.fill")

        imageLoadTask = Task { [weak self] in
            guard let self else { return }

            do {
                guard let resolvedURL = try await self.supabaseManager.resolveProfileImageURL(from: storedValue) else {
                    return
                }

                let (data, _) = try await URLSession.shared.data(from: resolvedURL)
                guard !Task.isCancelled, let image = UIImage(data: data) else { return }

                await MainActor.run {
                    self.profileEditView.profileImageView.image = image
                }
            } catch {
                // 실패 시 기본 이미지를 유지한다.
            }
        }
    }

    private func presentImageActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
                self?.presentCameraPicker()
            })
        }

        alertController.addAction(UIAlertAction(title: "앨범", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })

        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = profileEditView.cameraButton
            popoverController.sourceRect = profileEditView.cameraButton.bounds
        }

        present(alertController, animated: true)
    }

    private func presentCameraPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
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
