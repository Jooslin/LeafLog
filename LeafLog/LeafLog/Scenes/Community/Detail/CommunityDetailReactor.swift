//
//  CommunityDetailReactor.swift
//  LeafLog
//
//  Created by Yeseul Jang on 7/9/26.
//

import ReactorKit
import RxSwift

final class CommunityDetailReactor: Reactor {
    enum Action {
        case viewDidLoad
    }
    
    enum Mutation {
        case setLoading(Bool)
    }
    
    struct State {
        var isLoading = false
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
