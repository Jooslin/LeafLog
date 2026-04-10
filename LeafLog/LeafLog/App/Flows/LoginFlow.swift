//
//  LoginFlow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/10/26.
//

import UIKit
import RxFlow
import ReactorKit

final class LoginFlow: Flow {
    let navigationController = UINavigationController()
//    let viewController: LoginViewController
    
    var root: RxFlow.Presentable { self.navigationController }
    
    init(window: UIWindow) {
        window.rootViewController = navigationController
    }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}
