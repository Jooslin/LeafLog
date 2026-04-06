//
//  MyInfoTabFlow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/6/26.
//

import UIKit
import RxFlow

final class MyInfoTabFlow: Flow {
    let navigationController = UINavigationController()
    
    var root: any RxFlow.Presentable { navigationController }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .myInfoTab:
            //TODO: 내 정보 VC 생성 시 아래 ViewController()부분을 바꾸시면 됩니다!
            let viewController = ViewController()
            navigationController.pushViewController(viewController, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}
