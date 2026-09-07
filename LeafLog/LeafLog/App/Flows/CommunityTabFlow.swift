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
            let viewController = CommunityViewController()
            viewController.reactor = CommunityReactor()
            navigationController.setViewControllers(
                [viewController],
                animated: false
            )

            return .one(
                flowContributor: .contribute(
                    withNextPresentable: viewController,
                    withNextStepper: viewController
                )
            )

        case .communityDetail(let postID):
            return navigateToDetail(postID: postID)
            
        case .memberProfile(let memberID):
            return navigateToMemberProfile(memberID: memberID)

        case .communityComposeCreate:
            return navigateToCompose(mode: .create)

        case .communityComposeEdit(let post):
            return navigateToCompose(mode: .edit(post))
            
        case .communityPostUpdated(let postID):
            return updateCommunityPostDetail(postID: postID)
            
        case .communityPostDeleted(let postID):
            return deleteCommunityPostDetail(postID: postID)
            
        case .composeNotice:
            let notice = CommunityInfoViewController()
            notice.modalPresentationStyle = .overCurrentContext
            navigationController.present(notice, animated: false)
            return .none

        case .pageBack:
            navigationController.popViewController(animated: true)
            return .none
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}

private extension CommunityTabFlow {
    func navigateToCompose(
        mode: CommunityComposeMode
    ) -> FlowContributors {
        let viewController = CommunityComposeViewController(mode: mode)
        viewController.reactor = CommunityComposeReactor(mode: mode)
        navigationController.pushViewController(viewController, animated: true)

        return .one(
            flowContributor: .contribute(
                withNextPresentable: viewController,
                withNextStepper: viewController
            )
        )
    }
    
    func navigateToDetail(postID: UUID) -> FlowContributors {
        let viewController = CommunityDetailViewController()
        viewController.hidesBottomBarWhenPushed = true
        viewController.reactor = CommunityDetailReactor(postID: postID)
        navigationController.pushViewController(viewController, animated: true)

        return .one(
            flowContributor: .contribute(
                withNextPresentable: viewController,
                withNextStepper: viewController
            )
        )
    }
    
    func navigateToMemberProfile(memberID: UUID) -> FlowContributors {
        let viewController = MemberProfileViewController(memberID: memberID)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
        
        return .one(
            flowContributor: .contribute(
                withNextPresentable: viewController,
                withNextStepper: viewController
            )
        )
    }
    
    func updateCommunityPostDetail(postID: UUID) -> FlowContributors {
        navigationController.popViewController(animated: true)
        
        let detailViewController = navigationController.viewControllers
            .compactMap { $0 as? CommunityDetailViewController }
            .last
        detailViewController?.refreshPostIfNeeded(postID: postID)
        
        return .none
    }
    
    func deleteCommunityPostDetail(postID: UUID) -> FlowContributors {
        let deletedViewController = navigationController.viewControllers
            .compactMap { $0 as? CommunityDetailViewController }
            .last { $0.currentPostID == postID }
        
        if let deletedViewController {
            navigationController.popToViewController(
                deletedViewController,
                animated: false
            )
        }
        
        navigationController.popViewController(animated: true)
        
        return .none
    }
}
