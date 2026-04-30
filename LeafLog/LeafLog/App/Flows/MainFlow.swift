//
//  MainFlow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/10/26.
//

import UIKit
import RxFlow
import ReactorKit
import Dependencies

final class MainFlow: Flow {
    @Dependency(\.uiApplication) private var uiApplication
    private let window: UIWindow
    private let tabBarController = MainViewController()
    
    var root: any Presentable { tabBarController }
    
    init(window: UIWindow) {
        window.rootViewController = tabBarController
        self.window = window
    }
    
    func navigate(to step: any RxFlow.Step) -> FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .main:
            return navigateToMain()
            
        case .loginRequired:
            return .end(forwardToParentFlowWithStep: step)
            
        case .alert(let title, let message):
            return presentAlert(title: title, message: message)
            
        case .pageBack:
            pop(animated: true)
            return .none

        case .endPlantDelete:
            popTwice(animated: true)
            return .none
            
        case .record(let plantID):
            return navigateToPlantRecord(plantID: plantID)
            
        case .plantEdit(let plant):
            let plantRegisterViewController = makePlantEditViewController(plant: plant)
            navigate(to: plantRegisterViewController, animated: true)
            
            return .one(
                flowContributor: .contribute(
                    withNextPresentable: plantRegisterViewController,
                    withNextStepper: plantRegisterViewController
                ))

        case .plantSearch:
            return navigateToPlantSearch()

        case .plantSearchDetail(let contentNumber):
            return navigateToPlantSearchDetail(contentNumber: contentNumber)

        case .classificationResult(let result):
            return navigateToClassificationResult(result)

        case .plantRegisterSelectedPlant(let selectedPlant):
            return updatePlantRegister(selectedPlant)

        case .cameraRequired:
            return navigateToCameraClassification()

        case .applicatoinSettingRequired:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                uiApplication.open(url)
            }
            return .none

        case let .confirmAlert(title, message, okTitle, onConfirm):
            presentConfirmAlert(
                title: title,
                message: message,
                okTitle: okTitle,
                onConfirm: onConfirm
            )
            return .none
          
        case .alarmCenter:
            return navigateToAlarmCenter()
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
    
    private func navigate(to viewController: UIViewController, animated: Bool) {
        if let navigationController = tabBarController.selectedViewController as? UINavigationController {
            navigationController.pushViewController(viewController, animated: animated)
        } else {
            tabBarController.selectedViewController?.present(viewController, animated: animated, completion: nil)
        }
    }
    
    private func present(_ viewController: UIViewController, animated: Bool) {
        tabBarController.selectedViewController?.present(viewController, animated: animated, completion: nil)
    }
    
    private func pop(animated: Bool) {
        if let navigationController = tabBarController.selectedViewController as? UINavigationController {
            navigationController.popViewController(animated: animated)
        } else {
            tabBarController.selectedViewController?.dismiss(animated: animated)
        }
    }

    private func popTwice(animated: Bool) {
        guard let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            tabBarController.selectedViewController?.dismiss(animated: animated)
            return
        }

        let targetIndex = navigationController.viewControllers.count - 3
        if targetIndex >= 0 {
            let targetViewController = navigationController.viewControllers[targetIndex]
            navigationController.popToViewController(targetViewController, animated: animated)
        } else {
            navigationController.popToRootViewController(animated: animated)
        }
    }
}

