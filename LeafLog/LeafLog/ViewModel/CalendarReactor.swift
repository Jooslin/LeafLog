//
//  CalendarReactor.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/19/26.
//

import Foundation
import UIKit
import ReactorKit
import Dependencies

final class CalendarReactor: Reactor {
    enum Action {
        
    }
    
    enum Mutation {
        
    }
    
    struct State {
        
    }
    
    let initialState = State()
    
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
