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
import OSLog

final class NotificationCenterReactor: Reactor {
    enum Action {
        case viewWillAppear
        case refresh
        case categorySelected(Int)
    }

    enum Mutation {
        case setAlarm(
            category: AppNotificationCategory,
            items: [NotificationCenterView.Item]
        )
        case setCategorySelectionLoading(Bool)
        case error(String)
    }
    
    struct State {
        var alarmItem: [NotificationCenterView.Item] = []
        var category: AppNotificationCategory
        var isCategorySelectionLoading = false
        @Pulse var errorMessage: String?
    }
    
    let initialState: State

    init(category: AppNotificationCategory) {
        self.initialState = State(category: category)
    }
    
    //MARK: properties
    @Dependency(\.notificationDBManager) private var notificationDBManager
    private let logger = Logger(subsystem: "LeafLog", category: "NotificationCenterReactor")
    private let calendar = Calendar.current
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            let category = currentState.category

            return notifications(category: category)
                .take(until: differentCategorySelected(from: category))
            
        case .refresh:
            guard !currentState.isCategorySelectionLoading else {
                return .empty()
            }

            let category = currentState.category

            return notifications(category: category)
                .take(until: differentCategorySelected(from: category))
            
        case .categorySelected(let index):
            guard let category = AppNotificationCategory(segmentIndex: index) else {
                return .empty()
            }

            if category == currentState.category {
                guard currentState.isCategorySelectionLoading else {
                    return .empty()
                }

                return .just(.setCategorySelectionLoading(false))
            }

            return Observable.concat([
                .just(.setCategorySelectionLoading(true)),
                notifications(category: category),
                .just(.setCategorySelectionLoading(false))
            ])
            .take(until: differentCategorySelected(from: category))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case let .setAlarm(category, items):
            newState.category = category
            newState.alarmItem = items

        case .setCategorySelectionLoading(let isLoading):
            newState.isCategorySelectionLoading = isLoading
            
        case .error(let message):
            newState.errorMessage = message
        }
        
        return newState
    }
}

extension NotificationCenterReactor {
    private func notifications(category: AppNotificationCategory) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            let task = Task { [weak self] in
                guard let self else {
                    observer.onCompleted()
                    return
                }
                
                do {
                    let now = Date()
                    let notifications = try await self.notificationDBManager.fetchMyNotifications(category: category)
                    
                    let items = notifications.map {
                        let time = self.calculateExcessAlarmTime(from: $0.sentAt, to: now)
                        let timeString = time > 24 ? "\(Int(time / 24))일 전" : "\(Int(time))시간 전"
                        
                        let alarm = NotificationCenterView.Alarm(
                            id: $0.id,
                            title: $0.title,
                            body: $0.plantNamesText ?? $0.body,
                            category: $0.category,
                            sentTimeLabel: timeString
                        )
                        
                        let item = NotificationCenterView.Item.alarm(alarm)
                        
                        return item
                    }
                    
                    observer.onNext(.setAlarm(category: category, items: items))

                    do {
                        try await self.notificationDBManager.markAllAsRead()
                        NotificationCenter.default.post(name: .leafLogNotificationReadStateChanged, object: nil)
                    } catch {
                        self.logger.error("알림 전체 읽음 처리 실패: \(error.localizedDescription, privacy: .private)")
                    }

                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.error(error.userMessage))
                    observer.onCompleted()
                } catch is CancellationError {
                    self.logger.debug("알림 조회 Task가 취소되었습니다.")
                    observer.onCompleted()
                } catch {
                    self.logger.error("알 수 없는 에러: \(error.localizedDescription)")
                    observer.onNext(.error("알 수 없는 오류입니다. 잠시 후 다시 시도해주세요."))
                    observer.onCompleted()
                }
            }
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    // 카테고리 조회 여부 판단
    // - inFlightCategory: 기존에 알람을 조회중인 카테고리
    // - $0: 선택된 카테고리
    // -> 기존 카테고리와 선택된 카테고리가 동일할 경우에는 반환값이 없음
    // -> 상이할 경우에만 반환값 있음: 기존 진행중이던 조회 task를 취소
    private func differentCategorySelected(
        from inFlightCategory: AppNotificationCategory
    ) -> Observable<AppNotificationCategory> {
        action
            .compactMap { action in
                guard case .categorySelected(let index) = action else {
                    return nil
                }

                return AppNotificationCategory(segmentIndex: index)
            }
            .filter { $0 != inFlightCategory }
    }
}

extension NotificationCenterReactor {
    private func calculateExcessAlarmTime(from date: Date?, to now: Date) -> Double {
        guard let date else { return -1 }
        
        let distance = date.distance(to: now) // 초단위의 두 날짜간 간격
        
        return distance / 3600 // 시간 단위로 반환
    }
}
