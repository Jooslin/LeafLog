//
//  CommunityDetailReactor.swift
//  LeafLog
//
//  Created by Yeseul Jang on 7/9/26.
//

import ReactorKit
import RxSwift

final class CommunityDetailReactor: Reactor {
    struct Post: Equatable {
        let category: String
        let title: String
        let nickname: String
        let date: String
        let body: String
        let imageAssetNames: [String]
        let likeCount: String
        let commentCount: String
    }
    
    struct Comment: Equatable {
        let nickname: String
        let date: String
        let body: String
        let badge: CommentBadge
    }
    
    enum CommentBadge: Equatable {
        case author
        case mine
        case none
    }
    
    enum Action {
        case viewDidLoad
    }
    
    enum Mutation {
        case setLoading(Bool)
    }
    
    struct State {
        var isLoading = false
        var post = Post(
            category: "식물 일상",
            title: "우리집 몬스테라 새잎이 나왔어요!",
            nickname: "잎로그",
            date: "2026.04.27",
            body: """
            요즘 식물 키우면서 느낀 건, 결국 꾸준히 “기록하는 사람”이 식물을 오래 잘 키운다는 점이에요. 처음에는 물 주는 날짜만 잘 기억하면 된다고 생각했는데, 막상 키우다 보니까 그렇게 단순하지 않더라고요. 같은 주기로 물을 줘도 어떤 날은 잎이 축 처지고, 어떤 날은 멀쩡하고요. 이유를 몰라서 그냥 감으로 대응하다 보니 식물 상태가 더 나빠지는 경우도 있었어요.
            """,
            imageAssetNames: ["placeholder", "placeholder", "placeholder", "placeholder", "placeholder"],
            likeCount: "N",
            commentCount: "N"
        )
        var comments: [Comment] = [
            .init(
                nickname: "닉네임임",
                date: "2026.04.27",
                body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
                badge: .none
            ),
            .init(
                nickname: "닉네임임",
                date: "2026.04.27",
                body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
                badge: .author
            ),
            .init(
                nickname: "닉네임임",
                date: "2026.04.27",
                body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
                badge: .mine
            ),
            .init(
                nickname: "닉네임임",
                date: "2026.04.27",
                body: "잎이 정말 싱그럽네요! 혹시 햇빛은 어떻게 쬐나요?",
                badge: .none
            )
        ]
    }
    
    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .empty()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }
        
        return newState
    }
}
