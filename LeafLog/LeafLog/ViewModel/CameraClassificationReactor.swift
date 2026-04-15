//
//  CameraClassificationReactor.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/15/26.
//

import UIKit
import ReactorKit
import RxSwift
import Dependencies

final class CameraClassificationReactor: Reactor {
    // 행동(트리거)
    enum Action {
        case viewWillAppear
    }
    
    // State를 변경시킬 값
    enum Mutation {
        
    }
    
    // (화면의) 상태
    struct State {
        
    }
    
    let initialState = State()
}
