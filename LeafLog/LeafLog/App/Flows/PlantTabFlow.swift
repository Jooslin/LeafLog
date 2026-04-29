//
//  PlantTabFlow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/5/26.
//

import UIKit
import RxFlow
import Dependencies
import AVFoundation
import RxRelay
import PhotosUI

/*
 RxFlow 사용 예시입니다. - 추후 해당 탭 구현 시 변경 예정입니다.
 switch문으로 step에 따라 실행할 동작을 정의해주시면 됩니다.
 PlantTabFlow에서만 step에 따른 동작을 정의해놓았으므로 다른 탭(Calendar, MyInfo)에서는 push버튼을 눌러도 아무 동작이 실행되지 않습니다.
 */

final class PlantTabFlow: Flow {
    @Dependency(\.cameraService) private var cameraService
    @Dependency(\.uiApplication) private var uiApplication
    private let navigationController = UINavigationController()
    private let photoSelectStepper = PhotoSelectStepper()
    private var imagePicker: PHPickerViewController?
    
    var root: any RxFlow.Presentable { navigationController }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .plantTab:
            let homeViewController = HomeViewController()
            navigationController.setViewControllers([homeViewController], animated: false)

            return .one(
                flowContributor: .contribute(
                    withNextPresentable: homeViewController,
                    withNextStepper: homeViewController
                )
            )
            
        case .endPlantRegister:
            navigationController.popToRootViewController(animated: true)
            return .none

        case .plantRegister(let selectedPlant):
            if let selectedPlant,
               let registerViewController = navigationController.topViewController as? PlantRegisterViewController {
                registerViewController.updateSelectedPlant(selectedPlant)

                return .none
            }

            if let selectedPlant,
               let registerIndex = navigationController.viewControllers.lastIndex(where: { $0 is PlantRegisterViewController }),
               let registerViewController = navigationController.viewControllers[registerIndex] as? PlantRegisterViewController {
                registerViewController.updateSelectedPlant(selectedPlant)

                let previousViewControllers = Array(navigationController.viewControllers.prefix(registerIndex))
                let searchViewControllers = navigationController.viewControllers
                    .dropFirst(registerIndex + 1)
                    .filter { $0 is SearchViewController }
                let updatedViewControllers = previousViewControllers + searchViewControllers + [registerViewController]
                navigationController.setViewControllers(updatedViewControllers, animated: true)

                return .none
            }

            let plantRegisterViewController = makePlantRegisterViewController(selectedPlant: selectedPlant)
            
            if navigationController.viewControllers.isEmpty {
                let homeViewController = HomeViewController()
                navigationController.setViewControllers([homeViewController, plantRegisterViewController], animated: false)
            } else if selectedPlant == nil,
                      let registerIndex = navigationController.viewControllers.lastIndex(where: { $0 is PlantRegisterViewController }) {
                var updatedViewControllers = Array(navigationController.viewControllers.prefix(registerIndex))
                updatedViewControllers.append(plantRegisterViewController)
                navigationController.setViewControllers(updatedViewControllers, animated: true)
            } else {
                navigationController.pushViewController(plantRegisterViewController, animated: true)
            }

//            return .one(
//                flowContributor: .contribute(
//                    withNextPresentable: plantRegisterViewController,
//                    withNextStepper: plantRegisterViewController
//                )
//            )
            
            return .one(
                flowContributor: .contribute(
                    withNextPresentable: plantRegisterViewController,
                    withNextStepper: CompositeStepper(
                        steppers: [plantRegisterViewController, photoSelectStepper]
                    )))

        case .plantEdit(let plant):
            let plantRegisterViewController = makePlantEditViewController(plant: plant)
            navigationController.pushViewController(plantRegisterViewController, animated: true)

            return .one(
                flowContributor: .contribute(
                    withNextPresentable: plantRegisterViewController,
                    withNextStepper: CompositeStepper(
                        steppers: [plantRegisterViewController, photoSelectStepper]
                    )
                )
            )

