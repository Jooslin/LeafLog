//
//  LoginFlow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/10/26.
//  Updated by 김주희 on 4/17/26.
//

import UIKit
import RxFlow
import ReactorKit

final class LoginFlow: Flow {
    private let window: UIWindow
    private let navigationController = UINavigationController()
    
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
        case .loginRequired:
            return navigateToLogin()
        case .main:
            return .end(forwardToParentFlowWithStep: step)
        case .alert(let title, let message):
            return presentAlert(title: title, message: message)
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }

    private func presentAlert(title: String, message: String) -> FlowContributors {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        navigationController.present(alert, animated: true)
        return .none
    }
}

extension LoginFlow {
    private func navigateToLogin() -> FlowContributors {
        let viewController = LoginViewController()
        viewController.reactor = LoginReactor()

        navigationController.setViewControllers([viewController], animated: false)
        return .one(
            flowContributor: .contribute(
                withNextPresentable: viewController,
                withNextStepper: viewController)
        )
    }
}
