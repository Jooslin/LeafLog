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
        var commentCount: String
        var isLiked: Bool
        let isMine: Bool
    }
    
    struct Comment: Equatable {
        let id: UUID
        let memberID: UUID
        let nickname: String
        let date: String
        let body: String
        let badge: CommentBadge
        let isMine: Bool
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
        case refreshPost
        case moreButtonTapped
        case postImageTapped(index: Int)
        case postProfileImageTapped
        case commentProfileImageTapped(index: Int)
        case enterCommentText(String)
        case heartButtonTapped
        case commentButtonTapped
        case sendButtonTapped
        case editButtonTapped
        case deleteButtonTapped
        case reportReasonSelected(CommunityReportReason)
        case reachedBottom
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setDetail(Post, originalPost: CommunityPost, comments: [Comment])
        case setPost(Post, originalPost: CommunityPost)
        case setComments([Comment])
        case setCommentInputText(String)
        case setSubmittingComment(Bool)
        case setReporting(Bool)
        case setDeleting(Bool)
        case setLoadingMoreComments(Bool)
        case appendComments([Comment], nextCursor: String?, hasNextPage: Bool)
        case setPostLiked(Bool)
        case presentPostActionSheet(PostActionSheetKind)
        case presentImageViewer(ImageViewerRoute)
        case routeToMemberProfile(memberID: UUID)
        case routeToEditPost(CommunityPost)
        case routeToDeletedPost(postID: UUID)
        case presentReportCompletedAlert
        case setErrorMessage(String)
    }
    
    struct State {
        var isLoading = false
        var isSubmittingComment = false
        var isReporting = false
        var isDeleting = false
        var isLoadingMoreComments = false
        var hasNextCommentPage = false
        var nextCommentCursor: String?
        @Pulse var postActionSheetKind: PostActionSheetKind?
        @Pulse var imageViewerRoute: ImageViewerRoute?
        @Pulse var memberProfileRoute: UUID?
        @Pulse var editPostRoute: CommunityPost?
        @Pulse var deletedPostRoute: UUID?
        @Pulse var reportCompleted: Bool?
        @Pulse var errorMessage: String?
        var post: Post?
        var originalPost: CommunityPost?
        var comments: [Comment] = []
        var commentInputText = ""
    }
    
    let initialState: State
    
    @Dependency(\.communityPostDBManager) private var communityPostDBManager
    @Dependency(\.communityCommentDBManager) private var communityCommentDBManager
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
                fetchDetail(),
                .just(.setLoading(false))
            )
            
        case .refreshPost:
            return .concat(
                .just(.setLoading(true)),
                fetchDetail(),
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
            
        case .enterCommentText(let text):
            return .just(.setCommentInputText(text))
            
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
            
        case .commentButtonTapped:
            return .empty()
            
        case .sendButtonTapped:
            guard let originalPost = currentState.originalPost,
                  currentState.isSubmittingComment == false else {
                return .empty()
            }
            
            let content = currentState.commentInputText
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard content.isEmpty == false else {
                return .just(.setErrorMessage("댓글 내용을 입력해주세요."))
            }
            guard content.count <= 500 else {
                return .just(.setErrorMessage("댓글은 500자 이하로 입력해주세요."))
            }
            
            return .concat(
                .just(.setSubmittingComment(true)),
                submitComment(
                    content: content,
                    postAuthorID: originalPost.authorID
                ),
                .just(.setSubmittingComment(false))
            )
            
        case .editButtonTapped:
            guard let originalPost = currentState.originalPost else { return .empty() }
            return .just(.routeToEditPost(originalPost))
            
        case .deleteButtonTapped:
            guard let post = currentState.post,
                  let originalPost = currentState.originalPost,
                  post.isMine,
                  currentState.isDeleting == false else {
                return .empty()
            }
            
            return .concat(
                .just(.setDeleting(true)),
                deletePost(originalPost),
                .just(.setDeleting(false))
            )
            
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
            
        case .setDetail(let post, let originalPost, let comments):
            var updatedPost = post
            updatedPost.commentCount = String(comments.count)
            newState.post = updatedPost
            newState.originalPost = originalPost
            newState.comments = comments
            
        case .setPost(let post, let originalPost):
            newState.post = post
            newState.originalPost = originalPost
            
        case .setComments(let comments):
            newState.comments = comments
            newState.post?.commentCount = String(comments.count)
            
        case .setCommentInputText(let text):
            newState.commentInputText = text
            
        case .setSubmittingComment(let isSubmittingComment):
            newState.isSubmittingComment = isSubmittingComment
            
        case .setReporting(let isReporting):
            newState.isReporting = isReporting
            
        case .setDeleting(let isDeleting):
            newState.isDeleting = isDeleting
            
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
            
        case .routeToEditPost(let post):
            newState.editPostRoute = post
            
        case .routeToDeletedPost(let postID):
            newState.deletedPostRoute = postID
            
        case .presentReportCompletedAlert:
            newState.reportCompleted = true
            
        case .setErrorMessage(let message):
            newState.errorMessage = message
        }
        
        return newState
    }
    
    private func fetchDetail() -> Observable<Mutation> {
        Single<CommunityDetailResult>.create {
            [communityPostDBManager, communityCommentDBManager, supabaseManager, logger, postID] in
            let post = try await communityPostDBManager.fetchPost(id: postID)
            let comments = try await communityCommentDBManager.fetchComments(postID: postID)
            let authorIDs = Set([post.authorID] + comments.map(\.authorID))
            let profiles = try await communityPostDBManager.fetchPublicProfiles(authorIDs: Array(authorIDs))
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
                isMine: post.authorID == currentUserID,
                comments: comments,
                commentAuthorNicknames: profiles.mapValues {
                    $0.nickname ?? "알 수 없는 사용자"
                },
                currentUserID: currentUserID
            )
        }
        .map { result in
            .setDetail(
                Self.makeDetailPost(from: result),
                originalPost: result.post,
                comments: Self.makeDetailComments(from: result)
            )
        }
        .asObservable()
        .catch { error in
            let message = (error as? AuthError)?.userMessage
                ?? "게시글을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            return .just(.setErrorMessage(message))
        }
    }
    
    private func submitComment(
        content: String,
        postAuthorID: UUID
    ) -> Observable<Mutation> {
        Single<[Comment]>.create {
            [communityCommentDBManager, communityPostDBManager, supabaseManager, postID] in
            _ = try await communityCommentDBManager.createComment(
                postID: postID,
                content: content
            )
            
            return try await Self.fetchDisplayComments(
                postID: postID,
                postAuthorID: postAuthorID,
                communityCommentDBManager: communityCommentDBManager,
                communityPostDBManager: communityPostDBManager,
                supabaseManager: supabaseManager
            )
        }
        .asObservable()
        .flatMap { comments -> Observable<Mutation> in
            Observable.from([
                Mutation.setComments(comments),
                Mutation.setCommentInputText("")
            ])
        }
        .catch { error in
            let message = (error as? AuthError)?.userMessage
                ?? "댓글을 저장하지 못했어요. 잠시 후 다시 시도해주세요."
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
    
    private func deletePost(_ post: CommunityPost) -> Observable<Mutation> {
        Single<UUID>.create { [communityPostDBManager] in
            try await communityPostDBManager.deletePost(post)
            return post.id
        }
        .map { .routeToDeletedPost(postID: $0) }
        .asObservable()
        .catch { error in
            let message = (error as? AuthError)?.userMessage
                ?? "게시글을 삭제하지 못했어요. 잠시 후 다시 시도해주세요."
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
    
    private static func fetchDisplayComments(
        postID: UUID,
        postAuthorID: UUID,
        communityCommentDBManager: CommunityCommentDBManager,
        communityPostDBManager: CommunityPostDBManager,
        supabaseManager: SupabaseManager
    ) async throws -> [Comment] {
        let comments = try await communityCommentDBManager.fetchComments(postID: postID)
        let profiles = try await communityPostDBManager.fetchPublicProfiles(
            authorIDs: Array(Set(comments.map(\.authorID)))
        )
        
        return makeDetailComments(
            comments: comments,
            commentAuthorNicknames: profiles.mapValues {
                $0.nickname ?? "알 수 없는 사용자"
            },
            postAuthorID: postAuthorID,
            currentUserID: supabaseManager.client.auth.currentUser?.id
        )
    }
    
    private static func makeDetailComments(from result: CommunityDetailResult) -> [Comment] {
        makeDetailComments(
            comments: result.comments,
            commentAuthorNicknames: result.commentAuthorNicknames,
            postAuthorID: result.post.authorID,
            currentUserID: result.currentUserID
        )
    }
    
    private static func makeDetailComments(
        comments: [CommunityComment],
        commentAuthorNicknames: [UUID: String],
        postAuthorID: UUID,
        currentUserID: UUID?
    ) -> [Comment] {
        comments.map { comment in
            let isMine = comment.authorID == currentUserID
            let badge: CommentBadge
            if comment.authorID == postAuthorID {
                badge = .author
            } else if isMine {
                badge = .mine
            } else {
                badge = .none
            }
            
            return Comment(
                id: comment.id,
                memberID: comment.authorID,
                nickname: commentAuthorNicknames[comment.authorID] ?? "알 수 없는 사용자",
                date: dateFormatter.string(from: comment.createdAt),
                body: comment.content,
                badge: badge,
                isMine: isMine
            )
        }
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
    let comments: [CommunityComment]
    let commentAuthorNicknames: [UUID: String]
    let currentUserID: UUID?
}
