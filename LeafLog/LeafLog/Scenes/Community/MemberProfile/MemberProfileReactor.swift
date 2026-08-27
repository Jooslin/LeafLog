//
//  MemberProfileReactor.swift
//  LeafLog
//
//  Created by Yeseul Jang on 8/5/26.
//

import ReactorKit
import RxSwift

final class MemberProfileReactor: Reactor {
    struct Profile: Equatable {
        let nickname: String
        let profileImageURL: String?
        let postCount: String
        let likeCount: String
    }
    
    struct Post: Equatable {
        let title: String
        let nickname: String
        let date: String
        let body: String
        let imageAssetName: String?
        let likeCount: String
        let commentCount: String
    }
    
    enum PostListItem: Equatable {
        case post(Post)
        case empty
    }
    
    enum Action {
        case viewDidLoad
        case moreButtonTapped
        case sortButtonTapped
        case reachedBottom
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setInitialLoading(Bool)
        case setLoadingMore(Bool)
        case setPosts([Post], nextCursor: String?, hasNextPage: Bool)
        case appendPosts([Post], nextCursor: String?, hasNextPage: Bool)
        case resetPosts
    }
    
    struct State {
        var isLoading = false
        var isInitialLoading = false
        var isLoadingMore = false
        var hasNextPage = false
        var nextCursor: String?
        var profile = Profile(
            nickname: "닉네임",
            profileImageURL: nil,
            postCount: "12",
            likeCount: "36"
        )
        var posts: [Post] = [
            .init(
                title: "우리집 몬스테라 새잎이 나왔어요!",
                nickname: "닉네임",
                date: "2026.04.27",
                body: "드디어 새잎이 쑥 나왔어요. 매일보는 즐거움이 있답니다! 몬스테라 후기 남겨요...",
                imageAssetName: "placeholder",
                likeCount: "N",
                commentCount: "N"
            ),
            .init(
                title: "우리집 몬스테라 새잎이 나왔어요!",
                nickname: "닉네임",
                date: "2026.04.27",
                body: "드디어 새잎이 쑥 나왔어요. 매일보는 즐거움이 있답니다! 몬스테라 후기 남겨요 열심히 기록해보자",
                imageAssetName: nil,
                likeCount: "N",
                commentCount: "N"
            ),
            .init(
                title: "우리집 몬스테라 새잎이 나왔어요!",
                nickname: "닉네임",
                date: "2026.04.27",
                body: "드디어 새잎이 쑥 나왔어요. 매일보는 즐거움이 있답니다! 몬스테라 후기 남겨요...",
                imageAssetName: "placeholder",
                likeCount: "N",
                commentCount: "N"
            ),
            .init(
                title: "우리집 몬스테라 새잎이 나왔어요!",
                nickname: "닉네임",
                date: "2026.04.27",
                body: "드디어 새잎이 쑥 나왔어요. 매일보는 즐거움이 있답니다! 몬스테라 후기 남겨요...",
                imageAssetName: "placeholder",
                likeCount: "N",
                commentCount: "N"
            ),
            .init(
                title: "우리집 몬스테라 새잎이 나왔어요!",
                nickname: "닉네임",
                date: "2026.04.27",
                body: "드디어 새잎이 쑥 나왔어요. 매일보는 즐거움이 있답니다! 몬스테라 후기 남겨요 열심히 기록해보자",
                imageAssetName: nil,
                likeCount: "N",
                commentCount: "N"
            ),
            .init(
                title: "우리집 몬스테라 새잎이 나왔어요!",
                nickname: "닉네임",
                date: "2026.04.27",
                body: "드디어 새잎이 쑥 나왔어요. 매일보는 즐거움이 있답니다! 몬스테라 후기 남겨요...",
                imageAssetName: "placeholder",
                likeCount: "N",
                commentCount: "N"
            )
        ]
        
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
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad,
             .moreButtonTapped,
             .sortButtonTapped:
            return .empty()
            
        case .reachedBottom:
            guard currentState.isInitialLoading == false,
                  currentState.isLoadingMore == false,
                  currentState.hasNextPage else {
                return .empty()
            }
            
            return .empty()
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
            
        case .setPosts(let posts, let nextCursor, let hasNextPage):
            newState.posts = posts
            newState.nextCursor = nextCursor
            newState.hasNextPage = hasNextPage
            
        case .appendPosts(let posts, let nextCursor, let hasNextPage):
            newState.posts.append(contentsOf: posts)
            newState.nextCursor = nextCursor
            newState.hasNextPage = hasNextPage
            
        case .resetPosts:
            newState.posts = []
            newState.nextCursor = nil
            newState.hasNextPage = false
        }
        
        return newState
    }
}
