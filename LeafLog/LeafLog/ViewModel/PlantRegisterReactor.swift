//
//  PlantRegisterReactor.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/20/26.
//
import Dependencies
import Foundation
import ReactorKit
import RxSwift
import UIKit
import OSLog

final class PlantRegisterReactor: Reactor {
    @Dependency(\.plantService) private var plantService
    @Dependency(\.plantClassificationService) private var plantClassificationService
    private static let lastWateredDateCalendar = Calendar(identifier: .gregorian)
    private static let lastWateredDateTimeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    private let logger = Logger(subsystem: "LeafLog", category: "PlantRegisterReactor")

    enum Mode: Equatable {
        case create(SelectedPlant?)
        case edit(MyPlant)

        var title: String {
            switch self {
            case .create:
                return "식물 등록"
            case .edit:
                return "식물 수정"
            }
        }

        var buttonTitle: String {
            switch self {
            case .create:
                return "등록하기"
            case .edit:
                return "수정하기"
            }
        }
    }
    
    private struct ValidationError: Error {
        let message: String
    }

    enum Action {
        case viewDidLoad
        case updateCategory(PlantCategory?)
        case updateLocation(PlantLocation?)
        case updateSelectedPlant(SelectedPlant)
        case updateNickname(String)
        case updateWateringInterval(String)
        case updateLastWateredDate(Date?)
        case saveTapped(nickname: String?, image: UIImage?)
        case deleteTapped
        
        case classificationImageSelected(UIImage)
    }

    enum Mutation {
        case setSelectedPlant(SelectedPlant)
        case setSelectedCategory(PlantCategory?)
        case setSelectedLocation(PlantLocation?)
        case setNicknameText(String)
        case setWateringIntervalText(String)
        case setLastWateredDate(Date?)
        case setExistingImage(UIImage?)
        case setSaving(Bool)
        case setSaveCompleted
        case setDeleteCompleted
        case setErrorMessage(String)
        
        case analyzeResult([String: PlantClassificationService.Confidence])
    }

    struct State {
        var isReady = false
        var mode: Mode = .create(nil)
        var title = "식물 등록"
        var buttonTitle = "등록하기"
        var selectedPlant: SelectedPlant? = nil
        var nicknameText = ""
        var selectedCategory: PlantCategory? = nil
        var selectedLocation: PlantLocation? = nil
        var wateringIntervalText = ""
        var lastWateredDate: Date? = nil
        var lastWateredDateText = ""
        var isRegisterEnabled = false
        var isSaving = false
        @Pulse var existingImage: UIImage? = nil
        @Pulse var saveCompleted = false
        @Pulse var deleteCompleted = false
        @Pulse var errorMessage: String? = nil
        
        var classificationResult: [String: PlantClassificationService.Confidence] = [:]
    }

    let initialState: State

    init(selectedPlant: SelectedPlant? = nil) {
        self.initialState = Self.makeInitialState(mode: .create(selectedPlant))
    }

    init(mode: Mode) {
        self.initialState = Self.makeInitialState(mode: mode)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return loadExistingImage(state: currentState)
        case .updateCategory(let category):
            return .just(.setSelectedCategory(category))
        case .updateLocation(let location):
            return .just(.setSelectedLocation(location))
        case .updateSelectedPlant(let selectedPlant):
            return .just(.setSelectedPlant(selectedPlant))
        case .updateNickname(let nickname):
            return .just(.setNicknameText(nickname))
        case .updateWateringInterval(let text):
            return .just(.setWateringIntervalText(text))
        case .updateLastWateredDate(let date):
            return .just(.setLastWateredDate(date))
        case .saveTapped(let nickname, let image):
            return savePlant(state: currentState, nickname: nickname, image: image)
        case .deleteTapped:
            return deletePlant(state: currentState)
        case .classificationImageSelected(let image):
            return analyzeImage(image)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setSelectedPlant(let selectedPlant):
            newState.selectedPlant = selectedPlant
            newState.selectedCategory = Self.suggestedCategory(from: selectedPlant)
            let suggestedWateringIntervalText = Self.suggestedWateringIntervalText(from: selectedPlant.detail?.springWaterCycle)
            if !suggestedWateringIntervalText.isEmpty || newState.wateringIntervalText.isEmpty {
                newState.wateringIntervalText = suggestedWateringIntervalText
            }
        case .setSelectedCategory(let category):
            newState.selectedCategory = category
        case .setSelectedLocation(let location):
            newState.selectedLocation = location
        case .setNicknameText(let nickname):
            newState.nicknameText = nickname
        case .setWateringIntervalText(let text):
            newState.wateringIntervalText = text
        case .setLastWateredDate(let date):
            newState.lastWateredDate = date
            newState.lastWateredDateText = Self.makeLastWateredDateText(from: date)
        case .setExistingImage(let image):
            newState.existingImage = image
        case .setSaving(let isSaving):
            newState.isSaving = isSaving
        case .setSaveCompleted:
            newState.isSaving = false
            newState.saveCompleted = true
        case .setDeleteCompleted:
            newState.isSaving = false
            newState.deleteCompleted = true
        case .setErrorMessage(let message):
            newState.isSaving = false
            newState.errorMessage = message
        case .analyzeResult(let result):
            newState.classificationResult = result
        }

