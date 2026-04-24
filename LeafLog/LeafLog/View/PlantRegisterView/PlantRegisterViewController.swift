//
//  PlantRegisterViewController.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/17/26.
//

import PhotosUI
import ReactorKit
import RxSwift
import UIKit
import RxCocoa

private struct PlantRegisterHeaderState: Equatable {
    let title: String
    let buttonTitle: String
    let showsDeleteButton: Bool
}

private struct LastWateredDateViewState: Equatable {
    let date: Date?
    let text: String
}

private func makePlantRegisterHeaderState(_ state: PlantRegisterReactor.State) -> PlantRegisterHeaderState {
    let showsDeleteButton: Bool
    if case .edit = state.mode {
        showsDeleteButton = true
    } else {
        showsDeleteButton = false
    }

    return PlantRegisterHeaderState(
        title: state.title,
        buttonTitle: state.buttonTitle,
        showsDeleteButton: showsDeleteButton
    )
}

final class PlantRegisterViewController: BaseViewController, View {
    private let registerView = PlantRegisterView()
    private var selectedImage: UIImage?
    
    init(reactor: PlantRegisterReactor = PlantRegisterReactor()) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSelectedPlant(_ selectedPlant: SelectedPlant) {
        reactor?.action.onNext(.updateSelectedPlant(selectedPlant))
    }
    
    override func loadView() {
        view = registerView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        guard let reactor else { return }
        bindUI(reactor: reactor)
    }

