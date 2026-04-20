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
    enum Action {
        case viewDidLoad
        case selectPlant(SelectedPlant)
    }

    enum Mutation {
        case setSelectedPlant(SelectedPlant)
    }

    struct State {
        var isReady = false
        var selectedPlant: SelectedPlant? = nil
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .empty()
        case .selectPlant(let selectedPlant):
            return .just(.setSelectedPlant(selectedPlant))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setSelectedPlant(let selectedPlant):
            newState.selectedPlant = selectedPlant
        }

        return newState
    }
}
