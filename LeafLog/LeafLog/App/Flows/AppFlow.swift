//
//  Flow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import RxFlow
import RxSwift

final class AppFlow: Flow {
    
    let window: UIWindow
    let tabBarController = UITabBarController()
    
    var root: any RxFlow.Presentable { tabBarController }
    
    init(windowScene: UIWindowScene) {
        self.window = UIWindow(windowScene: windowScene)
        self.window.rootViewController = tabBarController
        self.window.makeKeyAndVisible()
    }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        // 정의한 AppStep일 때만 동작
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .main:
            let plantTabFlow = PlantTabFlow()
            let calendarTabFlow = PlantTabFlow()
            let myInfoTabFlow = PlantTabFlow()
            
            // Flow를 준비 - 클로저는 Flow가 배치될 준비가 되었을 때(Flow의 첫 번째 화면이 선택되었을 때) 실행될 동작
            Flows.use(plantTabFlow, calendarTabFlow, myInfoTabFlow, when: .ready) { plant, calendar, my in
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
                
                self.tabBarController.viewControllers = [plant, calendar, my]
            }
            
            return .multiple(flowContributors: [
                .contribute(withNextPresentable: plantTabFlow, withNextStepper: OneStepper(withSingleStep: AppStep.plantTab)),
                .contribute(withNextPresentable: calendarTabFlow, withNextStepper: OneStepper(withSingleStep: AppStep.calendarTab)),
                .contribute(withNextPresentable: myInfoTabFlow, withNextStepper: OneStepper(withSingleStep: AppStep.myInfoTab))
            ])
            
        default:
            return .none
        }
    }
    
    
}
