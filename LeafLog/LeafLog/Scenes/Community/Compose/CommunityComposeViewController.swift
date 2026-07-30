//
//  CommunityComposeViewController.swift
//  LeafLog
//
//  Created by 변예린 on 7/5/26.
//

import UIKit
import Dependencies
import PhotosUI
import ReactorKit
import RxCocoa

final class CommunityComposeViewController: BaseViewController, View {
    //MARK: properties
    let composeView: CommunityComposeView
    private var pictureDragStartX: CGFloat?
    private var pictureDragTargetIndex: Int?

    init(mode: CommunityComposeMode = .create) {
        switch mode {
        case .create:
            composeView = CommunityComposeView(mode: .create)
        case .edit:
            composeView = CommunityComposeView(mode: .edit)
        }

        super.init(nibName: nil, bundle: nil)
        reactor = CommunityComposeReactor(mode: mode)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Lifecycle
    override func loadView() {
        view = composeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hidesBottomBarWhenPushed = true
        navigationController?.navigationBar.isHidden = true
    }
    
    //MARK: Bind
    func bind(reactor: CommunityComposeReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: CommunityComposeReactor) {
        rx.viewWillAppear
            .take(1)
            .map { _ in CommunityComposeReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        //MARK: TitleView
        // 뒤로가기
        composeView.titleView.rx.backButtonTap
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.pageBack)
            })
            .disposed(by: disposeBag)
        
