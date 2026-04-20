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

final class PlantRegisterReactor: Reactor {
    @Dependency(\.plantService) private var plantService

    enum Action {
        case viewDidLoad
        case selectPlant(SelectedPlant)
        case saveTapped(PlantCreateInput)
    }

    enum Mutation {
        case setSelectedPlant(SelectedPlant)
        case setSaving(Bool)
        case setSaveCompleted
        case setErrorMessage(String)
    }

    struct State {
        var isReady = false
        var selectedPlant: SelectedPlant? = nil
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
        case .saveTapped(let input):
            return savePlant(input: input)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setSelectedPlant(let selectedPlant):
            newState.selectedPlant = selectedPlant
        case .setSaving(let isSaving):
            newState.isSaving = isSaving
        case .setSaveCompleted:
            newState.isSaving = false
            newState.saveCompleted = true
        case .setErrorMessage(let message):
            newState.isSaving = false
            newState.errorMessage = message
        }

        return newState
    }

    private func savePlant(input: PlantCreateInput) -> Observable<Mutation> {
        Observable.create { [plantService] observer in
            observer.onNext(.setSaving(true))

            let task = Task {
                do {
                    _ = try await plantService.registerPlant(input: input)
                    observer.onNext(.setSaveCompleted)
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage(error.localizedDescription))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
}
