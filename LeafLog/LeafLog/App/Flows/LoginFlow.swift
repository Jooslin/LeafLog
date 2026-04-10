//
//  LoginFlow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/10/26.
//

import UIKit
import RxFlow
import ReactorKit

final class LoginFlow: Flow {
    let window: UIWindow
    let navigationController = UINavigationController()
    
    var root: any Presentable { navigationController }
    
    init(window: UIWindow) {
        window.rootViewController = navigationController
        self.window = window
    }
    
    func navigate(to step: any RxFlow.Step) -> FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .main:
            return navigateToMain()
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}

extension LoginFlow {
    private func navigateToMain() -> FlowContributors {
        let tabBarController = UITabBarController()
        
        let plantTabFlow = PlantTabFlow()
        let calendarTabFlow = CalendarTabFlow()
        let myInfoTabFlow = MyInfoTabFlow()

        window.rootViewController = tabBarController
        
        // Flow를 준비 - 클로저는 Flow가 배치될 준비가 되었을 때(Flow의 첫 번째 화면이 선택되었을 때) 실행될 동작
        // Flow.use는 내부에서 Single 이벤트를 drive로 구독을 소비하므로 소비 완료 후 자동으로 구독이 해제되어 메모리 누수가 발생하지 않음
        Flows.use(plantTabFlow, calendarTabFlow, myInfoTabFlow, when: .created) { plant, calendar, my in
            plant.tabBarItem = UITabBarItem(
                title: "식물",
                image: UIImage(systemName: "leaf"),
                tag: 0
            )
            
            calendar.tabBarItem = UITabBarItem(
                title: "달력",
                image: UIImage(systemName: "calendar"),
                tag: 1
            )
            
            my.tabBarItem = UITabBarItem(
                title: "내 정보",
                image: UIImage(systemName: "person"),
                tag: 2
            )
            
            tabBarController.setViewControllers([plant, calendar, my], animated: true)
        }
        
        return .multiple(flowContributors: [
            .contribute(withNextPresentable: plantTabFlow, withNextStepper: OneStepper(withSingleStep: AppStep.plantTab)),
            .contribute(withNextPresentable: calendarTabFlow, withNextStepper: OneStepper(withSingleStep: AppStep.calendarTab)),
            .contribute(withNextPresentable: myInfoTabFlow, withNextStepper: OneStepper(withSingleStep: AppStep.myInfoTab))
        ])
    }
}
