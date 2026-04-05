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
        <#code#>
    }
    
    
}
