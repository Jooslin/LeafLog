//
//  Flow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import RxFlow
import RxSwift
import ReactorKit

/*
 RxFlow에서는 다음과 같은 용어들을 사용합니다.
 - Flow: 각 Flow는 앱 내에서의 네비게이션 영역을 의미합니다.
 - Step: 각 Step은 '앱의 네비게이션 상태(state)'를 의미합니다.
    -> "이 화면으로 가고싶어"라는 뜻이라기 보다는, "누군가 혹은 어떤 것이 이 동작을 했다"라는 의미로 보는 것이 적절합니다.
    -> "누군가 혹은 어떤 것이 이 동작을 했다"라는 state가 전달되면, RxFlow는 현재의 네비게이션 Flow에 알맞은 화면을 선택합니다.
 - Stepper: Steps를 방출할 수 있는(emit) 존재입니다. Stepper는 Flow의 모든 네비게이션 동작을 트리거합니다.
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
    let loginNavigationController = UINavigationController()
    
    var root: any RxFlow.Presentable { window }
    
    init(windowScene: UIWindowScene) {
        self.window = UIWindow(windowScene: windowScene)
        self.window.makeKeyAndVisible()
    }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        // 정의한 AppStep일 때만 동작
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .splash:
            let splashViewController = SplashViewController()
            window.rootViewController = splashViewController
            
            return .one(
                flowContributor: .contribute(
                    withNextPresentable: splashViewController,
                    withNextStepper: splashViewController
                )
            )
            
        case .loginRequired:
            return navigateToLogin()

        case .main:
            return navigateToMain()
            
        case .alert(let title, let message):
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))

            let presenter: UIViewController?
            if let selected = tabBarController.selectedViewController {
                presenter = selected
            } else {
                presenter = window.rootViewController
            }

            presenter?.present(alert, animated: true)
            return .none

            
        default:
            return .none
        }
    }
    
    func navigate(to viewController: UIViewController, animated: Bool) {
        if let navigationController = tabBarController.selectedViewController as? UINavigationController {
            navigationController.pushViewController(viewController, animated: animated)
        } else {
            tabBarController.selectedViewController?.present(viewController, animated: animated, completion: nil)
        }
    }
    
    private func present(_ viewController: UIViewController, animated: Bool) {
        tabBarController.selectedViewController?.present(viewController, animated: animated, completion: nil)
    }
}

extension AppFlow {
    private func navigateToLogin() -> FlowContributors {
        let loginFlow = LoginFlow(window: self.window)
        let viewController = LoginViewController()
        viewController.reactor = LoginReactor()

        Flows.use(loginFlow, when: .created) { login in
            guard let nav = login as? UINavigationController else { return }
            
            nav.setViewControllers([viewController], animated: true)
        }
        
        return .one(
            flowContributor: .contribute(
                withNextPresentable: loginFlow,
                withNextStepper: viewController)
        )
    }
    
    private func navigateToMain() -> FlowContributors {
        let mainFlow = MainFlow(window: window)
        return .one(
            flowContributor: .contribute(
                withNextPresentable: mainFlow,
                withNextStepper: OneStepper(withSingleStep: AppStep.main))
            )
    }
}
