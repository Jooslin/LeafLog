//
//  SupabaseManager.swift
//  LeafLog
//
//  Created by 김주희 on 4/6/26.
//

import Foundation
import Supabase
import Dependencies

final class SupabaseManager {
    private init() {}
    
    let client: SupabaseClient = {
        guard let supabaseURL = URL(string: "https://\(AppSecrets.supabaseURL)") else {
            fatalError("유효하지 않은 Supabase URL입니다.")
        }
        
        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: AppSecrets.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }()
}

extension SupabaseManager {
    // 유저 fcm 토큰 업데이트
    func updateFCMToken(_ validToken: String) {
        // Supabase 서버로 토큰 쏴주기
        Task {
            do {
                // 현재 로그인된 유저의 정보(세션)를 가져옴
                let currentUserId = client.auth.currentUser?.id
                
                // profiles 테이블에서 현재 유저의 행을 찾아 fcm_token 값을 덮어씌움
                try await client
                    .from("profiles")
                    .update(["fcm_token": validToken])
                    .eq("id", value: currentUserId)
                    .execute()
                
                print("✅ Supabase DB에 FCM 토큰이 성공적으로 저장되었습니다.")
                
            } catch {
                // 앱을 처음 켜서 아직 로그인이 안 된 경우 - 앱을 멈추거나 유저에게 에러를 알릴 필요가 없으므로 print문으로만 출력
                print("⚠️ FCM 토큰 저장 보류 (로그인 전이거나 네트워크 에러): \(error.localizedDescription)")
            }
        }
    }
    
    // 유저 알림 허용 여부 업데이트
    func updateIsNotificationEnabled(_ isEnabled: Bool) {
        Task {
            do {
                // 현재 로그인된 유저의 정보(세션)를 가져옴
                let currentUserId = client.auth.currentUser?.id
                
                // profiles 테이블에서 현재 유저의 행을 찾아 알림 허용 여부(is_notification_enabled) 값을 덮어씌움
                try await client
                    .from("profiles")
                    .update(["is_notification_enabled": isEnabled])
                    .eq("id", value: currentUserId)
                    .execute()
                
                print("✅ Supabase DB에 알림 허용 여부가 성공적으로 저장되었습니다.")
                
            } catch {
                // 앱을 처음 켜서 아직 로그인이 안 된 경우 - 앱을 멈추거나 유저에게 에러를 알릴 필요가 없으므로 print문으로만 출력
                print("⚠️ 알림 허용 여부 저장 보류 (로그인 전이거나 네트워크 에러): \(error.localizedDescription)")
            }
        }
    }
}

//MARK: Dependencies
extension SupabaseManager: DependencyKey {
    static var liveValue: SupabaseManager {
        SupabaseManager()
    }
}

extension DependencyValues {
    var supabaseManager: SupabaseManager {
        get { self[SupabaseManager.self] }
        set { self[SupabaseManager.self] = newValue }
    }
}
