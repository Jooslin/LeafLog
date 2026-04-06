//
//  PlantTabFlow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/5/26.
//

import UIKit
import RxFlow

/*
 RxFlow 사용 예시입니다. - 추후 해당 탭 구현 시 변경 예정입니다.
 switch문으로 step에 따라 실행할 동작을 정의해주시면 됩니다.
 PlantTabFlow에서만 step에 따른 동작을 정의해놓았으므로 다른 탭(Calendar, MyInfo)에서는 push버튼을 눌러도 아무 동작이 실행되지 않습니다.
 */

final class PlantTabFlow: Flow {
    let navigationController = UINavigationController()
    
    var root: any RxFlow.Presentable { navigationController }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .plantTab:
            let viewController = ViewController()
            navigationController.pushViewController(viewController, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))
            
        case .pushButtonTapped: // push 버튼이 눌렀을 경우
            let second = SecondViewController() // push할 VC
            navigationController.pushViewController(second, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: second, withNextStepper: second)) // 다음 Presentable 객체인 SecondVC와 다음 Step을 방출한 Stepper인 SecondVC를 전달 (Presentable과 Stepper 모두 동일하게 secondVC입니다.)
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}
