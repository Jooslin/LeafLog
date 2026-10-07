//
//  AlarmSettingReactor.swift
//  LeafLog
//
//  Created by 변예린 on 10/7/26.
//

import ReactorKit
import RxSwift

final class AlarmSettingReactor: Reactor {
    enum Action {
        case viewWillAppear
    }

    enum Mutation {
        case setSettings([AlarmSettingView.Section: [AlarmSettingView.Setting]])
    }

    struct State {
        var settings: [AlarmSettingView.Section: [AlarmSettingView.Setting]] = [:]
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return .just(.setSettings([
                .management: [
                    .init(id: .wateringReminder, title: "물주기 알림", isOn: false)
                ],
                .community: [
                    .init(id: .favorite, title: "좋아요 알림", isOn: false),
                    .init(id: .comment, title: "댓글 알림", isOn: false)
                ],
                .app: [
                    .init(id: .appNews, title: "앱 소식 알림", isOn: false)
                ]
            ]))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setSettings(let settings):
            newState.settings = settings
        }
        return newState
    }
}