extension MainFlow {
    private func navigateToMain() -> FlowContributors {
        
        let plantTabFlow = PlantTabFlow()
        let calendarTabFlow = CalendarTabFlow()
        let myInfoTabFlow = MyInfoTabFlow()
        
        // Flow를 준비 - 클로저는 Flow가 배치될 준비가 되었을 때(Flow의 첫 번째 화면이 선택되었을 때) 실행될 동작
        // Flow.use는 내부에서 Single 이벤트를 drive로 구독을 소비하므로 소비 완료 후 자동으로 구독이 해제되어 메모리 누수가 발생하지 않음
        Flows.use(plantTabFlow, calendarTabFlow, myInfoTabFlow, when: .created) { plant, calendar, my in
            
            plant.tabBarItem = UITabBarItem(
                title: "홈",
                image: .houseEmpty,
                selectedImage: .houseFill
            )
            
            calendar.tabBarItem = UITabBarItem(
                title: "캘린더",
                image: .calendarEmpty,
                selectedImage: .calendarFill,
            )
            
            my.tabBarItem = UITabBarItem(
                title: "마이",
                image: .userEmpty,
                selectedImage: .userFill
            )
            
            self.tabBarController.setViewControllers([plant, calendar, my], animated: true)
            self.tabBarController.tabBar.tintColor = .primary700
        }
        
        return .multiple(flowContributors: [
            .contribute(withNextPresentable: plantTabFlow, withNextStepper: OneStepper(withSingleStep: AppStep.plantTab)),
            .contribute(withNextPresentable: calendarTabFlow, withNextStepper: OneStepper(withSingleStep: AppStep.calendarTab)),
            .contribute(withNextPresentable: myInfoTabFlow, withNextStepper: OneStepper(withSingleStep: AppStep.myInfoTab))
        ])
    }
    
    private func presentAlert(title: String, message: String) -> FlowContributors {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        present(alert, animated: true)
        return .none
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

        present(alert, animated: true)
    }
    
    private func navigateToPlantRecord(plantID: UUID) -> FlowContributors {
        let viewController = PlantCareViewController(reactor: PlantCareReactor(plantID: plantID))
        navigate(to: viewController, animated: true)
        return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))
    }
  
    private func navigateToAlarmCenter() -> FlowContributors {
        let notificationCenterViewController = NotificationCenterViewController()
        let reactor = NotificationCenterReactor()
        notificationCenterViewController.reactor = reactor
        
        navigate(to: notificationCenterViewController, animated: true)
        return .one(flowContributor: .contribute(
            withNextPresentable: notificationCenterViewController,
            withNextStepper: notificationCenterViewController))
    }

    private func navigateToPlantSearch() -> FlowContributors {
        let searchViewController = SearchViewController()
        searchViewController.hidesBottomBarWhenPushed = true
        navigate(to: searchViewController, animated: true)

        return .one(
            flowContributor: .contribute(
                withNextPresentable: searchViewController,
                withNextStepper: searchViewController
            )
        )
    }

    private func navigateToPlantSearchDetail(contentNumber: String) -> FlowContributors {
        let reactor = SearchDetailReactor(contentNumber: contentNumber)
        let viewController = SearchDetailViewController(reactor: reactor)
        viewController.hidesBottomBarWhenPushed = true
        navigate(to: viewController, animated: true)

        return .one(
            flowContributor: .contribute(
                withNextPresentable: viewController,
                withNextStepper: viewController
            )
        )
    }

    private func navigateToClassificationResult(_ result: [String: PlantClassificationService.Confidence]) -> FlowContributors {
        let searchViewController = SearchViewController(classficationResult: result)
        searchViewController.hidesBottomBarWhenPushed = true
        navigate(to: searchViewController, animated: true)

        return .one(
            flowContributor: .contribute(
                withNextPresentable: searchViewController,
                withNextStepper: searchViewController
            )
        )
    }

    private func navigateToCameraClassification() -> FlowContributors {
        let cameraViewController = CameraClassificationViewController()
        navigate(to: cameraViewController, animated: true)

        return .one(
            flowContributor: .contribute(
                withNextPresentable: cameraViewController,
                withNextStepper: cameraViewController
            )
        )
    }

    private func updatePlantRegister(_ selectedPlant: SelectedPlant) -> FlowContributors {
        guard let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            return .none
        }

        if let registerViewController = navigationController.topViewController as? PlantRegisterViewController {
            registerViewController.updateSelectedPlant(selectedPlant)
            return .none
        }

        if let registerIndex = navigationController.viewControllers.lastIndex(where: { $0 is PlantRegisterViewController }),
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
        navigate(to: plantRegisterViewController, animated: true)

        return .one(
            flowContributor: .contribute(
                withNextPresentable: plantRegisterViewController,
                withNextStepper: plantRegisterViewController
            )
        )
    }
}

extension MainFlow {
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
