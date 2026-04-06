//
//  Flow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import RxFlow
import RxSwift

/*
 RxFlow에서는 다음과 같은 용어들을 사용합니다.
 - Flow: 각 Flow는 앱 내에서의 네비게이션 영역을 의미합니다.
 - Step: 각 Step은 '앱의 네비게이션 상태(state)'를 의미합니다.
    -> "이 화면으로 가고싶어"라는 뜻이라기 보다는, "누군가 혹은 어떤 것이 이 동작을 했다"라는 의미로 보는 것이 적절합니다.
    -> "누군가 혹은 어떤 것이 이 동작을 했다"라는 state가 전달되면, RxFlow는 현재의 네비게이션 Flow에 알맞은 화면을 선택합니다.
 - Stepper: Steps를 뱉어낼 수 있는(emit) 존재입니다. Stepper는 Flow의 모든 네비게이션 동작을 트리거합니다.
 - Presentable: 나타내질 수 있는 (presented) 추상적 존재를 의미합니다. UIViewController와 Flow는 Presentable입니다.
 
 - NextFlowItem: Reactive 메커니즘 내에서, '새로운 Step'을 생성해낼 존재가 무엇인지 Coordinator에게 알려줍니다.(tell)
    -> withNextPresentable: 다음 Presentable을 의미합니다.
        => Steps는 Presentable이 존재해야 생성될 수 있습니다.
           Presentable 없이 Steps가 실행되지 않도록 하기 위해 Presentable의 존재도 함께 Coordinator에 알립니다.
    -> withNextStepper: 다음 Stepper(Step을 생성해낼 존재)를 의미합니다.
 
 - Coordinator: Flows와 Steps를 조합하는 역할을 합니다.
    -> RxFlow에서 구현해두었으므로 우리가 직접적으로 구현하지 않습니다. SceneDelegate에서 선언됩니다.
 */

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
                
                self.tabBarController.setViewControllers([plant, calendar, my], animated: true)
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
