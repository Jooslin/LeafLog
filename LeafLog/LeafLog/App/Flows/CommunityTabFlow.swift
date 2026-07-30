//
//  CommunityTabFlow.swift
//  LeafLog
//
//  Created by 변예린 on 7/9/26.
//

import UIKit
import RxFlow
import Dependencies
import RxRelay
import ReactorKit

/*
 RxFlow 사용 예시입니다. - 추후 해당 탭 구현 시 변경 예정입니다.
 switch문으로 step에 따라 실행할 동작을 정의해주시면 됩니다.
 PlantTabFlow에서만 step에 따른 동작을 정의해놓았으므로 다른 탭(Calendar, MyInfo)에서는 push버튼을 눌러도 아무 동작이 실행되지 않습니다.
 */

final class CommunityTabFlow: Flow {
    private let navigationController = UINavigationController()
    
    var root: any RxFlow.Presentable { navigationController }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .communityTab:
            //TODO: Community Main VC로 변경 필요
            let viewController = CommunityComposeViewController()
            navigationController.setViewControllers([viewController], animated: false)

            return .one(
                flowContributor: .contribute(
                    withNextPresentable: viewController,
                    withNextStepper: viewController
                )
            )
            
        case .composeNotice:
            let notice = CommunityInfoViewController()
            notice.modalPresentationStyle = .overCurrentContext
            navigationController.present(notice, animated: false)
        
            return .none
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}
