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
        case enterTitle(String)
    }
    
    enum Mutation {
        case setCategory(PostCategory)
        case setTitle(String)
    }
    
    struct State {
        var category: PostCategory
        var title: String = ""
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
        case .enterTitle(let title):
                return .just(.setTitle(title))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setCategory(let category):
            newState.category = category
        case .setTitle(let title):
            newState.title = title
        }
        return newState
    }
}
