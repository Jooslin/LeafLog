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
import Then

final class PlantRegisterViewController: BaseViewController, View {
    
    private let registerView = PlantRegisterView()
    private var selectedImage: UIImage?
    private let lastWateredDatePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .wheels
        $0.locale = Locale(identifier: "ko_KR")
        $0.timeZone = TimeZone(identifier: "Asia/Seoul")
        $0.maximumDate = Date()
    }
    private let lastWateredDateFormatter = DateFormatter().then {
        $0.locale = Locale(identifier: "ko_KR")
        $0.timeZone = TimeZone(identifier: "Asia/Seoul")
        $0.dateFormat = "yyyy / MM / dd"
    }
    
    init(reactor: PlantRegisterReactor = PlantRegisterReactor()) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = registerView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
//        bindUI(reactor: reactor)
    }
    
    func bind(reactor: PlantRegisterReactor) {
        Observable.just(())
            .map { PlantRegisterReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
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
            .map(\.wateringIntervalText)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] text in
                guard self?.registerView.wateringCycleTextField.text != text else { return }
                self?.registerView.wateringCycleTextField.text = text
            })
            .disposed(by: disposeBag)
        
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
                self?.resetFormUI()
                self?.steps.accept(AppStep.pageBack)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("저장 실패", message))
            })
            .disposed(by: disposeBag)
        
        bindUI(reactor: reactor)
    }
    
    private func bindUI(reactor: PlantRegisterReactor) {
        registerView.headerView.backButton.rx.tap
            .map {
                AppStep.pageBack
            }
            .bind(to: steps)
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
        
        //TODO: 검색 카메라 버튼 구현 시 아래 주석 풀고 사용 예정입니다. (단, 이벤트 보내는 주체 변경 필요)
//        registerView.plantTypeSearchButton.rx.tap
//            .compactMap { [weak self] _ -> PHPickerViewController? in
//                return self?.makeImagePicker()
//            }
//            .withUnretained(self)
//            .do(onNext: { $0.present($1, animated: true) })
//            .flatMap { $1.rx.selectedImages }
//            .compactMap(\.first)
//            .map { PlantRegisterReactor.Action.classificationImageSelected($0) }
//            .bind(to: reactor.action)
//            .disposed(by: disposeBag)
        
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
        
        registerView.wateringCycleTextField.rx.text.orEmpty
            .map { PlantRegisterReactor.Action.updateWateringInterval($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        registerView.registerButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handleRegisterTap()
            })
            .disposed(by: disposeBag)
        
        configureLastWateredDatePicker()
        syncInitialFormState()
    }
    
    private func updateSingleSelection(selectedButton: UIButton, in buttons: [UIButton]) {
        buttons.forEach { $0.isSelected = ($0 === selectedButton) }
    }
    
//    @objc private func handleFormValueChanged() {
//        reactor?.action.onNext(
//            .updateWateringInterval(registerView.wateringCycleTextField.text ?? "")
//        )
//    }
    
    private func notifyCategorySelectionChanged() {
        reactor?.action.onNext(.updateCategory(selectedCategoryFromButtons))
    }
    
    private func notifyLocationSelectionChanged() {
        reactor?.action.onNext(.updateLocation(selectedLocationFromButtons))
    }
    
    private func syncInitialFormState() {
        notifyCategorySelectionChanged()
        notifyLocationSelectionChanged()
        reactor?.action.onNext(.updateWateringInterval(registerView.wateringCycleTextField.text ?? ""))
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
    
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }
    
    private func configureLastWateredDatePicker() {
        registerView.lastWateredDateTextField.inputView = lastWateredDatePicker
        registerView.lastWateredDateTextField.tintColor = .clear
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(didTapLastWateredDateDone))
        ]
        registerView.lastWateredDateTextField.inputAccessoryView = toolbar
    }
    
    @objc private func didTapLastWateredDateDone() {
        let selectedDate = lastWateredDatePicker.date
        updateLastWateredDateField(date: selectedDate)
        reactor?.action.onNext(.updateLastWateredDate(selectedDate))
        registerView.lastWateredDateTextField.resignFirstResponder()
    }
    
    private func updateLastWateredDateField(date: Date) {
        registerView.lastWateredDateTextField.text = lastWateredDateFormatter.string(from: date)
    }
    
    private func resetFormUI() {
        selectedImage = nil
        lastWateredDatePicker.date = Date()
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

extension PlantRegisterViewController: PHPickerViewControllerDelegate {
    //TODO: 추후 수정 필요!!!
    //    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    //        picker.dismiss(animated: true)
    //
    //        guard let result = results.first,
    //              result.itemProvider.canLoadObject(ofClass: UIImage.self)
    //        else {
    //            return
    //        }
    //
    //        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
    //            guard let selectedImage = image as? UIImage else { return }
    //
    //            DispatchQueue.main.async {
    //                self?.selectedImage = selectedImage
    //                self?.registerView.cameraButton.layer.contents = selectedImage.cgImage
    //                self?.registerView.cameraButton.layer.contentsGravity = .resizeAspectFill
    //                self?.registerView.cameraButton.backgroundColor = .clear
    //            }
    //        }
    //    }
    
    // picker에서 이미지 선택 시(picker 종료 시) 동작
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let item = results.first,
              item.itemProvider.canLoadObject(ofClass: UIImage.self) else {
            picker.dismiss(animated: true)
            return
        }
        
        // itemProvider에서 UIImage로 로드가 가능하다면 UIImage로 선택된 사진 load
        item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self, weak picker] image, error in // loadObject는 비동기로 작동하므로 picker도 약한 참조
            guard let image = image as? UIImage else {
                picker?.dismiss(animated: true)
                return
            }
            
            Task { @MainActor [weak self, weak picker] in
                picker?.dismiss(animated: true) { [weak self] in
                    self?.reactor?.action.onNext(PlantRegisterReactor.Action.classificationImageSelected(image))
                }
            }
        }
    }
}
