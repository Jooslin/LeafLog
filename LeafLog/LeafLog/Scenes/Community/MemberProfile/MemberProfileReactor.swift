//
//  MemberProfileReactor.swift
//  LeafLog
//
//  Created by Yeseul Jang on 8/5/26.
//

import Foundation
import Dependencies
import OSLog
import ReactorKit
import RxSwift
import Supabase

final class MemberProfileReactor: Reactor {
    private let memberID: UUID
    
    struct Profile: Equatable {
        let nickname: String
        let profileImageURL: URL?
        let postCount: String
        let likeCount: String
    }
    
    struct Post: Equatable {
        let id: UUID
        let title: String
        let nickname: String
        let date: String
        let body: String
        let imageURL: URL?
        let likeCount: String
        let commentCount: String
    }
    
    enum PostListItem: Equatable {
        case post(Post)
        case empty
    }
    
    enum Ownership: Equatable {
        case unknown
        case mine
        case visitor
    }
    
    enum Action {
        case viewDidLoad
        case moreButtonTapped
        case reportReasonSelected(CommunityReportReason)
        case sortButtonTapped
        case reachedBottom
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setInitialLoading(Bool)
        case setLoadingMore(Bool)
        case setReporting(Bool)
        case setProfile(Profile)
        case setOwnership(Ownership)
        case setPosts([Post], nextOffset: Int?, hasNextPage: Bool)
        case appendPosts([Post], nextOffset: Int?, hasNextPage: Bool)
        case resetPosts
        case presentMemberActionSheet
        case presentReportCompletedAlert
        case setErrorMessage(String)
    }
    
    struct State {
        var isLoading = false
        var isInitialLoading = true
        var isLoadingMore = false
        var isReporting = false
        var hasNextPage = false
        var nextOffset: Int?
        var profile: Profile?
        var posts: [Post] = []
        var ownership: Ownership = .unknown
        @Pulse var memberActionSheet: Bool?
        @Pulse var reportCompleted: Bool?
        @Pulse var errorMessage: String?
        
        var shouldShowMoreButton: Bool {
            ownership == .visitor
        }
        
        var postListItems: [PostListItem] {
            if isInitialLoading {
                return []
            }
            
            if posts.isEmpty {
                return [.empty]
            }
            
            return posts.map { .post($0) }
        }
    }
    
    let initialState = State()
    private let pageSize = 10
    
    @Dependency(\.communityPostDBManager) private var communityPostDBManager
    @Dependency(\.communityReportDBManager) private var communityReportDBManager
    @Dependency(\.supabaseManager) private var supabaseManager
    private let logger = Logger(subsystem: "LeafLog", category: "MemberProfileReactor")
    
    init(memberID: UUID) {
        self.memberID = memberID
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .concat(
                .just(.setInitialLoading(true)),
                fetchInitialProfile(),
                .just(.setInitialLoading(false))
            )
            
        case .moreButtonTapped:
            guard currentState.ownership == .visitor else { return .empty() }
            return .just(.presentMemberActionSheet)
            
        case .reportReasonSelected(let reason):
            guard currentState.ownership == .visitor,
                  currentState.isReporting == false else {
                return .empty()
            }
            
            return .concat(
                .just(.setReporting(true)),
                reportMember(reason: reason),
                .just(.setReporting(false))
            )
            
        case .sortButtonTapped:
            return .empty()
            
        case .reachedBottom:
            guard currentState.isInitialLoading == false,
                  currentState.isLoadingMore == false,
                  currentState.hasNextPage,
                  let nextOffset = currentState.nextOffset else {
                return .empty()
            }
            
            return .concat(
                .just(.setLoadingMore(true)),
                fetchMorePosts(offset: nextOffset),
                .just(.setLoadingMore(false))
            )
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
            
        case .setInitialLoading(let isInitialLoading):
            newState.isInitialLoading = isInitialLoading
            
        case .setLoadingMore(let isLoadingMore):
            newState.isLoadingMore = isLoadingMore
            
        case .setReporting(let isReporting):
            newState.isReporting = isReporting
            
        case .setProfile(let profile):
            newState.profile = profile
            
        case .setOwnership(let ownership):
            newState.ownership = ownership
            
        case .setPosts(let posts, let nextOffset, let hasNextPage):
            newState.posts = posts
            newState.nextOffset = nextOffset
            newState.hasNextPage = hasNextPage
            
        case .appendPosts(let posts, let nextOffset, let hasNextPage):
            newState.posts.append(contentsOf: posts)
            newState.nextOffset = nextOffset
            newState.hasNextPage = hasNextPage
            
        case .resetPosts:
            newState.posts = []
            newState.nextOffset = nil
            newState.hasNextPage = false
            
        case .presentMemberActionSheet:
            newState.memberActionSheet = true
            
        case .presentReportCompletedAlert:
            newState.reportCompleted = true
            
        case .setErrorMessage(let message):
            newState.errorMessage = message
        }
        
