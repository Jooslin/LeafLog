//
//  MainFlow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/10/26.
//

import UIKit
import RxFlow
import ReactorKit

final class MainFlow: Flow {
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
            
        case .record(let plantID, let date):
            return navigateToPlantRecord(plantID: plantID, date: date)
          
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
    
    private func navigateToPlantRecord(plantID: UUID, date: Date) -> FlowContributors {
        let viewController = PlantCareViewController(reactor: PlantCareReactor(plantID: plantID, selectedDate: date))
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
}
