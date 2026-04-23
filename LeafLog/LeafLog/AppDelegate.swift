//
//  AppDelegate.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import KakaoSDKCommon
import GoogleSignIn
import Firebase
import Dependencies
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    @Dependency(\.fcmManager) private var fcmManager
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 구글 SDK 세팅
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: AppSecrets.googleClientID)
        
        // 카카오 SDK 세팅
        KakaoSDK.initSDK(appKey: AppSecrets.kakaoNativeAppKey)
        
        // 파이어베이스 설정
        FirebaseApp.configure()
        fcmManager.setConfigs()
        
        // Apple의 푸시 서버(APNs)에 앱을 등록하고 디바이스 토큰 발급을 요청함
        application.registerForRemoteNotifications()
        
        // FCM Token 갱신
        fcmManager.syncCurrentFCMToken()
        return true
        }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
}

extension AppDelegate {
    // APNs 토큰이 발급되었을 때 실행 - registerForRemoteNotifications()가 완료된 이후 실행
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Firebase에 apns 토큰을 전달
        Messaging.messaging().apnsToken = deviceToken
    }
}
