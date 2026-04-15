//
//  MyInfoTabFlow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/6/26.
//

import UIKit
import RxFlow
import ReactorKit
import PhotosUI

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
            viewController.reactor = ProfileEditReactor()
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

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
                self?.presentCameraPicker(from: profileEditVC)
            })
        }

        alertController.addAction(UIAlertAction(title: "앨범", style: .default) { [weak self] _ in
            self?.presentPhotoPicker(from: profileEditVC)
        })

        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = profileEditVC.profileImagePickerSourceView
            popoverController.sourceRect = profileEditVC.profileImagePickerSourceView.bounds
        }

        navigationController.present(alertController, animated: true)
    }

    func presentCameraPicker(from viewController: ProfileEditViewController) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = viewController

        navigationController.present(picker, animated: true)
    }

    func presentPhotoPicker(from viewController: ProfileEditViewController) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = viewController

        navigationController.present(picker, animated: true)
    }
}

