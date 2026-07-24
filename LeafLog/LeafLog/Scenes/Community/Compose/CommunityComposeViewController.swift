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
    let composeView = CommunityComposeView(mode: .create)
    
    //MARK: Lifecycle
    override func loadView() {
        view = composeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hidesBottomBarWhenPushed = true
        navigationController?.navigationBar.isHidden = true
        setPictureActions()
    }
    
    //MARK: Bind
    func bind(reactor: CommunityComposeReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: CommunityComposeReactor) {
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
            .map { CommunityComposeReactor.Action.enterTitle($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        composeView.rx.pictureViewTap
            .compactMap { [weak self] index -> PHPickerViewController? in
                return self?.makeImagePicker()
            }
            .withUnretained(self)
            .do(onNext: { $0.present($1, animated: true) })
            .flatMap { $1.rx.selectedImages.take(1) }
            .map { CommunityComposeReactor.Action.selectPicture($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        composeView.bodyTextView.rx.setDelegate(self)
            .disposed(by: disposeBag)

        composeView.bodyTextView.rx.text.orEmpty
            .distinctUntilChanged()
            .map { CommunityComposeReactor.Action.enterBody($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        
    }
    
    private func bindState(reactor: CommunityComposeReactor) {
        let state = reactor.state.asDriver(onErrorJustReturn: .init(category: .plantLife))
        
        state.map(\.category)
            .drive(with: composeView) { view, category in
                view.applySelectedCategory(category)
            }
            .disposed(by: disposeBag)
        
        state.map(\.body)
            .drive(with: composeView) { view, text in
                let count = text.count
                view.updatePlaceholderVisibility(count) // 텍스트뷰 플레이스홀더 레이블 표시 UI 설정
                view.updateCount(count) // 텍스트 초과 표시 UI 설정
            }
            .disposed(by: disposeBag)
        
        state.map(\.isButtonActive)
            .drive(with: composeView) { view, isActive in
                view.saveButton.isEnabled = isActive
            }
            .disposed(by: disposeBag)
    }
}

//MARK: 사진 선택 기능 관련
extension CommunityComposeViewController {
    private func setPictureActions() {
        composeView.pictureViews.forEach { pictureView in
            pictureView.onPictureSelectionRequested = { [weak self, weak pictureView] in
                guard let self, let pictureView else { return }

               
            }
        }
    }

    private func makeImagePicker() -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 3

        let picker = PHPickerViewController(configuration: configuration)
    
        return picker
    }
}

//MARK: UITextView Delegate
extension CommunityComposeViewController: UITextViewDelegate {
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
