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
    let window: UIWindow
    let navigationController = UINavigationController()
    
    var root: any Presentable { navigationController }
    
    init(window: UIWindow) {
        window.rootViewController = navigationController
        self.window = window
    }
    
    func navigate(to step: any RxFlow.Step) -> FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .main:
            return navigateToMain()
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}

extension LoginFlow {
    private func navigateToMain() -> FlowContributors {
        let mainFlow = MainFlow(window: window)
        return .one(
            flowContributor: .contribute(
                withNextPresentable: mainFlow,
                withNextStepper: OneStepper(withSingleStep: AppStep.main))
            )
    }
}