        return newState
    }
    
    private func fetchInitialProfile() -> Observable<Mutation> {
        Single<MemberProfileResult>.create { [communityPostDBManager, supabaseManager, logger, memberID, pageSize] in
            let currentUserID = supabaseManager.client.auth.currentUser?.id
            let profiles = try await communityPostDBManager.fetchPublicProfiles(authorIDs: [memberID])
            let profile = profiles[memberID]
            let profileImageURLs = await communityPostDBManager.resolvePublicProfileImageURLs(profiles: profiles)
            let stats = try await communityPostDBManager.fetchPostStats(authorID: memberID)
            let posts = try await communityPostDBManager.fetchPosts(
                authorID: memberID,
                limit: pageSize,
                offset: 0
            )
            let postImageURLs = await Self.resolvePostImageURLs(
                posts: posts,
                supabaseManager: supabaseManager,
                logger: logger
            )
            
            return MemberProfileResult(
                profile: Profile(
                    nickname: profile?.nickname ?? "알 수 없는 사용자",
                    profileImageURL: profileImageURLs[memberID],
                    postCount: String(stats.postCount),
                    likeCount: String(stats.likeCount)
                ),
                posts: Self.makePosts(posts, nickname: profile?.nickname ?? "알 수 없는 사용자", imageURLs: postImageURLs),
                ownership: memberID == currentUserID ? .mine : .visitor,
                nextOffset: posts.count,
                hasNextPage: posts.count == pageSize
            )
        }
        .asObservable()
        .flatMap { result -> Observable<Mutation> in
            .from([
                .setOwnership(result.ownership),
                .setProfile(result.profile),
                .setPosts(
                    result.posts,
                    nextOffset: result.nextOffset,
                    hasNextPage: result.hasNextPage
                )
            ])
        }
        .catch { error in
            let message = (error as? AuthError)?.userMessage
                ?? "작성자 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            return .just(.setErrorMessage(message))
        }
    }
    
    private func fetchMorePosts(offset: Int) -> Observable<Mutation> {
        Single<MemberProfilePostsPage>.create { [communityPostDBManager, supabaseManager, logger, memberID, pageSize, currentState] in
            let posts = try await communityPostDBManager.fetchPosts(
                authorID: memberID,
                limit: pageSize,
                offset: offset
            )
            let postImageURLs = await Self.resolvePostImageURLs(
                posts: posts,
                supabaseManager: supabaseManager,
                logger: logger
            )
            let nickname = currentState.profile?.nickname ?? "알 수 없는 사용자"
            
            return MemberProfilePostsPage(
                posts: Self.makePosts(posts, nickname: nickname, imageURLs: postImageURLs),
                nextOffset: offset + posts.count,
                hasNextPage: posts.count == pageSize
            )
        }
        .map {
            .appendPosts(
                $0.posts,
                nextOffset: $0.nextOffset,
                hasNextPage: $0.hasNextPage
            )
        }
        .asObservable()
        .catch { error in
            let message = (error as? AuthError)?.userMessage
                ?? "게시글을 더 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            return .just(.setErrorMessage(message))
        }
    }
    
    private func reportMember(reason: CommunityReportReason) -> Observable<Mutation> {
        Single<Bool>.create { [communityReportDBManager, memberID] in
            try await communityReportDBManager.reportMember(
                reportedUserID: memberID,
                reason: reason
            )
            return true
        }
        .map { _ in .presentReportCompletedAlert }
        .asObservable()
        .catch { error in
            let message = (error as? AuthError)?.userMessage
                ?? "신고를 접수하지 못했어요. 잠시 후 다시 시도해주세요."
            return .just(.setErrorMessage(message))
        }
    }
    
    nonisolated private static func makePosts(
        _ posts: [CommunityPost],
        nickname: String,
        imageURLs: [UUID: URL]
    ) -> [Post] {
        posts.map {
            Post(
                id: $0.id,
                title: $0.title,
                nickname: nickname,
                date: dateFormatter.string(from: $0.createdAt),
                body: $0.content,
                imageURL: imageURLs[$0.id],
                likeCount: String($0.likeCount),
                commentCount: String($0.commentCount ?? 0)
            )
        }
    }
    
    private static func resolvePostImageURLs(
        posts: [CommunityPost],
        supabaseManager: SupabaseManager,
        logger: Logger
    ) async -> [UUID: URL] {
        var imageURLs: [UUID: URL] = [:]
        
        for post in posts {
            guard let imagePath = post.firstImagePath else { continue }
            
            do {
                if let imageURL = try await supabaseManager.resolveCommunityPostImageURL(
                    from: imagePath,
                    cacheKey: post.id.uuidString
                ) {
                    imageURLs[post.id] = imageURL
                }
            } catch {
                logger.error(
                    "Member profile post image URL resolution failed. postID: \(post.id.uuidString, privacy: .public), error: \(String(describing: error), privacy: .private)"
                )
            }
        }
        
        return imageURLs
    }
    
    nonisolated private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}

private struct MemberProfileResult {
    let profile: MemberProfileReactor.Profile
    let posts: [MemberProfileReactor.Post]
    let ownership: MemberProfileReactor.Ownership
    let nextOffset: Int
    let hasNextPage: Bool
}

private struct MemberProfilePostsPage {
    let posts: [MemberProfileReactor.Post]
    let nextOffset: Int
    let hasNextPage: Bool
}