        case .plantSearch:
            let searchViewController = SearchViewController()
            searchViewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(searchViewController, animated: true)

            return .one(
                flowContributor: .contribute(
                    withNextPresentable: searchViewController,
                    withNextStepper: searchViewController
                )
            )

        case .plantSearchDetail(let contentNumber):
            let reactor = SearchDetailReactor(contentNumber: contentNumber)
            let viewController = SearchDetailViewController(reactor: reactor)
            viewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(viewController, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))

        case .record(let plantID, let date):
            let viewController = PlantCareViewController(reactor: PlantCareReactor(plantID: plantID, selectedDate: date))
            viewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(viewController, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))            
        
        case .classificationResult(let result): // AI 검색 결과 표시
            let searchViewController = SearchViewController(classficationResult: result)
            searchViewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(searchViewController, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: searchViewController, withNextStepper: searchViewController))
            
        case .applicatoinSettingRequired: // 휴대폰 앱 설정 화면 이동
            if let url = URL(string: UIApplication.openSettingsURLString) {
                uiApplication.open(url)
            }
            return .none
            
        case .photoSelect: // 사진 선택 분기
            return presentPhotoSelect()

        case .diaryImageSourceSheet:
            presentDiaryImageSourceSheet()
            return .none

        case let .confirmAlert(title, message, okTitle, onConfirm):
            presentConfirmAlert(
                title: title,
                message: message,
                okTitle: okTitle,
                onConfirm: onConfirm
            )
            return .none
            
        case .cameraRequired:
            let camera = CameraClassificationViewController()
            navigationController.pushViewController(camera, animated: true)
            
            return .one(flowContributor: .contribute(withNextPresentable: camera, withNextStepper: camera))
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}

extension PlantTabFlow {
    // 사진 선택 alert에서 사용할 stepper
    struct PhotoSelectStepper: Stepper {
        let steps = PublishRelay<Step>()
    }
    
    //TODO: 추후 수정 필요 - 등록 화면의 카메라 검색 버튼과 연동하여 수정 필요
    private func presentPhotoSelect() -> FlowContributors {
        let alert = UIAlertController()
        let cameraAction = UIAlertAction(title: "촬영하기", style: .default) { [weak self] _ in
            self?.photoSelectStepper.steps.accept(AppStep.cameraRequired)
        }
        
//        let galleryAction = UIAlertAction(title: "이미지 불러오기", style: .default) { [weak self] _ in
//            guard let self else { return }
//            
//           let imagePicker = imagePicker ?? makeImagePicker()
//            
//            alert.dismiss(animated: true) {
//                self.navigationController.present(imagePicker, animated: true)
//            }
//        }
        
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(cameraAction)
//        alert.addAction(galleryAction)
        alert.addAction(cancel)
        
        navigationController.present(alert, animated: true)
        
        return .none
    }

    private func presentDiaryImageSourceSheet() {
        guard let viewController = navigationController.topViewController as? PlantCareViewController else {
            return
        }

        ImageSourcePickerPresenter.present(
            from: navigationController,
            sourceView: viewController.diaryImagePickerSourceView,
            delegate: viewController,
            deleteTitle: viewController.hasDiaryPhoto ? "사진 삭제" : nil,
            onDelete: { [weak viewController] in
                viewController?.deleteDiaryPhoto()
            }
        )
    }

    private func presentConfirmAlert(
        title: String,
        message: String,
        okTitle: String,
        onConfirm: @escaping () -> Void
    ) {
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
    }

    private func makePlantRegisterViewController(selectedPlant: SelectedPlant?) -> PlantRegisterViewController {
        let reactor = PlantRegisterReactor(selectedPlant: selectedPlant)
        let viewController = PlantRegisterViewController(reactor: reactor)
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }

    private func makePlantEditViewController(plant: MyPlant) -> PlantRegisterViewController {
        let reactor = PlantRegisterReactor(mode: .edit(plant))
        let viewController = PlantRegisterViewController(reactor: reactor)
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }
}
