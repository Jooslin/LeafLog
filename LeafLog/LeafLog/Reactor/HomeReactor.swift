//
//  HomeReactor.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/27/26.
//

import Foundation
import ReactorKit
import Supabase
import Dependencies

final class HomeReactor: Reactor {
    enum Action {
        
    }
    
    enum Mutation {
        
    }
    
    struct State {
        var isLoading: Bool = false
        var isAppleLoginBlocked = false
        @Pulse var loginSuccess: Bool = false
        @Pulse var errorMessage: String? = nil
    }
    
    let initialState = State()
    
    //MARK: Properties
    @Dependency(\.plantDBManager) private var plantDBManger
    @Dependency(\.careRecordDBManager) private var careRecordDBManager
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        
        }
        return newState
    }
}
