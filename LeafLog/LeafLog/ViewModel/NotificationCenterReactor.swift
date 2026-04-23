//
//  NotificationCenterReactor.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/23/26.
//

import Foundation
import ReactorKit
import RxSwift
import Dependencies

final class NotificationCenterReactor: Reactor {

    enum Action {
        case viewWillAppear
    }

    enum Mutation {
        case setAlarm([NotificationCenterView.Item])
    }

    struct State {
        var alarmItem: [NotificationCenterView.Item] = []
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return .just(.setAlarm([]))
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setAlarm(let items):
            newState.alarmItem = items
        }
        return newState
    }

}