        // 안내문
        composeView.titleView.rx.rightButtonTap
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.composeNotice)
            }) 
            .disposed(by: disposeBag)
        
        //MARK: Body
        composeView.rx.categoryButtonTap
            .map { CommunityComposeReactor.Action.selectCategory($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        composeView.titleTextField.rx.text.orEmpty
            .skip(1)
            .map { CommunityComposeReactor.Action.enterTitle($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        composeView.titleTextField.delegate = self
        
        composeView.rx.pictureViewTap
            .withLatestFrom(reactor.state.map(\.pictures.count)) { index, pictureCount in
                (index, pictureCount)
            }
            .compactMap { [weak self] index, pictureCount in
                self?.makePicturePickerRequest(
                    index: index,
                    pictureCount: pictureCount
                )
            }
            .withUnretained(self)
            .do(onNext: { viewController, request in
                viewController.present(request.picker, animated: true)
            })
            .flatMap { _, request in
                request.picker.rx.selectedImages
                    .take(1)
                    .map { images in (request, images) }
            }
            .observe(on: MainScheduler.instance)
            .compactMap { request, images in
                Self.makePictureAction(request: request, images: images)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        composeView.rx.pictureRemoveButtonTap
            .map { CommunityComposeReactor.Action.removePicture(index: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        composeView.rx.pictureViewLongPress
            .withLatestFrom(reactor.state.map(\.pictures.count)) { event, pictureCount in
                (event, pictureCount)
            }
            .compactMap { [weak self] event, pictureCount in
                self?.makePictureMoveAction(
                    index: event.index,
                    pictureCount: pictureCount,
                    gesture: event.gesture
                )
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        composeView.bodyTextView.rx.setDelegate(self)
            .disposed(by: disposeBag)

        composeView.bodyTextView.rx.text.orEmpty
            .skip(1)
            .distinctUntilChanged()
            .map { CommunityComposeReactor.Action.enterBody($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        composeView.saveButton.rx.tap
            .map { CommunityComposeReactor.Action.saveTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: CommunityComposeReactor) {
        let state = reactor.state.asDriver(onErrorDriveWith: .empty())
        
        state.map(\.category)
            .drive(with: composeView) { view, category in
                view.applySelectedCategory(category)
            }
            .disposed(by: disposeBag)

        state.map(\.title)
            .distinctUntilChanged()
            .drive(with: composeView) { view, title in
                guard view.titleTextField.text != title else { return }
                view.titleTextField.text = title
            }
            .disposed(by: disposeBag)
        
        state.map(\.body)
            .drive(with: composeView) { view, text in
                if view.bodyTextView.text != text {
                    view.bodyTextView.text = text
                }
                let count = text.count
                view.updatePlaceholderVisibility(count) // 텍스트뷰 플레이스홀더 레이블 표시 UI 설정
                view.updateCount(count) // 텍스트 초과 표시 UI 설정
            }
            .disposed(by: disposeBag)
        
        state.map(\.pictures)
            .drive(with: composeView) { view, pictures in
                view.applyPictures(pictures.map(\.previewImage))
            }
            .disposed(by: disposeBag)

        state.map(\.isButtonActive)
            .drive(with: composeView) { view, isActive in
                view.saveButton.isEnabled = isActive
            }
            .disposed(by: disposeBag)

        state.map(\.isSaving)
            .distinctUntilChanged()
            .drive(with: self) { viewController, isSaving in
                viewController.setSaving(isSaving)
            }
            .disposed(by: disposeBag)

        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { viewController, message in
                viewController.steps.accept(AppStep.alert("오류", message))
            }
            .disposed(by: disposeBag)

        reactor.pulse(\.$warningMessage)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { viewController, message in
                viewController.steps.accept(AppStep.alert("안내", message))
            }
            .disposed(by: disposeBag)
    }

    private func setSaving(_ isSaving: Bool) {
        composeView.isUserInteractionEnabled = !isSaving
        navigationController?
            .interactivePopGestureRecognizer?
            .isEnabled = !isSaving
    }
}

//MARK: 사진 선택 Image Picker 관련
extension CommunityComposeViewController {
    private typealias PicturePickerRequest = (
        index: Int,
        replacesExisting: Bool,
        picker: PHPickerViewController
    )

    // 사진 선택 수 제한 반영 imagePicker 생성
    private func makePicturePickerRequest(
        index: Int,
        pictureCount: Int
    ) -> PicturePickerRequest? {
        guard index <= pictureCount else { return nil }

        let replacesExisting = index < pictureCount
        let selectionLimit = replacesExisting
            ? 1
            : composeView.pictureViews.count - pictureCount
        guard selectionLimit > 0 else { return nil }

        return (
            index,
            replacesExisting,
            makeImagePicker(selectionLimit: selectionLimit)
        )
    }

    // 사진 선택 시 리액터에 전달할 액션 생성 - replace 혹은 add
    private static func makePictureAction(
        request: PicturePickerRequest,
        images: [UIImage]
    ) -> CommunityComposeReactor.Action? {
        if request.replacesExisting {
            guard let image = images.first else { return nil }
            return .replacePicture(index: request.index, image: image)
        }

        guard !images.isEmpty else { return nil }
        return .addPictures(images)
    }

    // 이미지 피커 생성
    private func makeImagePicker(selectionLimit: Int) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selection = .ordered
        configuration.selectionLimit = selectionLimit

        let picker = PHPickerViewController(configuration: configuration)
    
        return picker
    }
}

//MARK: 사진 순서 변경 애니메이션
extension CommunityComposeViewController {
    // 사진 순서 변경 액션
    private func makePictureMoveAction(
        index: Int,
        pictureCount: Int,
        gesture: UILongPressGestureRecognizer
    ) -> CommunityComposeReactor.Action? {
        guard index < pictureCount else { return nil }

        let pictureView = composeView.pictureViews[index]
        let location = gesture.location(in: composeView)

        switch gesture.state {
        case .began:
            pictureDragStartX = location.x
            pictureDragTargetIndex = index
            pictureView.superview?.layer.zPosition = 1
            pictureView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)

        case .changed:
            guard let startX = pictureDragStartX else { return nil }
            pictureView.transform = CGAffineTransform(
                translationX: location.x - startX,
                y: 0
            ).scaledBy(x: 1.05, y: 1.05)

            guard
                let targetIndex = nearestPictureIndex(
                    to: location.x,
                    pictureCount: pictureCount
                ),
                targetIndex != pictureDragTargetIndex
            else {
                return nil
            }
            pictureDragTargetIndex = targetIndex
            updateSiblingPictureTransforms(
                sourceIndex: index,
                targetIndex: targetIndex,
                pictureCount: pictureCount
            )

        case .ended:
            guard
                let targetIndex = nearestPictureIndex(
                    to: location.x,
                    pictureCount: pictureCount
                )
            else {
                resetPictureDrag(pictureView, pictureCount: pictureCount)
                return nil
            }
            resetPictureDrag(pictureView, pictureCount: pictureCount)
            guard targetIndex != index else { return nil }
            return .movePicture(from: index, to: targetIndex)

        case .cancelled, .failed:
            resetPictureDrag(
                pictureView,
                pictureCount: pictureCount,
                animated: true
            )

        default:
            break
        }

        return nil
    }

    // 가장 가까운 사진 인덱스 계산
    private func nearestPictureIndex(
        to locationX: CGFloat,
        pictureCount: Int
    ) -> Int? {
        (0..<pictureCount).min { lhs, rhs in
            abs(pictureCenterX(at: lhs) - locationX)
                < abs(pictureCenterX(at: rhs) - locationX)
        }
    }

    // 사진 중앙 위치 계산
    private func pictureCenterX(at index: Int) -> CGFloat {
        let pictureView = composeView.pictureViews[index]
        let slotView = pictureView.superview ?? pictureView
        let center = CGPoint(
            x: slotView.bounds.midX,
            y: slotView.bounds.midY
        )
        return slotView.convert(center, to: composeView).x
    }

    // 드래그 위치에 따라 기존 사진을 한 칸씩 이동
    private func updateSiblingPictureTransforms(
        sourceIndex: Int,
        targetIndex: Int,
        pictureCount: Int
    ) {
        let slotDistance = abs(
            pictureCenterX(at: 1) - pictureCenterX(at: 0)
        )

        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction]
        ) {
            for index in 0..<pictureCount where index != sourceIndex {
                let translationX: CGFloat

                if sourceIndex < targetIndex,
                   index > sourceIndex,
                   index <= targetIndex {
                    translationX = -slotDistance
                } else if sourceIndex > targetIndex,
                          index >= targetIndex,
                          index < sourceIndex {
                    translationX = slotDistance
                } else {
                    translationX = 0
                }

                self.composeView.pictureViews[index].transform =
                    CGAffineTransform(translationX: translationX, y: 0)
            }
        }
    }

    // 사진 순서 변경 제스처 관련 초기화
    private func resetPictureDrag(
        _ pictureView: PictureComposeView,
        pictureCount: Int,
        animated: Bool = false
    ) {
        pictureDragStartX = nil
        pictureDragTargetIndex = nil
        pictureView.superview?.layer.zPosition = 0

        let resetTransforms = {
            self.composeView.pictureViews.forEach {
                $0.transform = .identity
            }
        }

        if animated {
            UIView.animate(
                withDuration: 0.15,
                animations: resetTransforms
            )
        } else {
            resetTransforms()
        }
    }
}

//MARK: Text Input Delegate
extension CommunityComposeViewController: UITextFieldDelegate, UITextViewDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentText = textField.text ?? ""
        guard let textRange = Range(range, in: currentText) else {
            return false
        }

        let updatedText = currentText.replacingCharacters(
            in: textRange,
            with: string
        )

        return updatedText.count <= 50
    }

    // 글자수 제한 기능
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        let currentText = textView.text ?? ""
        guard let textRange = Range(range, in: currentText) else {
            return false
        }

        let updatedText = currentText.replacingCharacters(in: textRange, with: text)
        if updatedText.count <= CommunityComposeView.bodyMaxCount {
            return true
        }

        let replaceCount = currentText[textRange].count // 글자를 붙여넣기할 때 붙여넣을 글자의 수
        let remainingCount = CommunityComposeView.bodyMaxCount - currentText.count + replaceCount
        guard remainingCount > 0 else {
            return false
        }

        // 최대 글자 수 까지만 글자를 적용하여 textView에 반영
        let limitedText = String(text.prefix(remainingCount))
        let limitedUpdatedText = currentText.replacingCharacters(in: textRange, with: limitedText)
        textView.text = limitedUpdatedText
        textView.selectedRange = NSRange(
            location: range.location + (limitedText as NSString).length,
            length: 0
        )
        
        // NotificationCenter를 통해 textView.text의 변경을 알림 -> bodyTextView.rx.tex.orEmpty에서 감지
        NotificationCenter.default.post(
            name: UITextView.textDidChangeNotification,
            object: textView
        )

        return false
    }
}

@available(iOS 17.0, *)
#Preview {
  CommunityComposeViewController()
}
