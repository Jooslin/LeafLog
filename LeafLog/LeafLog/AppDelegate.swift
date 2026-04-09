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
import Auth
import Supabase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 구글 SDK 세팅
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: AppSecrets.googleClientID)
        
        // 카카오 SDK 세팅
        KakaoSDK.initSDK(appKey: AppSecrets.kakaoNativeAppKey)
        
        // 파이어베이스 설정
        FirebaseApp.configure()
        
        // 앱 실행 시 사용자에게 알림 허용 권한 받기
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        // Apple의 푸시 서버(APNs)에 앱을 등록하고 디바이스 토큰 발급을 요청함
        application.registerForRemoteNotifications()
        
        // 파이어베이스 Messaging 설정
        Messaging.messaging().delegate = self
        
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
    // 백그라운드에서 푸시 알림을 탭했을 때 실행
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token: \(deviceToken)")
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Foreground에서 알림이 오는 설정
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner])
    }
}

extension AppDelegate: MessagingDelegate {
    // 파이어베이스 MessagingDelegate 설정 - 앱 시작 시, 혹은 토큰이 갱신되었을 때 호출되는 함수
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        // 전달받은 토큰이 정상적으로 있는지 확인
        guard let validToken = fcmToken else { return }
        
        // Supabase 서버로 토큰 쏴주기
        Task {
            do {
                // 현재 로그인된 유저의 정보(세션)를 가져옴
                let session = try await SupabaseManager.shared.client.auth.session
                let currentUserId = session.user.id
                
                // profiles 테이블에서 현재 유저의 행을 찾아 fcm_token 값을 덮어씌움
                try await SupabaseManager.shared.client
                    .from("profiles")
                    .update(["fcm_token": validToken])
                    .eq("id", value: currentUserId)
                    .execute()
                
                print("✅ Supabase DB에 FCM 토큰이 성공적으로 저장되었습니다.")
                
            } catch {
                // 앱을 처음 켜서 아직 로그인이 안 된 경우
                print("⚠️ FCM 토큰 저장 보류 (로그인 전이거나 네트워크 에러): \(error.localizedDescription)")
            }
        }
    }
}