        newState.isRegisterEnabled = Self.isRegisterEnabled(for: newState)
        return newState
    }

    private func savePlant(state: State, nickname: String?, image: UIImage?) -> Observable<Mutation> {
        switch state.mode {
        case .create:
            return createPlant(state: state, nickname: nickname, image: image)
        case .edit:
            return updatePlant(state: state, nickname: nickname, image: image)
        }
    }

    private func createPlant(state: State, nickname: String?, image: UIImage?) -> Observable<Mutation> {
        let inputResult = makePlantCreateInput(
            from: state,
            nickname: nickname,
            image: image
        )

        guard case let .success(input) = inputResult else {
            if case let .failure(error) = inputResult {
                return .just(.setErrorMessage(error.message))
            }
            return .empty()
        }

        return Observable.create { [plantService] observer in
            observer.onNext(Mutation.setSaving(true))

            let task = Task {
                do {
                    _ = try await plantService.registerPlant(input: input)
                    observer.onNext(Mutation.setSaveCompleted)
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(Mutation.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(Mutation.setErrorMessage(error.localizedDescription))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func updatePlant(state: State, nickname: String?, image: UIImage?) -> Observable<Mutation> {
        let inputResult = makePlantUpdateInput(
            from: state,
            nickname: nickname,
            image: image
        )

        guard case let .success(input) = inputResult else {
            if case let .failure(error) = inputResult {
                return .just(.setErrorMessage(error.message))
            }
            return .empty()
        }

        return Observable.create { [plantService] observer in
            observer.onNext(Mutation.setSaving(true))

            let task = Task {
                do {
                    _ = try await plantService.updatePlant(input: input)
                    observer.onNext(Mutation.setSaveCompleted)
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(Mutation.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(Mutation.setErrorMessage(error.localizedDescription))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func deletePlant(state: State) -> Observable<Mutation> {
        guard case let .edit(plant) = state.mode else {
            return .just(.setErrorMessage("삭제할 식물 정보를 찾지 못했어요."))
        }

        return Observable.create { [plantService] observer in
            observer.onNext(Mutation.setSaving(true))

            let task = Task {
                do {
                    try await plantService.deletePlant(
                        plantID: plant.id,
                        imagePath: plant.imagePath
                    )
                    observer.onNext(Mutation.setDeleteCompleted)
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(Mutation.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(Mutation.setErrorMessage(error.localizedDescription))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func loadExistingImage(state: State) -> Observable<Mutation> {
        guard case let .edit(plant) = state.mode else {
            return .empty()
        }

        return Observable.create { [plantService] observer in
            let task = Task {
                do {
                    let image = try await plantService.loadPlantImage(from: plant.imagePath)
                    observer.onNext(.setExistingImage(image))
                    observer.onCompleted()
                } catch {
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func makePlantCreateInput(
        from state: State,
        nickname: String?,
        image: UIImage?
    ) -> Result<PlantCreateInput, ValidationError> {
        guard let category = state.selectedCategory else {
            return .failure(ValidationError(message: "식물 카테고리를 선택해주세요."))
        }

        guard let speciesName = state.selectedPlant?.name.trimmingCharacters(in: .whitespacesAndNewlines),
              !speciesName.isEmpty else {
            return .failure(ValidationError(message: "식물 종류를 먼저 선택해주세요."))
        }

        guard let nickname = nickname?.trimmingCharacters(in: .whitespacesAndNewlines),
              !nickname.isEmpty else {
            return .failure(ValidationError(message: "식물 별명을 입력해주세요."))
        }

        guard let location = state.selectedLocation else {
            return .failure(ValidationError(message: "식물 위치를 선택해주세요."))
        }

        guard let wateringIntervalDays = Int(state.wateringIntervalText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return .failure(ValidationError(message: "급수 주기를 올바르게 입력해주세요."))
        }

        guard let lastWateredAt = state.lastWateredDate else {
            return .failure(ValidationError(message: "마지막 급수일을 선택해주세요."))
        }

        return .success(
            PlantCreateInput(
                category: category,
                location: location,
                nickname: nickname,
                speciesName: speciesName,
                contentNumber: state.selectedPlant?.contentNumber,
                image: image,
                wateringIntervalDays: wateringIntervalDays,
                lastWateredAt: lastWateredAt
            )
        )
    }

    private func makePlantUpdateInput(
        from state: State,
        nickname: String?,
        image: UIImage?
    ) -> Result<PlantUpdateInput, ValidationError> {
        guard case let .edit(plant) = state.mode else {
            return .failure(ValidationError(message: "수정할 식물 정보를 찾지 못했어요."))
        }

        guard let category = state.selectedCategory else {
            return .failure(ValidationError(message: "식물 카테고리를 선택해주세요."))
        }

        guard let speciesName = state.selectedPlant?.name.trimmingCharacters(in: .whitespacesAndNewlines),
              !speciesName.isEmpty else {
            return .failure(ValidationError(message: "식물 종류를 먼저 선택해주세요."))
        }

        guard let nickname = nickname?.trimmingCharacters(in: .whitespacesAndNewlines),
              !nickname.isEmpty else {
            return .failure(ValidationError(message: "식물 별명을 입력해주세요."))
        }

        guard let location = state.selectedLocation else {
            return .failure(ValidationError(message: "식물 위치를 선택해주세요."))
        }

        guard let wateringIntervalDays = Int(state.wateringIntervalText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return .failure(ValidationError(message: "급수 주기를 올바르게 입력해주세요."))
        }

        guard let lastWateredAt = state.lastWateredDate else {
            return .failure(ValidationError(message: "마지막 급수일을 선택해주세요."))
        }

        return .success(
            PlantUpdateInput(
                id: plant.id,
                category: category,
                location: location,
                nickname: nickname,
                speciesName: speciesName,
                contentNumber: state.selectedPlant?.contentNumber,
                image: image,
                existingImagePath: plant.imagePath,
                wateringIntervalDays: wateringIntervalDays,
                lastWateredAt: lastWateredAt
            )
        )
    }

    private static func isRegisterEnabled(for state: State) -> Bool {
        let hasCategory = state.selectedCategory != nil
        let hasPlantName = !(state.selectedPlant?.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasNickname = !state.nicknameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLocation = state.selectedLocation != nil
        let hasWateringInterval = Int(state.wateringIntervalText.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
        let hasLastWateredDate = state.lastWateredDate != nil
        let isNotSaving = !state.isSaving

        return hasCategory
            && hasPlantName
            && hasNickname
            && hasLocation
            && hasWateringInterval
            && hasLastWateredDate
            && isNotSaving
    }

    private static func makeInitialState(mode: Mode) -> State {
        var state = State()
        state.mode = mode
        state.title = mode.title
        state.buttonTitle = mode.buttonTitle

        switch mode {
        case .create(let selectedPlant):
            state.selectedPlant = selectedPlant
            state.selectedCategory = suggestedCategory(from: selectedPlant)
            state.wateringIntervalText = suggestedWateringIntervalText(from: selectedPlant?.detail?.springWaterCycle)

        case .edit(let plant):
            state.selectedPlant = SelectedPlant(
                name: plant.speciesName,
                contentNumber: plant.contentNumber,
                detail: nil,
                category: plant.category
            )
            state.nicknameText = plant.nickname ?? ""
            state.selectedCategory = plant.category
            state.selectedLocation = plant.location
            state.wateringIntervalText = "\(plant.wateringIntervalDays)"
            state.lastWateredDate = plant.lastWateredAt
            state.lastWateredDateText = makeLastWateredDateText(from: plant.lastWateredAt)
        }

        state.isRegisterEnabled = isRegisterEnabled(for: state)
        return state
    }

    private static func suggestedCategory(from selectedPlant: SelectedPlant?) -> PlantCategory? {
        guard let selectedPlant else { return nil }

        if let selectedCategory = selectedPlant.category {
            return selectedCategory
        }

        guard let growStyle = selectedPlant.detail?.growStyle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !growStyle.isEmpty else {
            return nil
        }

        return PlantCategory.allCases.first { category in
            growStyle.contains(category.rawValue) || category.rawValue.contains(growStyle)
        }
    }

    private static func suggestedWateringIntervalText(from springWaterCycle: String?) -> String {
        guard let springWaterCycle else { return "" }
        let normalizedWaterCycle = springWaterCycle.components(separatedBy: .whitespacesAndNewlines).joined()

        if normalizedWaterCycle.contains("토양표면이말랐을때충분히관수") {
            return "4"
        }

        if normalizedWaterCycle.contains("화분흙대부분말랐을때충분히관수") {
            return "7"
        }

        if normalizedWaterCycle.contains("항상흙을촉촉하게유지함") {
            return "0"
        }

        if normalizedWaterCycle.contains("흙을촉촉하게유지함") {
            return "3"
        }

        return ""
    }

    private static func makeLastWateredDateText(from date: Date?) -> String {
        guard let date else { return "" }
        var calendar = lastWateredDateCalendar
        calendar.timeZone = lastWateredDateTimeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return ""
        }

        return String(format: "%04d / %02d / %02d", year, month, day)
    }
}

extension PlantRegisterReactor {
    private func analyzeImage(_ image: UIImage) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            Task {
                do {
                    let classificationResult = try self.plantClassificationService.analyzeImage(image: image)
                    observer.onNext(.analyzeResult(classificationResult))
                    observer.onCompleted()
                } catch let error as PlantClassificationService.ClassificationError {
                    self.logger.error("PlantClassificationError: \(error.localizedDescription)")
                    observer.onNext(.analyzeResult([:]))
                    observer.onCompleted()
                } catch {
                    self.logger.error("알 수 없는 에러: \(error.localizedDescription)")
                    observer.onNext(.analyzeResult([:]))
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}
