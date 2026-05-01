//
//  SceneDelegate.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import KakaoSDKAuth
import GoogleSignIn
import ReactorKit
import RxFlow
import RxRelay
import Dependencies
import OSLog

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private let logger = Logger(subsystem: "LeafLog", category: "SceneDelegate")
    let coordinator = FlowCoordinator()
    private let appStepper = AppStepper()
    @Dependency(\.notificationManager) private var notificationManager
    @Dependency(\.fcmManager) private var fcmManager
    @Dependency(\.appUpdateManager) private var appUpdateManager
    
    var window: UIWindow?
    private var isCheckingRequiredUpdate = false
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        // 카카오 처리
        if AuthApi.isKakaoTalkLoginUrl(url) {
            _ = AuthController.handleOpenUrl(url: url)
            return
        }
        
        // 구글 처리
        if GIDSignIn.sharedInstance.handle(url) {
            return
        }
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let appFlow = AppFlow(windowScene: windowScene)
        window = appFlow.window
        
        coordinator.coordinate(
            flow: appFlow,
            with: CompositeStepper(steppers: [
                OneStepper(withSingleStep: AppStep.splash),
                appStepper
            ])
        )
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        //Foreground에 진입할 때마다 알림 허용 권한 업데이트
        Task { [weak self] in
            do {
                try await self?.notificationManager.updateIsNotificationEnabled(to: nil)
            } catch {
                self?.logger.error("알림 허용 여부 저장 시 오류 발생: \(error.localizedDescription, privacy: .private)")
            }
        }

        Task { [weak self] in
            await self?.emitRequiredUpdateIfNeeded()
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
    }

    @MainActor
    private func emitRequiredUpdateIfNeeded() async {
        guard isCheckingRequiredUpdate == false else { return }
        guard window?.rootViewController is SplashViewController == false else { return }
        guard window?.rootViewController is UpdateRequiredViewController == false else { return }

        isCheckingRequiredUpdate = true
        defer { isCheckingRequiredUpdate = false }

        let updateState = await appUpdateManager.fetchUpdateState()

        guard case let .required(message, storeURL) = updateState else { return }

        appStepper.steps.accept(AppStep.updateRequired(message: message, storeURL: storeURL))
    }
}

private struct AppStepper: Stepper {
    let steps = PublishRelay<Step>()
}
