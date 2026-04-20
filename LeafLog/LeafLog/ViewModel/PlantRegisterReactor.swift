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

final class PlantRegisterReactor: Reactor {
    @Dependency(\.plantService) private var plantService

    private struct ValidationError: Error {
        let message: String
    }

    enum Action {
        case viewDidLoad
        case selectPlant(SelectedPlant)
        case updateCategory(PlantCategory?)
        case updateLocation(PlantLocation?)
        case updateWateringInterval(String)
        case updateLastWateredDate(Date?)
        case saveTapped(nickname: String?, image: UIImage?)
    }

    enum Mutation {
        case setSelectedPlant(SelectedPlant)
        case setSelectedCategory(PlantCategory?)
        case setSelectedLocation(PlantLocation?)
        case setWateringIntervalText(String)
        case setLastWateredDate(Date?)
        case setSaving(Bool)
        case setSaveCompleted
        case setErrorMessage(String)
    }

    struct State {
        var isReady = false
        var selectedPlant: SelectedPlant? = nil
        var selectedCategory: PlantCategory? = nil
        var selectedLocation: PlantLocation? = nil
        var wateringIntervalText = ""
        var lastWateredDate: Date? = nil
        var isRegisterEnabled = false
        var isSaving = false
        @Pulse var saveCompleted = false
        @Pulse var errorMessage: String? = nil
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .empty()
        case .selectPlant(let selectedPlant):
            return .just(.setSelectedPlant(selectedPlant))
        case .updateCategory(let category):
            return .just(.setSelectedCategory(category))
        case .updateLocation(let location):
            return .just(.setSelectedLocation(location))
        case .updateWateringInterval(let text):
            return .just(.setWateringIntervalText(text))
        case .updateLastWateredDate(let date):
            return .just(.setLastWateredDate(date))
        case .saveTapped(let nickname, let image):
            return savePlant(nickname: nickname, image: image)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setSelectedPlant(let selectedPlant):
            newState.selectedPlant = selectedPlant
            newState.selectedCategory = suggestedCategory(from: selectedPlant)
            newState.wateringIntervalText = suggestedWateringIntervalText(from: selectedPlant.detail?.springWaterCycle)
        case .setSelectedCategory(let category):
            newState.selectedCategory = category
        case .setSelectedLocation(let location):
            newState.selectedLocation = location
        case .setWateringIntervalText(let text):
            newState.wateringIntervalText = text
        case .setLastWateredDate(let date):
            newState.lastWateredDate = date
        case .setSaving(let isSaving):
            newState.isSaving = isSaving
        case .setSaveCompleted:
            newState = State()
            newState.saveCompleted = true
        case .setErrorMessage(let message):
            newState.isSaving = false
            newState.errorMessage = message
        }

        newState.isRegisterEnabled = isRegisterEnabled(for: newState)
        return newState
    }

    private func savePlant(nickname: String?, image: UIImage?) -> Observable<Mutation> {
        let inputResult = makePlantCreateInput(
            from: currentState,
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
                image: image,
                wateringIntervalDays: wateringIntervalDays,
                lastWateredAt: lastWateredAt
            )
        )
    }

    private func isRegisterEnabled(for state: State) -> Bool {
        let hasCategory = state.selectedCategory != nil
        let hasPlantName = !(state.selectedPlant?.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasLocation = state.selectedLocation != nil
        let hasWateringInterval = Int(state.wateringIntervalText.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
        let hasLastWateredDate = state.lastWateredDate != nil
        let isNotSaving = !state.isSaving

        return hasCategory
            && hasPlantName
            && hasLocation
            && hasWateringInterval
            && hasLastWateredDate
            && isNotSaving
    }

    private func suggestedCategory(from selectedPlant: SelectedPlant) -> PlantCategory? {
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

    private func suggestedWateringIntervalText(from springWaterCycle: String?) -> String {
        guard let springWaterCycle else { return "" }

        if springWaterCycle.contains("토양표면이 말랐을때 충분히 관수함")
            || springWaterCycle.contains("토양 표면이 말랐을때 충분히 관수함") {
            return "4"
        }

        if springWaterCycle.contains("화분 흙 대부분 말랐을때 충분히 관수")
            || springWaterCycle.contains("화분 흙 대부분 말랐을때 충분히 관수함") {
            return "7"
        }

        if springWaterCycle.contains("항상 흙을 촉촉하게 유지함(물에 잠김)")
            || springWaterCycle.contains("항상 흙을 촉촉하게 유지함") {
            return "0"
        }

        if springWaterCycle.contains("흙을 촉촉하게 유지함(물에 잠기지 않도록 주의)")
            || springWaterCycle.contains("흙을 촉촉하게 유지함") {
            return "3"
        }

        return ""
    }
}
