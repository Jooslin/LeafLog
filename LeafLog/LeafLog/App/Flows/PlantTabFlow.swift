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
import ReactorKit

/*
 RxFlow 사용 예시입니다. - 추후 해당 탭 구현 시 변경 예정입니다.
 switch문으로 step에 따라 실행할 동작을 정의해주시면 됩니다.
 PlantTabFlow에서만 step에 따른 동작을 정의해놓았으므로 다른 탭(Calendar, MyInfo)에서는 push버튼을 눌러도 아무 동작이 실행되지 않습니다.
 */

final class PlantTabFlow: Flow {
    @Dependency(\.cameraService) private var cameraService
    @Dependency(\.uiApplication) private var uiApplication
    private let navigationController = UINavigationController()
    
    var root: any RxFlow.Presentable { navigationController }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .plantTab:
            let homeViewController = HomeViewController()
            homeViewController.reactor = HomeReactor()
            navigationController.setViewControllers([homeViewController], animated: false)

            return .one(
                flowContributor: .contribute(
                    withNextPresentable: homeViewController,
                    withNextStepper: homeViewController
                )
            )
            
        case .record(let plantID, let date):
            let viewController = PlantCareViewController(reactor: PlantCareReactor(plantID: plantID, selectedDate: date))
            viewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(viewController, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))
            
        case .endPlantRegisterEdit:
            navigationController.popToRootViewController(animated: true)
            return .none

            // 새 식물 등록 시작
        case .plantRegister:
            let plantRegisterViewController = makePlantRegisterViewController(selectedPlant: nil)

            if navigationController.viewControllers.isEmpty {
                let homeViewController = HomeViewController()
                navigationController.setViewControllers([homeViewController, plantRegisterViewController], animated: false)
            } else if let registerIndex = navigationController.viewControllers.lastIndex(where: { $0 is PlantRegisterViewController }) {
                var updatedViewControllers = Array(navigationController.viewControllers.prefix(registerIndex))
                updatedViewControllers.append(plantRegisterViewController)
                navigationController.setViewControllers(updatedViewControllers, animated: true)
            } else {
                navigationController.pushViewController(plantRegisterViewController, animated: true)
            }

            return .one(
                flowContributor: .contribute(
                    withNextPresentable: plantRegisterViewController,
                    withNextStepper:  plantRegisterViewController
                    )
                )
            
            // 검색, 상세 등에서 식물 정보 가지고 시작
        case .plantRegisterSelectedPlant(let selectedPlant):
            if let registerViewController = navigationController.topViewController as? PlantRegisterViewController {
                registerViewController.updateSelectedPlant(selectedPlant)
                return .none
            }

            if let registerIndex = navigationController.viewControllers.lastIndex(where: { $0 is PlantRegisterViewController }),
               let registerViewController = navigationController.viewControllers[registerIndex] as? PlantRegisterViewController {
                registerViewController.updateSelectedPlant(selectedPlant)
                navigationController.popToViewController(registerViewController, animated: true)
                return .none
            }

            let plantRegisterViewController = makePlantRegisterViewController(selectedPlant: selectedPlant)
            navigationController.pushViewController(plantRegisterViewController, animated: true)
            return .one(
                flowContributor: .contribute(
                    withNextPresentable: plantRegisterViewController,
                    withNextStepper: plantRegisterViewController
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
        
        case .classificationResult(let result): // AI 검색 결과 표시
            return navigateToClassificationResult(result)
            
        case .applicatoinSettingRequired: // 휴대폰 앱 설정 화면 이동
            if let url = URL(string: UIApplication.openSettingsURLString) {
                uiApplication.open(url)
            }
            return .none
            
        case .cameraRequired:
            return navigateToCameraClassification()
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}

extension PlantTabFlow {
    private func updateAndRestorePlantRegister(
        registerViewController: PlantRegisterViewController,
        selectedPlant: SelectedPlant,
        registerIndex: Int
    ) {
        registerViewController.updateSelectedPlant(selectedPlant)

        let previousViewControllers = Array(navigationController.viewControllers.prefix(registerIndex))
        let searchViewControllers = navigationController.viewControllers
            .dropFirst(registerIndex + 1)
            .filter { $0 is SearchViewController }
        let updatedViewControllers = previousViewControllers + searchViewControllers + [registerViewController]
        navigationController.setViewControllers(updatedViewControllers, animated: true)
    }

    private func makePlantRegisterViewController(selectedPlant: SelectedPlant?) -> PlantRegisterViewController {
        let reactor = PlantRegisterReactor(selectedPlant: selectedPlant)
        let viewController = PlantRegisterViewController(reactor: reactor)
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }
    
    private func navigateToCameraClassification() -> FlowContributors {
        if let cameraVC = navigationController.viewControllers.first(where: { $0 is CameraClassificationViewController }) {
            navigationController.popToViewController(cameraVC, animated: true)
            return .none
        } else {
            let cameraViewController = CameraClassificationViewController()
            navigationController.pushViewController(cameraViewController, animated: true)
            
            return .one(
                flowContributor: .contribute(
                    withNextPresentable: cameraViewController,
                    withNextStepper: cameraViewController
                )
            )
        }
    }
    
    private func navigateToClassificationResult(_ result: [String: PlantClassificationService.Confidence]) -> FlowContributors {
        let searchViewController = SearchViewController(classficationResult: result)
        searchViewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(searchViewController, animated: true)
        
        return .one(
            flowContributor: .contribute(
                withNextPresentable: searchViewController,
                withNextStepper: searchViewController
            )
        )
    }
}
