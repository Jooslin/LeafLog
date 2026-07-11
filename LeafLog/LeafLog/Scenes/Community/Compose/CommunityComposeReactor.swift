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

    }
    
    struct State {
        let category: PostCategory
    }
    
    let initialState = State(category: .plantLife)
    
    //MARK: Properties
    private let calendar = Calendar.current
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return .empty()
        case .selectCategory:
            return .empty()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        
        }
        return newState
    }
}
