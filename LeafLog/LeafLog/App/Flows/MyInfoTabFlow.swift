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
    private let navigationController = UINavigationController()
    
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
            viewController.hidesBottomBarWhenPushed = true
            viewController.reactor = ProfileEditReactor()
            navigationController.pushViewController(viewController, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))

        case .myActivity:
            let viewController = MyActivityViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(viewController, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))
            
        case let .confirmAlert(title, message, okTitle, onConfirm):
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: okTitle, style: .destructive) { _ in
                onConfirm()
            })
            
            navigationController.present(alert, animated: true)
            return .none
            
        case .profileImageSourceSheet:
            presentProfileImageSourceSheet()
            return .none
            
        case .loginRequired:
            return .end(forwardToParentFlowWithStep: step)
            
        case .notificationAuthorizationRequired(let onSettingsSelected):
            return presentNotificationAuthorizationRequired(onSettingsSelected: onSettingsSelected)
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}

// MARK: - Helper
private extension MyInfoTabFlow {
    func presentProfileImageSourceSheet() {
        guard let profileEditVC = navigationController.topViewController as? ProfileEditViewController else {
            return
        }
        
        // 공용 presenter 호출
        ImageSourcePickerPresenter.present(
            from: navigationController,
            sourceView: profileEditVC.profileImagePickerSourceView,
            delegate: profileEditVC,
            deleteTitle: profileEditVC.hasProfileImage ? "사진 삭제" : nil,
            onDelete: { [weak profileEditVC] in
                profileEditVC?.deleteProfileImage()
            }
        )
    }
    
    func presentNotificationAuthorizationRequired(onSettingsSelected: @escaping () -> Void) -> RxFlow.FlowContributors {
        let alert = UIAlertController(title: "알림 권한 필요", message: "푸시 알림을 활성화하기 위해서는 알림 권한이 필요합니다.", preferredStyle: .alert)
        
        let setting = UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            onSettingsSelected()
        }
        
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(setting)
        alert.addAction(cancel)
        
        navigationController.present(alert, animated: true)
        
        return .none
    }
}
