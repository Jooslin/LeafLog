//
//  CommunityDetailReactor.swift
//  LeafLog
//
//  Created by Yeseul Jang on 7/9/26.
//

import Dependencies
import Foundation
import OSLog
import ReactorKit
import RxSwift
import Supabase

final class CommunityDetailReactor: Reactor {
    struct PostImageSlot: Equatable, Sendable {
        let originalIndex: Int
        let imageURL: URL?
    }
    
    struct Post: Equatable {
        let id: UUID
        let memberID: UUID
        let category: String
        let title: String
        let nickname: String
        let profileImageURL: URL?
        let date: String
        let body: String
        let imageSlots: [PostImageSlot]
        let likeCount: String
        let commentCount: String
        var isLiked: Bool
        let isMine: Bool
    }
    
    struct Comment: Equatable {
        let memberID: UUID
        let nickname: String
        let date: String
        let body: String
        let badge: CommentBadge
    }
    
    struct ImageViewerRoute: Equatable {
        let imageSlots: [PostImageSlot]
        let initialIndex: Int
    }
    
    enum PostActionSheetKind: Equatable {
        case owner
        case visitor
    }
    
    enum CommentBadge: Equatable {
        case author
        case mine
        case none
    }
    
    enum Action {
        case viewDidLoad
        case moreButtonTapped
        case postImageTapped(index: Int)
        case postProfileImageTapped
        case commentProfileImageTapped(index: Int)
        case heartButtonTapped
        case commentButtonTapped
        case sendButtonTapped
        case reportReasonSelected(CommunityReportReason)
        case reachedBottom
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setPost(Post)
        case setReporting(Bool)
        case setLoadingMoreComments(Bool)
        case appendComments([Comment], nextCursor: String?, hasNextPage: Bool)
        case setPostLiked(Bool)
        case presentPostActionSheet(PostActionSheetKind)
        case presentImageViewer(ImageViewerRoute)
        case routeToMemberProfile(memberID: UUID)
        case presentReportCompletedAlert
        case setErrorMessage(String)
    }
    
    struct State {
        var isLoading = false
        var isReporting = false
        var isLoadingMoreComments = false
        var hasNextCommentPage = false
        var nextCommentCursor: String?
        @Pulse var postActionSheetKind: PostActionSheetKind?
        @Pulse var imageViewerRoute: ImageViewerRoute?
        @Pulse var memberProfileRoute: UUID?
        @Pulse var reportCompleted: Bool?
        @Pulse var errorMessage: String?
        var post: Post?
        var comments: [Comment] = [
            .init(
                memberID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                nickname: "닉네임임",
                date: "2026.04.27",
                body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
                badge: .none
            ),
            .init(
                memberID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                nickname: "닉네임임",
                date: "2026.04.27",
                body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
                badge: .author
            ),
            .init(
                memberID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                nickname: "닉네임임",
                date: "2026.04.27",
                body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
                badge: .mine
            ),
            .init(
                memberID: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                nickname: "닉네임임",
                date: "2026.04.27",
                body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
                badge: .none
            )
        ]
    }
    
    let initialState: State
    
    @Dependency(\.communityPostDBManager) private var communityPostDBManager
    @Dependency(\.communityReportDBManager) private var communityReportDBManager
    @Dependency(\.supabaseManager) private var supabaseManager
    private let logger = Logger(subsystem: "LeafLog", category: "CommunityDetailReactor")
    private let postID: UUID
    
