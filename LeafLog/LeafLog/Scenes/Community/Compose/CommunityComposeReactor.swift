//
//  CommunityComposeReactor.swift
//  LeafLog
//
//  Created by 변예린 on 7/9/26.
//

import Foundation
import ReactorKit
import Supabase
import Dependencies

final class CommunityComposeReactor: Reactor {
    enum Action {
        case viewWillAppear
        case selectCategory(Int)
    }
    
    enum Mutation {
        case setCategory(PostCategory)
    }
    
    struct State {
        var category: PostCategory
    }
    
    let initialState = State(category: .plantLife)
    
    //MARK: Properties
    private let calendar = Calendar.current
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return .empty()
        case .selectCategory(let tag):
            return .just(.setCategory(PostCategory(rawValue: tag) ?? .plantLife))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setCategory(let category):
            newState.category = category
        }
        return newState
    }
}
