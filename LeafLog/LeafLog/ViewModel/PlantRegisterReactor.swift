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
    }

    enum Mutation { }

    struct State {
        var isReady = false
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .empty()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        state
    }
}