    init(postID: UUID) {
        self.postID = postID
        self.initialState = State()
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .concat(
                .just(.setLoading(true)),
                fetchPost(),
                .just(.setLoading(false))
            )
            
        case .postImageTapped(let index):
            guard let post = currentState.post,
                  post.imageSlots.indices.contains(index) else { return .empty() }
            
            return .just(.presentImageViewer(.init(
                imageSlots: post.imageSlots,
                initialIndex: index
            )))
            
        case .postProfileImageTapped:
            guard let memberID = currentState.post?.memberID else { return .empty() }
            
            return .just(.routeToMemberProfile(memberID: memberID))
            
        case .commentProfileImageTapped(let index):
            guard currentState.comments.indices.contains(index) else { return .empty() }
            let memberID = currentState.comments[index].memberID
            
            return .just(.routeToMemberProfile(memberID: memberID))
            
        case .reachedBottom:
            guard currentState.isLoadingMoreComments == false,
                  currentState.hasNextCommentPage else {
                return .empty()
            }
            
            return .empty()
            
        case .heartButtonTapped:
            guard let post = currentState.post else { return .empty() }
            return .just(.setPostLiked(!post.isLiked))
            
        case .moreButtonTapped:
            guard let post = currentState.post else { return .empty() }
            return .just(.presentPostActionSheet(post.isMine ? .owner : .visitor))
            
        case .commentButtonTapped,
             .sendButtonTapped:
            return .empty()
            
        case .reportReasonSelected(let reason):
            guard let post = currentState.post,
                  post.isMine == false,
                  currentState.isReporting == false else {
                return .empty()
            }
            
            return .concat(
                .just(.setReporting(true)),
                reportPost(post: post, reason: reason),
                .just(.setReporting(false))
            )
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
            
        case .setPost(let post):
            newState.post = post
            
        case .setReporting(let isReporting):
            newState.isReporting = isReporting
            
        case .setLoadingMoreComments(let isLoadingMoreComments):
            newState.isLoadingMoreComments = isLoadingMoreComments
            
        case .appendComments(let comments, let nextCursor, let hasNextPage):
            newState.comments.append(contentsOf: comments)
            newState.nextCommentCursor = nextCursor
            newState.hasNextCommentPage = hasNextPage
            
        case .setPostLiked(let isLiked):
            newState.post?.isLiked = isLiked
            
        case .presentPostActionSheet(let kind):
            newState.postActionSheetKind = kind
            
        case .presentImageViewer(let route):
            newState.imageViewerRoute = route
            
        case .routeToMemberProfile(let memberID):
            newState.memberProfileRoute = memberID
            
        case .presentReportCompletedAlert:
            newState.reportCompleted = true
            
        case .setErrorMessage(let message):
            newState.errorMessage = message
        }
        
        return newState
    }
    
    private func fetchPost() -> Observable<Mutation> {
        Single<CommunityDetailResult>.create {
            [communityPostDBManager, supabaseManager, logger, postID] in
            let post = try await communityPostDBManager.fetchPost(id: postID)
            let profiles = try await communityPostDBManager.fetchPublicProfiles(authorIDs: [post.authorID])
            let nickname = profiles[post.authorID]?.nickname ?? "알 수 없는 사용자"
            let profileImageURLs = await communityPostDBManager.resolvePublicProfileImageURLs(profiles: profiles)
            let currentUserID = supabaseManager.client.auth.currentUser?.id
            let imagePaths = Self.imagePaths(from: post)
            var imageSlots: [PostImageSlot] = []
            
            for (index, imagePath) in imagePaths.enumerated() {
                var imageURL: URL?
                
                do {
                    imageURL = try await supabaseManager.resolveCommunityPostImageURL(
                        from: imagePath,
                        cacheKey: "\(post.id.uuidString)-\(index)"
                    )
                } catch {
                    logger.error(
                        "Community detail image URL resolution failed. postID: \(post.id.uuidString, privacy: .public), error: \(String(describing: error), privacy: .private)"
                    )
                }
                
                imageSlots.append(PostImageSlot(originalIndex: index, imageURL: imageURL))
            }
            
            return CommunityDetailResult(
                post: post,
                authorNickname: nickname,
                authorProfileImageURL: profileImageURLs[post.authorID],
                imageSlots: imageSlots,
                isMine: post.authorID == currentUserID
            )
        }
        .map { result in
            .setPost(Self.makeDetailPost(from: result))
        }
        .asObservable()
        .catch { error in
            let message = (error as? AuthError)?.userMessage
                ?? "게시글을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            return .just(.setErrorMessage(message))
        }
    }
    
    private func reportPost(
        post: Post,
        reason: CommunityReportReason
    ) -> Observable<Mutation> {
        Single<Bool>.create { [communityReportDBManager] in
            try await communityReportDBManager.reportPost(
                postID: post.id,
                reportedUserID: post.memberID,
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
    
    nonisolated private static func imagePaths(from post: CommunityPost) -> [String] {
        let imagePaths = post.images
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.imagePath)
        
        if imagePaths.isEmpty, let legacyImagePath = post.legacyImagePath {
            return [legacyImagePath]
        }
        
        return imagePaths
    }
    
    private static func makeDetailPost(from result: CommunityDetailResult) -> Post {
        Post(
            id: result.post.id,
            memberID: result.post.authorID,
            category: result.post.category.title,
            title: result.post.title,
            nickname: result.authorNickname,
            profileImageURL: result.authorProfileImageURL,
            date: dateFormatter.string(from: result.post.createdAt),
            body: result.post.content,
            imageSlots: result.imageSlots,
            likeCount: String(result.post.likeCount),
            commentCount: String(result.post.commentCount ?? 0),
            isLiked: false,
            isMine: result.isMine
        )
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}

nonisolated private struct CommunityDetailResult: Sendable {
    let post: CommunityPost
    let authorNickname: String
    let authorProfileImageURL: URL?
    let imageSlots: [CommunityDetailReactor.PostImageSlot]
    let isMine: Bool
}
