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
    private var isLoading = false
    private var expectedUserId: UUID?
    private var confirmedValues: [AlarmSettingView.SettingID: Bool] = [:]
    private var pendingChanges: [(AlarmSettingView.SettingID, Bool)] = []
    private var saveTask: Task<Void, Never>?
    private var refreshAfterSave = false

    enum Action {
        case viewWillAppear
        case settingChanged(AlarmSettingView.SettingID, Bool)
        case saveFailed(AlarmSettingView.SettingID, Bool?)
    }

    enum Mutation {
        case setSettings([AlarmSettingView.Section: [AlarmSettingView.Setting]])
        case setValue(AlarmSettingView.SettingID, Bool)
        case saveFailed(AlarmSettingView.SettingID, Bool?)
    }

    struct State {
        var settings: [AlarmSettingView.Section: [AlarmSettingView.Setting]] = [:]
        @Pulse var errorMessage: String?
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            if saveTask != nil {
                refreshAfterSave = true
                return .just(.setSettings([:]))
            }
            return loadSettings()
        case .settingChanged(let id, let isOn):
            guard let userId = expectedUserId,
                  currentState.settings.values.flatMap({ $0 }).contains(where: { $0.id == id && $0.isEnabled }) else {
                return .empty()
            }
            pendingChanges.append((id, isOn))
            startSaving(for: userId)
            return .just(.setValue(id, isOn))
        case .saveFailed(let id, let value):
            return .just(.saveFailed(id, value))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setSettings(let settings):
            newState.settings = settings
        case .setValue(let id, let value):
            for section in [AlarmSettingView.Section.management, .community, .app] {
                if let index = newState.settings[section]?.firstIndex(where: { $0.id == id }) {
                    newState.settings[section]?[index].isOn = value
                }
            }
        case .saveFailed(let id, let value):
            if let value {
                for section in [AlarmSettingView.Section.management, .community, .app] {
                    if let index = newState.settings[section]?.firstIndex(where: { $0.id == id }) {
                        newState.settings[section]?[index].isOn = value
                    }
                }
            }
            newState.errorMessage = "알림 설정을 저장하지 못했습니다."
        }
        return newState
    }

    private func startSaving(for userId: UUID) {
        guard saveTask == nil else { return }
        // 변예린: 토글 변경을 순서대로 저장해 같은 종류의 마지막 선택이 서버에 남도록 한다.
        saveTask = Task {
            while !pendingChanges.isEmpty {
                let (id, isOn) = pendingChanges.removeFirst()
                do {
                    guard await notificationManager.checkNotificationEnabled() else {
                        throw NotificationSaveError.authorizationDisabled
                    }
                    try await supabaseManager.updateCurrentDeviceNotificationPreference(id.preferenceKind, isEnabled: isOn, for: userId)
                    confirmedValues[id] = isOn
                } catch {
                    logger.error("기기별 알림 설정 저장 실패: \(error.localizedDescription, privacy: .private)")
                    let serverValue = try? await supabaseManager.fetchCurrentDeviceNotificationPreferences(for: userId)?.value(for: id.preferenceKind)
                    let restoredValue = serverValue ?? confirmedValues[id]
                    if let restoredValue { confirmedValues[id] = restoredValue }
                    // 변예린: 같은 종류의 후속 선택이 대기 중이면 화면을 이전 값으로 덮지 않는다.
                    let hasLaterChange = pendingChanges.contains { $0.0 == id }
                    action.onNext(.saveFailed(id, hasLaterChange ? nil : restoredValue))
                }

                if supabaseManager.client.auth.currentUser?.id != userId {
                    pendingChanges.removeAll()
                    expectedUserId = nil
                    action.onNext(.viewWillAppear)
                    break
                }
            }
            saveTask = nil
            if refreshAfterSave {
                refreshAfterSave = false
                action.onNext(.viewWillAppear)
            }
        }
    }

    private func loadSettings() -> Observable<Mutation> {
        Observable.create { observer in
            guard !self.isLoading else {
                observer.onCompleted()
                return Disposables.create()
            }
            self.isLoading = true
            self.expectedUserId = nil
            self.confirmedValues.removeAll()
            observer.onNext(.setSettings([:]))

            let task = Task {
                do {
                    var preferences: DeviceNotificationPreferences?
                    if let userId = self.supabaseManager.client.auth.currentUser?.id,
                       let isAuthorized = try await self.notificationManager.syncCurrentDeviceNotificationAuthorization(for: userId),
                       isAuthorized {
                        preferences = try await self.supabaseManager.fetchCurrentDeviceNotificationPreferences(for: userId)
                        if let preferences {
                            self.expectedUserId = userId
                            self.confirmedValues = [
                                .wateringReminder: preferences.isWateringReminderEnabled,
                                .favorite: preferences.isFavoriteEnabled,
                                .comment: preferences.isCommentEnabled,
                                .appNews: preferences.isAppEnabled
                            ]
                        }
                    }

                    observer.onNext(.setSettings(self.settings(for: preferences)))
                } catch {
                    self.logger.error("기기별 알림 설정 조회 실패: \(error.localizedDescription, privacy: .private)")
                    observer.onNext(.setSettings(self.settings(for: nil)))
                }
                observer.onCompleted()
            }

            return Disposables.create {
                task.cancel()
                self.isLoading = false
            }
        }
    }

    private func settings(for preferences: DeviceNotificationPreferences?) -> [AlarmSettingView.Section: [AlarmSettingView.Setting]] {
        [
            .management: [
                .init(id: .wateringReminder, title: "물주기 알림", isOn: preferences?.isWateringReminderEnabled ?? false, isEnabled: preferences != nil)
            ],
            .community: [
                .init(id: .favorite, title: "좋아요 알림", isOn: preferences?.isFavoriteEnabled ?? false, isEnabled: preferences != nil),
                .init(id: .comment, title: "댓글 알림", isOn: preferences?.isCommentEnabled ?? false, isEnabled: preferences != nil)
            ],
            .app: [
                .init(id: .appNews, title: "앱 소식 알림", isOn: preferences?.isAppEnabled ?? false, isEnabled: preferences != nil)
            ]
        ]
    }
}

private enum NotificationSaveError: Error {
    case authorizationDisabled
}

private extension AlarmSettingView.SettingID {
    var preferenceKind: DeviceNotificationPreferenceKind {
        switch self {
        case .wateringReminder: .wateringReminder
        case .favorite: .favorite
        case .comment: .comment
        case .appNews: .appNews
        }
    }
}
