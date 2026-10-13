//
//  AlarmSettingReactor.swift
//  LeafLog
//
//  Created by 변예린 on 10/7/26.
//

import Dependencies
import OSLog
import ReactorKit
import RxSwift
import Supabase

final class AlarmSettingReactor: Reactor {
    @Dependency(\.notificationManager) private var notificationManager
    @Dependency(\.supabaseManager) private var supabaseManager
    private let logger = Logger(subsystem: "LeafLog", category: "AlarmSettingReactor")

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
            return loadSettings()
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

    private func loadSettings() -> Observable<Mutation> {
        Observable.create { observer in
            observer.onNext(.setSettings([:]))

            let task = Task {
                do {
                    var preferences: DeviceNotificationPreferences?
                    if let userId = self.supabaseManager.client.auth.currentUser?.id,
                       let isAuthorized = try await self.notificationManager.syncCurrentDeviceNotificationAuthorization(for: userId),
                       isAuthorized {
                        preferences = try await self.supabaseManager.fetchCurrentDeviceNotificationPreferences(for: userId)
                    }

                    observer.onNext(.setSettings(self.settings(for: preferences)))
                } catch {
                    self.logger.error("기기별 알림 설정 조회 실패: \(error.localizedDescription, privacy: .private)")
                    observer.onNext(.setSettings(self.settings(for: nil)))
                }
                observer.onCompleted()
            }

            return Disposables.create { task.cancel() }
        }
    }

    private func settings(for preferences: DeviceNotificationPreferences?) -> [AlarmSettingView.Section: [AlarmSettingView.Setting]] {
        [
            .management: [
                .init(id: .wateringReminder, title: "물주기 알림", isOn: preferences?.isWateringReminderEnabled ?? false)
            ],
            .community: [
                .init(id: .favorite, title: "좋아요 알림", isOn: preferences?.isFavoriteEnabled ?? false),
                .init(id: .comment, title: "댓글 알림", isOn: preferences?.isCommentEnabled ?? false)
            ],
            .app: [
                .init(id: .appNews, title: "앱 소식 알림", isOn: preferences?.isAppEnabled ?? false)
            ]
        ]
    }
}
