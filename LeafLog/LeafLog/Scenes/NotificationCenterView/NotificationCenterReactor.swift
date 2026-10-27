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
        case viewWillDisappear
        case refresh
        case categorySelected(Int)
        case loadNextPage
        case notificationDisplayed(NotificationCenterView.Alarm)
        case notificationSelected(NotificationCenterView.Alarm)
    }

    enum Mutation {
        case setAlarm(
            category: AppNotificationCategory,
            items: [NotificationCenterView.Item],
            nextCursor: NotificationDBManager.Cursor?,
            hasMore: Bool,
            generation: Int
        )
        case appendAlarm(
            items: [NotificationCenterView.Item],
            nextCursor: NotificationDBManager.Cursor?,
            hasMore: Bool,
            generation: Int
        )
        case setCategorySelectionLoading(Bool)
        case openPost(UUID)
        case error(String)
    }
    
    struct State {
        var alarmItem: [NotificationCenterView.Item] = []
        var category: AppNotificationCategory
        var nextCursor: NotificationDBManager.Cursor?
        var hasMore = false
        var listVersion = 0
        var isCategorySelectionLoading = false
        @Pulse var selectedPostID: UUID?
        @Pulse var errorMessage: String?
    }
    
    let initialState: State

    init(category: AppNotificationCategory) {
        self.initialState = State(category: category)
    }
    
    //MARK: properties
    @Dependency(\.notificationDBManager) private var notificationDBManager
    @Dependency(\.communityPostDBManager) private var communityPostDBManager
    private let logger = Logger(subsystem: "LeafLog", category: "NotificationCenterReactor")
    private let calendar = Calendar.current
    private var loadGeneration = 0
    private var isReloading = false
    private var isLoadingNextPage = false
    private var isVisible = false
    private var displayedUnreadIDs: [AppNotificationCategory: Set<UUID>] = [:]
    private var pendingReadTask: Task<Void, Never>?
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            isVisible = true
            let category = currentState.category

            return reloadNotifications(category: category)
                .take(until: differentCategorySelected(from: category))

        case .viewWillDisappear:
            isVisible = false
            loadGeneration += 1
            isReloading = false
            isLoadingNextPage = false
            markDisplayedNotificationsAsRead()
            return .empty()
            
        case .refresh:
            guard !currentState.isCategorySelectionLoading else {
                return .empty()
            }

            let category = currentState.category

            return reloadNotifications(category: category)
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
                reloadNotifications(category: category),
                .just(.setCategorySelectionLoading(false))
            ])
            .take(until: differentCategorySelected(from: category))

        case .loadNextPage:
            guard !isReloading, !isLoadingNextPage,
                  currentState.hasMore, let cursor = currentState.nextCursor else {
                return .empty()
            }

            isLoadingNextPage = true
            return notifications(
                category: currentState.category,
                cursor: cursor,
                generation: loadGeneration,
                append: true
            )

        case .notificationDisplayed(let alarm):
            guard isVisible, alarm.isUnread else { return .empty() }
            displayedUnreadIDs[alarm.category, default: []].insert(alarm.id)
            return .empty()

        case .notificationSelected(let alarm):
            guard alarm.category == .community else { return .empty() }
            return openPost(alarm.postID)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case let .setAlarm(category, items, nextCursor, hasMore, generation):
            guard generation == loadGeneration else { return state }
            newState.category = category
            newState.alarmItem = items
            newState.nextCursor = nextCursor
            newState.hasMore = hasMore
            newState.listVersion += 1

        case let .appendAlarm(items, nextCursor, hasMore, generation):
            guard generation == loadGeneration else { return state }
            newState.alarmItem.append(contentsOf: items)
            newState.nextCursor = nextCursor
            newState.hasMore = hasMore

        case .setCategorySelectionLoading(let isLoading):
            newState.isCategorySelectionLoading = isLoading

        case .openPost(let postID):
            newState.selectedPostID = postID
            
        case .error(let message):
            newState.errorMessage = message
        }
        
        return newState
    }
}

extension NotificationCenterReactor {
    private func reloadNotifications(category: AppNotificationCategory) -> Observable<Mutation> {
        loadGeneration += 1
        isReloading = true
        isLoadingNextPage = false
        return notifications(category: category, cursor: nil, generation: loadGeneration, append: false)
    }

