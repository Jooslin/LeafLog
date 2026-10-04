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
        case loadNextPage
        case selectCategory(PostCategory?)
        case refreshUnreadNotificationState
        case remoteNotificationReceived
    }

    enum Mutation {
        case beginPage(UUID, category: PostCategory?, isRefreshing: Bool)
        case pageFailed(UUID, String)
        case setPosts(
            requestID: UUID,
            offset: Int,
            posts: [CommunityPost],
            likedPostIDs: Set<UUID>,
            authorNicknames: [UUID: String],
            authorProfileImageURLs: [UUID: URL],
            postImageURLs: [UUID: URL]
        )
        case setHasUnreadNotification(Bool)
        case setErrorMessage(String)
    }

    struct State {
        var selectedCategory: PostCategory?
        var posts: [CommunityPost] = []
        var likedPostIDs: Set<UUID> = []
        var authorNicknames: [UUID: String] = [:]
        var authorProfileImageURLs: [UUID: URL] = [:]
        var postImageURLs: [UUID: URL] = [:]
        var hasUnreadNotification = false
        var isRefreshing = false
        var activeRequestID: UUID?
        var isLoadingPage = false
        var hasLoadedPosts = false
        var nextOffset = 0
        var hasMorePages = true
        var feedRevision = 0
        @Pulse var errorMessage: String?
    }

    private static let pageSize = 20
    let initialState = State()

    @Dependency(\.communityPostDBManager) private var communityPostDBManager
    @Dependency(\.notificationDBManager) private var notificationDBManager
    @Dependency(\.supabaseManager) private var supabaseManager
    private let logger = Logger(subsystem: "LeafLog", category: "CommunityReactor")

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return .concat(loadPage(reset: true), refreshUnreadNotificationState())

        case .refresh:
            return loadPage(reset: true, isRefreshing: true)

        case .loadNextPage:
            guard !currentState.isLoadingPage, currentState.hasMorePages else {
                return .empty()
            }
            return loadPage(reset: false)

        case .refreshUnreadNotificationState:
            return refreshUnreadNotificationState()

        case .selectCategory(let category):
            guard category != currentState.selectedCategory else { return .empty() }
            return loadPage(reset: true, category: category)

        case .remoteNotificationReceived:
            return refreshUnreadNotificationState()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case let .beginPage(requestID, category, isRefreshing):
            if category != state.selectedCategory {
                newState.posts = []
                newState.likedPostIDs = []
                newState.authorNicknames = [:]
                newState.authorProfileImageURLs = [:]
                newState.postImageURLs = [:]
                newState.nextOffset = 0
                newState.hasMorePages = true
                newState.hasLoadedPosts = false
                newState.feedRevision += 1
            }
            newState.selectedCategory = category
            newState.activeRequestID = requestID
            newState.isLoadingPage = true
            newState.isRefreshing = isRefreshing

        case let .setPosts(
            requestID,
            offset,
            posts,
            likedPostIDs,
            authorNicknames,
            authorProfileImageURLs,
            postImageURLs
        ):
            // 새로고침이나 카테고리 변경 전에 시작한 요청의 응답은 무시
            guard state.activeRequestID == requestID else { return state }
            if offset == 0 {
                newState.posts = posts
                newState.likedPostIDs = likedPostIDs
                newState.authorNicknames = authorNicknames
                newState.authorProfileImageURLs = authorProfileImageURLs
                newState.postImageURLs = postImageURLs
            } else {
                var existingIDs = Set(state.posts.map(\.id))
                newState.posts += posts.filter { existingIDs.insert($0.id).inserted }
                newState.likedPostIDs.formUnion(likedPostIDs)
                newState.authorNicknames.merge(authorNicknames) { _, new in new }
                newState.authorProfileImageURLs.merge(authorProfileImageURLs) { _, new in new }
                newState.postImageURLs.merge(postImageURLs) { _, new in new }
            }
            // 중복 게시글을 제외했더라도 다음 조회 위치는 서버에서 받은 개수만큼 이동
            newState.nextOffset = offset + posts.count
            newState.hasLoadedPosts = true
            newState.hasMorePages = posts.count == Self.pageSize
            newState.activeRequestID = nil
            newState.isLoadingPage = false
            newState.isRefreshing = false
            newState.feedRevision += 1

        case let .pageFailed(requestID, message):
            guard state.activeRequestID == requestID else { return state }
            newState.activeRequestID = nil
            newState.isLoadingPage = false
            newState.isRefreshing = false
            newState.errorMessage = message

        case .setHasUnreadNotification(let hasUnreadNotification):
            newState.hasUnreadNotification = hasUnreadNotification

        case .setErrorMessage(let message):
            newState.errorMessage = message
        }

        return newState
    }

    private func loadPage(
        reset: Bool,
        isRefreshing: Bool = false
    ) -> Observable<Mutation> {
        loadPage(reset: reset, category: currentState.selectedCategory, isRefreshing: isRefreshing)
    }

    private func loadPage(
        reset: Bool,
        category: PostCategory?,
        isRefreshing: Bool = false
    ) -> Observable<Mutation> {
        let requestID = UUID()
        let offset = reset ? 0 : currentState.nextOffset
        return .concat(
            .just(.beginPage(requestID, category: category, isRefreshing: isRefreshing)),
            fetchPosts(requestID: requestID, offset: offset, category: category)
        )
    }

    private func fetchPosts(
        requestID: UUID,
        offset: Int,
        category: PostCategory?
    ) -> Observable<Mutation> {
        Single<CommunityFeedResult>.create {
            [communityPostDBManager, supabaseManager, logger] in
            let posts = try await communityPostDBManager.fetchPosts(
                limit: Self.pageSize,
                offset: offset,
                category: category
            )
            let likedPostIDs = try await communityPostDBManager.fetchLikedPostIDs(
                postIDs: posts.map(\.id)
            )
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
                likedPostIDs: likedPostIDs,
                authorNicknames: authorNicknames,
                authorProfileImageURLs: authorProfileImageURLs,
                postImageURLs: postImageURLs
            )
        }
        .map {
            .setPosts(
                requestID: requestID,
                offset: offset,
                posts: $0.posts,
                likedPostIDs: $0.likedPostIDs,
                authorNicknames: $0.authorNicknames,
                authorProfileImageURLs: $0.authorProfileImageURLs,
                postImageURLs: $0.postImageURLs
            )
        }
        .asObservable()
        .catch { error in
            let message = (error as? AuthError)?.userMessage
                ?? "게시글을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            return .just(.pageFailed(requestID, message))
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
    let likedPostIDs: Set<UUID>
    let authorNicknames: [UUID: String]
    let authorProfileImageURLs: [UUID: URL]
    let postImageURLs: [UUID: URL]
}
