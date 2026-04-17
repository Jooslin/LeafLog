//
//  ApplicationClient.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/18/26.
//

import Dependencies
import UIKit

private enum UIApplicationKey: DependencyKey {
    @MainActor
    static let liveValue = UIApplication.shared
}

extension DependencyValues {
    @MainActor
    var uiApplication: UIApplication {
        get { self[UIApplicationKey.self] }
        set { self[UIApplicationKey.self] = newValue }
    }
}
