//
//  CommunityReactor.swift
//  LeafLog
//
//  Created by 김주희 on 8/19/26.
//

import Dependencies
import Foundation
import OSLog
import ReactorKit

final class CommunityReactor: Reactor {
    enum Action {
        case viewWillAppear
        case refresh
        case selectCategory(PostCategory?)
        case refreshUnreadNotificationState
        case remoteNotificationReceived
    }

    enum Mutation {
        case setPosts(
            posts: [CommunityPost],
            authorNicknames: [UUID: String],
            authorProfileImageURLs: [UUID: URL],
            postImageURLs: [UUID: URL]
        )
        case setRefreshing(Bool)
        case setSelectedCategory(PostCategory?)
        case setHasUnreadNotification(Bool)
        case setErrorMessage(String)
    }

    struct State {
        var allPosts: [CommunityPost] = []
        var selectedCategory: PostCategory?
        var posts: [CommunityPost] = []
        var authorNicknames: [UUID: String] = [:]
        var authorProfileImageURLs: [UUID: URL] = [:]
        var postImageURLs: [UUID: URL] = [:]
        var hasUnreadNotification = false
        var isRefreshing = false
        @Pulse var errorMessage: String?
    }

    let initialState = State()

    @Dependency(\.communityPostDBManager) private var communityPostDBManager
    @Dependency(\.notificationDBManager) private var notificationDBManager
    @Dependency(\.supabaseManager) private var supabaseManager
    private let logger = Logger(subsystem: "LeafLog", category: "CommunityReactor")

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return .concat(fetchPosts(), refreshUnreadNotificationState())

        case .refresh:
            return .concat(
                .just(.setRefreshing(true)),
                fetchPosts(),
                .just(.setRefreshing(false))
            )

        case .refreshUnreadNotificationState:
            return refreshUnreadNotificationState()

        case .selectCategory(let category):
            return .just(.setSelectedCategory(category))

        case .remoteNotificationReceived:
            return refreshUnreadNotificationState()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case let .setPosts(
            posts,
            authorNicknames,
            authorProfileImageURLs,
            postImageURLs
        ):
            newState.allPosts = posts
            newState.posts = newState.selectedCategory.map { category in
                posts.filter { $0.category == category }
            } ?? posts
            newState.authorNicknames = authorNicknames
            newState.authorProfileImageURLs = authorProfileImageURLs
            newState.postImageURLs = postImageURLs

        case .setRefreshing(let isRefreshing):
            newState.isRefreshing = isRefreshing

        case .setSelectedCategory(let category):
            newState.selectedCategory = category
            newState.posts = category.map { selectedCategory in
                state.allPosts.filter { $0.category == selectedCategory }
            } ?? state.allPosts

        case .setHasUnreadNotification(let hasUnreadNotification):
            newState.hasUnreadNotification = hasUnreadNotification

        case .setErrorMessage(let message):
            newState.errorMessage = message
        }

        return newState
    }

    private func fetchPosts() -> Observable<Mutation> {
        Single<CommunityFeedResult>.create {
            [communityPostDBManager, supabaseManager, logger] in
            let posts = try await communityPostDBManager.fetchPosts()
            let publicProfiles = try await communityPostDBManager.fetchPublicProfiles(
                authorIDs: posts.map(\.authorID)
            )
            let authorNicknames = publicProfiles.compactMapValues(\.nickname)
            let authorProfileImageURLs = await communityPostDBManager
                .resolvePublicProfileImageURLs(profiles: publicProfiles)

            var postImageURLs: [UUID: URL] = [:]
            for post in posts {
                guard let imagePath = post.firstImagePath else { continue }

                do {
                    if let imageURL = try await supabaseManager.resolveCommunityPostImageURL(
                        from: imagePath,
                        cacheKey: post.id.uuidString
                    ) {
                        postImageURLs[post.id] = imageURL
                    }
                } catch {
                    logger.error(
                        "Community post image URL resolution failed. postID: \(post.id.uuidString, privacy: .public), error: \(String(describing: error), privacy: .private)"
                    )
                }
            }

            return CommunityFeedResult(
                posts: posts,
                authorNicknames: authorNicknames,
                authorProfileImageURLs: authorProfileImageURLs,
                postImageURLs: postImageURLs
            )
        }
        .map {
            .setPosts(
                posts: $0.posts,
                authorNicknames: $0.authorNicknames,
                authorProfileImageURLs: $0.authorProfileImageURLs,
                postImageURLs: $0.postImageURLs
            )
        }
        .asObservable()
        .catch { error in
            let message = (error as? AuthError)?.userMessage
                ?? "게시글을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            return .just(.setErrorMessage(message))
        }
    }

    private func refreshUnreadNotificationState() -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            let task = Task { [weak self] in
                guard let self else {
                    observer.onCompleted()
                    return
                }

                do {
                    let hasUnreadNotification =
                        try await self.notificationDBManager.hasUnreadNotifications()
                    observer.onNext(.setHasUnreadNotification(hasUnreadNotification))
                } catch {
                    // 알림 조회 실패는 커뮤니티 목록 표시를 막지 않습니다.
                }

                observer.onCompleted()
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
}

nonisolated private struct CommunityFeedResult: Sendable {
    let posts: [CommunityPost]
    let authorNicknames: [UUID: String]
    let authorProfileImageURLs: [UUID: URL]
    let postImageURLs: [UUID: URL]
}