    private func notifications(
        category: AppNotificationCategory,
        cursor: NotificationDBManager.Cursor?,
        generation: Int,
        append: Bool
    ) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            let task = Task { [weak self] in
                guard let self else {
                    observer.onCompleted()
                    return
                }

                defer {
                    if generation == self.loadGeneration {
                        if append {
                            self.isLoadingNextPage = false
                        } else {
                            self.isReloading = false
                        }
                    }
                }
                
                do {
                    await self.pendingReadTask?.value
                    try Task.checkCancellation()
                    guard generation == self.loadGeneration else {
                        observer.onCompleted()
                        return
                    }

                    let now = Date()
                    let page = try await self.notificationDBManager.fetchMyNotifications(
                        category: category,
                        cursor: cursor
                    )
                    let notifications = page.notifications
                    let postTitles = category == .community
                        ? try await self.communityPostDBManager.fetchPostTitles(
                            postIDs: notifications.compactMap(\.metadata.postID)
                        )
                        : [:]

                    try Task.checkCancellation()
                    guard generation == self.loadGeneration else {
                        observer.onCompleted()
                        return
                    }
                    let groups = category == .community
                        ? try await self.notificationDBManager.fetchCommunityNotificationGroups(
                            notificationIDs: notifications.map(\.id)
                        )
                        : [:]

                    try Task.checkCancellation()
                    guard generation == self.loadGeneration else {
                        observer.onCompleted()
                        return
                    }
                    
                    let items = notifications.map { notification in
                        let time = self.calculateExcessAlarmTime(from: notification.sentAt ?? notification.createdAt, to: now)
                        let timeString = time > 24 ? "\(Int(time / 24))일 전" : "\(Int(time))시간 전"
                        let totalText = groups[notification.id].flatMap {
                            self.communityTotalText(group: $0, type: notification.type)
                        }
                        
                        let alarm = NotificationCenterView.Alarm(
                            id: notification.id,
                            postID: notification.metadata.postID,
                            title: notification.title,
                            body: category == .community
                                ? (notification.metadata.postID.flatMap { postTitles[$0] } ?? notification.body)
                                : (notification.plantNamesText ?? notification.body),
                            totalText: totalText,
                            category: notification.category,
                            detailCategory: notification.type,
                            sentTimeLabel: timeString,
                            isUnread: !notification.isRead
                        )
                        
                        let item = NotificationCenterView.Item.alarm(alarm)
                        
                        return item
                    }
                    
                    if append {
                        observer.onNext(.appendAlarm(
                            items: items,
                            nextCursor: page.nextCursor,
                            hasMore: page.hasMore,
                            generation: generation
                        ))
                    } else {
                        observer.onNext(.setAlarm(
                            category: category,
                            items: items,
                            nextCursor: page.nextCursor,
                            hasMore: page.hasMore,
                            generation: generation
                        ))
                    }

                    observer.onCompleted()
                } catch let error as AuthError {
                    if generation == self.loadGeneration {
                        observer.onNext(.error(error.userMessage))
                    }
                    observer.onCompleted()
                } catch is CancellationError {
                    self.logger.debug("알림 조회 Task가 취소되었습니다.")
                    observer.onCompleted()
                } catch {
                    self.logger.error("알 수 없는 에러: \(error.localizedDescription)")
                    if generation == self.loadGeneration {
                        observer.onNext(.error("알 수 없는 오류입니다. 잠시 후 다시 시도해주세요."))
                    }
                    observer.onCompleted()
                }
            }
            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func markDisplayedNotificationsAsRead() {
        let idsByCategory = displayedUnreadIDs
        displayedUnreadIDs.removeAll()
        guard !idsByCategory.isEmpty else { return }

        let previousTask = pendingReadTask
        let notificationDBManager = notificationDBManager
        let logger = logger
        pendingReadTask = Task {
            await previousTask?.value
            for category in [AppNotificationCategory.management, .community] {
                guard let ids = idsByCategory[category], !ids.isEmpty else { continue }
                do {
                    try await notificationDBManager.markAsRead(notificationIDs: Array(ids), category: category)
                    NotificationCenter.default.post(name: .leafLogNotificationReadStateChanged, object: nil)
                } catch {
                    logger.error("표시된 알림 읽음 처리 실패: \(error.localizedDescription, privacy: .private)")
                }
            }
        }
    }

    private func communityTotalText(group: CommunityNotificationGroup, type: AppNotificationType) -> String? {
        let action: String
        switch type {
        case .favorite:
            action = "좋아요를 눌렀어요."
        case .comment:
            action = "댓글을 남겼어요."
        default:
            return nil
        }

        let otherCount = group.participantIDs.count - 1
        if otherCount > 0 {
            return "\(group.firstActorNickname)님 외 \(otherCount)명이 \(action)"
        }
        return "\(group.firstActorNickname)님이 \(action)"
    }

    private func openPost(_ postID: UUID?) -> Observable<Mutation> {
        guard let postID else {
            return .just(.error("해당 게시물을 불러올 수 없습니다."))
        }

        return Observable.create { [weak self] observer in
            let task = Task { [weak self] in
                guard let self else {
                    observer.onCompleted()
                    return
                }

                do {
                    let titles = try await self.communityPostDBManager.fetchPostTitles(postIDs: [postID])
                    if titles[postID] != nil {
                        observer.onNext(.openPost(postID))
                    } else {
                        observer.onNext(.error("해당 게시물을 불러올 수 없습니다."))
                    }
                } catch let error as AuthError {
                    observer.onNext(.error(error.userMessage))
                } catch {
                    observer.onNext(.error("게시글을 불러오지 못했어요. 잠시 후 다시 시도해주세요."))
                }

                observer.onCompleted()
            }

            return Disposables.create { task.cancel() }
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