    func bind(reactor: PlantRegisterReactor) {
        // 진입에 따라서 헤더 바꾸기(등록/수정)
        reactor.state
            .map(makePlantRegisterHeaderState)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] headerState in
                self?.registerView.configureHeader(
                    title: headerState.title,
                    buttonTitle: headerState.buttonTitle,
                    showsDeleteButton: headerState.showsDeleteButton
                )
            })
            .disposed(by: disposeBag)
        
        // 선택 식물 변경시 안내뷰 변경
        reactor.state
            .map(\.selectedPlant)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] selectedPlant in
                guard let self else { return }
                
                guard let selectedPlant else {
                    self.resetFormUI()
                    return
                }
                
                self.registerView.applySelectedPlant(
                    name: selectedPlant.name,
                    growStyle: selectedPlant.detail?.growStyle,
                    lightDemand: selectedPlant.detail?.lightDemand,
                    springWaterCycle: selectedPlant.detail?.springWaterCycle,
                    selectedCategory: selectedPlant.category
                )
            })
            .disposed(by: disposeBag)

        reactor.pulse(\.$existingImage)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] image in
                guard let self, self.selectedImage == nil else { return }
                self.registerView.cameraButton.backgroundImageView.image = image
                self.registerView.cameraButton.backgroundColor = .clear
            })
            .disposed(by: disposeBag)
        
        // 세부사항 채우기
        reactor.state
            .map(\.selectedCategory)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] category in
                self?.applyCategorySelection(category)
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.selectedLocation)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] location in
                self?.applyLocationSelection(location)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.nicknameText)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] nickname in
                guard self?.registerView.plantNameTextField.text != nickname else { return }
                self?.registerView.plantNameTextField.text = nickname
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.wateringIntervalText)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] text in
                guard self?.registerView.wateringCycleTextField.text != text else { return }
                self?.registerView.wateringCycleTextField.text = text
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { LastWateredDateViewState(date: $0.lastWateredDate, text: $0.lastWateredDateText) }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] viewState in
                guard let self, let date = viewState.date else { return }
                self.registerView.setLastWateredDate(date, text: viewState.text)
            })
            .disposed(by: disposeBag)
        
        // 저장 가능 상태인지 검증
        reactor.state
            .map(\.isRegisterEnabled)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isEnabled in
                self?.applyRegisterButtonState(isEnabled: isEnabled)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$saveCompleted)
            .filter { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                self.resetFormUI()
                switch reactor.currentState.mode {
                case .create:
                    self.steps.accept(AppStep.plantTab)
                case .edit:
                    self.steps.accept(AppStep.pageBack)
                }
            })
            .disposed(by: disposeBag)

        reactor.pulse(\.$deleteCompleted)
            .filter { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.plantTab)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("오류", message))
            })
            .disposed(by: disposeBag)

        Observable.just(PlantRegisterReactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindUI(reactor: PlantRegisterReactor) {
        registerView.headerView.backButton.rx.tap
            .map {
                AppStep.pageBack
            }
            .bind(to: steps)
            .disposed(by: disposeBag)

        registerView.headerView.rightButton.rx.tap
            .subscribe(onNext: { [weak self, weak reactor] in
                guard case .edit = reactor?.currentState.mode else { return }

                self?.steps.accept(
                    AppStep.confirmAlert(
                        title: "식물 삭제",
                        message: "이 식물을 영구 삭제하시겠습니까?",
                        okTitle: "삭제",
                        onConfirm: { [weak reactor] in
                            reactor?.action.onNext(.deleteTapped)
                        }
                    )
                )
            })
            .disposed(by: disposeBag)
        
        registerView.cameraButton.rx.tap
            .compactMap { [weak self] _ -> PHPickerViewController? in
                return self?.makeImagePicker()
            }
            .withUnretained(self)
            .do(onNext: { $0.present($1, animated: true) }) // $0 == self, $1 == PHPickerViewController - 이미지 피커 띄우기
            .flatMap { $1.rx.selectedImages }
            .compactMap(\.first)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] image in
                self?.selectedImage = image
                self?.registerView.cameraButton.backgroundImageView.image = image
                self?.registerView.cameraButton.backgroundColor = .clear
            })
            .disposed(by: disposeBag)
        
        registerView.plantTypeSearchButton.addAction(
            UIAction { [weak self] _ in
                self?.handlePlantTypeSearchTap()
            },
            for: .touchUpInside
        )
        
        registerView.plantTypeSearchBar.cameraButton.rx.tap
            .map { AppStep.cameraRequired }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        registerView.categoryButtons.forEach { button in
            button.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.updateSingleSelection(
                        selectedButton: button,
                        in: self?.registerView.categoryButtons ?? [])
                    self?.notifyCategorySelectionChanged()
                })
                .disposed(by: disposeBag)
        }
        
        registerView.locationButtons.forEach { button in
            button.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.updateSingleSelection(
                        selectedButton: button,
                        in: self?.registerView.locationButtons ?? []
                    )
                    self?.notifyLocationSelectionChanged()
                })
                .disposed(by: disposeBag)
        }

        registerView.plantNameTextField.rx.text.orEmpty
            .map { PlantRegisterReactor.Action.updateNickname($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        registerView.wateringCycleTextField.rx.text.orEmpty
            .map { PlantRegisterReactor.Action.updateWateringInterval($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        registerView.registerButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handleRegisterTap()
            })
            .disposed(by: disposeBag)

        registerView.onLastWateredDateDone = { [weak reactor] date in
            reactor?.action.onNext(.updateLastWateredDate(date))
        }

        syncInitialFormState()
    }

    private func updateSingleSelection(selectedButton: UIButton, in buttons: [UIButton]) {
        buttons.forEach { $0.isSelected = ($0 === selectedButton) }
    }
    
    private func notifyCategorySelectionChanged() {
        reactor?.action.onNext(.updateCategory(selectedCategoryFromButtons))
    }
    
    private func notifyLocationSelectionChanged() {
        reactor?.action.onNext(.updateLocation(selectedLocationFromButtons))
    }
    
    private func syncInitialFormState() {
        guard let state = reactor?.currentState else { return }

        if state.selectedCategory == nil {
            notifyCategorySelectionChanged()
        }

        if state.selectedLocation == nil {
            notifyLocationSelectionChanged()
        }

        if state.wateringIntervalText.isEmpty {
            reactor?.action.onNext(.updateWateringInterval(registerView.wateringCycleTextField.text ?? ""))
        }
    }
    
    private func applyRegisterButtonState(isEnabled: Bool) {
        registerView.registerButton.isEnabled = isEnabled
        registerView.registerButton.alpha = isEnabled ? 1.0 : 0.6
    }
    
    private func applyCategorySelection(_ category: PlantCategory?) {
        if category == .other {
            registerView.categoryButtons.forEach { $0.isSelected = false }
            return
        }
        
        registerView.categoryButtons.forEach { button in
            let buttonTitle = button.configuration?.title ?? button.title(for: .normal)
            button.isSelected = (buttonTitle == category?.rawValue)
        }
    }
    
    private func applyLocationSelection(_ location: PlantLocation?) {
        registerView.locationButtons.forEach { button in
            let buttonTitle = button.configuration?.title ?? button.title(for: .normal)
            button.isSelected = (buttonTitle == location?.rawValue)
        }
    }
    
    private func handlePlantTypeSearchTap() {
        view.endEditing(true)
        steps.accept(AppStep.plantSearch)
    }
    
    private func resetFormUI() {
        selectedImage = nil
        registerView.resetForm()
    }
    
    private func handleRegisterTap() {
        let nickname = registerView.plantNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        reactor?.action.onNext(
            .saveTapped(
                nickname: nickname?.isEmpty == true ? nil : nickname,
                image: selectedImage
            )
        )
    }
    
    private var selectedCategoryFromButtons: PlantCategory? {
        let selectedTitle = registerView.categoryButtons
            .first(where: \.isSelected)?
            .configuration?.title
        
        guard let selectedTitle else { return nil }
        return PlantCategory.allCases.first(where: { $0.rawValue == selectedTitle })
    }
    
    private var selectedLocationFromButtons: PlantLocation? {
        let selectedTitle = registerView.locationButtons
            .first(where: \.isSelected)?
            .configuration?.title
        
        guard let selectedTitle else { return nil }
        return PlantLocation.allCases.first(where: { $0.rawValue == selectedTitle })
    }
}

extension PlantRegisterViewController {
    private func makeImagePicker() -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images // 라이브러리에서 보여줄 asset의 종류 지정
        config.selectionLimit = 1 // 선택 개수 설정 (0은 무제한)
        
        let imagePicker = PHPickerViewController(configuration: config)
        return imagePicker
    }
}
