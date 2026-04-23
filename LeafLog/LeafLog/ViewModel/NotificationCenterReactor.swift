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
    }
    
    enum Mutation {
        case setAlarm([NotificationCenterView.Item])
        case error(String)
    }
    
    struct State {
        var alarmItem: [NotificationCenterView.Item] = []
        @Pulse var errorMessage: String?
    }
    
    let initialState = State()
    
    //MARK: properties
    @Dependency(\.notificationDBManager) private var notificationDBManager
    private let logger = Logger(subsystem: "LeafLog", category: "NotificationCenterReactor")
    private let calendar = Calendar.current
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return notifications()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setAlarm(let items):
            newState.alarmItem = items
        case .error(let message):
            newState.errorMessage = message
        }
        
        return newState
    }
}

extension NotificationCenterReactor {
    private func notifications() -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            
            let task = Task {
                do {
                    let now = Date()
                    let notifications = try await self.notificationDBManager.fetchMyNotifications()
                    
                    let items = notifications.reduce([NotificationCenterView.Item]()) {
                        let time = self.calculateExcessAlarmTime(from: $1.sentAt, to: now)
                        
                        let timeString = time > 24 ? "\(Int(time / 24))일 전" : "\(Int(time))시간 전"
                        
                        let alarm = NotificationCenterView.Alarm(
                            id: $1.id,
                            title: $1.title,
                            body: $1.plantNamesText ?? "",
                            category: $1.category,
                            sentTimeLabel: timeString
                        )
                        
                        let item = NotificationCenterView.Item.alarm(alarm)
                        
                        return $0 + [item]
                    }
                    
                    observer.onNext(.setAlarm(items))
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.error(error.userMessage))
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
}

extension NotificationCenterReactor {
    private func calculateExcessAlarmTime(from date: Date?, to now: Date) -> Double {
        guard let date else { return -1 }
        
        let distance = date.distance(to: now) // 초단위의 두 날짜간 간격
        
        return distance / 3600 // 시간 단위로 반환
    }
}
