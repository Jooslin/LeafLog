//
//  MyInfoTabFlow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/6/26.
//

import UIKit
import RxFlow
import ReactorKit

final class MyInfoTabFlow: Flow {
    let navigationController = UINavigationController()
    
    var root: any RxFlow.Presentable { navigationController }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .myInfoTab:
            let viewController = MyPageViewController()
            viewController.reactor = MyPageReactor()
            navigationController.pushViewController(viewController, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))

        case .profileEdit:
            let viewController = ProfileEditViewController()
            viewController.reactor = ProfileEditReactor()
            navigationController.pushViewController(viewController, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}
