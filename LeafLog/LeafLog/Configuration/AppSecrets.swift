//
//  AppSecrets.swift
//  LeafLog
//
//  Created by 김주희 on 4/6/26.
//

import Foundation

enum AppSecrets {
    
    private enum InfoKeys {
        static let url = "SUPABASE_URL"
        static let anonKey = "SUPABASE_ANON_KEY"
        static let kakaoNativeAppKey = "KAKAO_NATIVE_APP_KEY"
        static let googleClientID = "CLIENT_ID"
    }
    
    
    static func getSecret(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            fatalError("\(key)를 Info.plist에서 찾을 수 없습니다.")
        }
        return value
    }

    
    static var supabaseURL: String { Self.getSecret(InfoKeys.url) }
    static var supabaseAnonKey: String { Self.getSecret(InfoKeys.anonKey) }
    static var kakaoNativeAppKey: String {
        let key = Self.getSecret(InfoKeys.kakaoNativeAppKey)
        
        if key.isEmpty || key.contains("$") {
            assertionFailure("Info.plist가 가짜 \(key)값을 가지고 있습니다.")
            return ""
        }
        return key
    }
    static var googleClientID: String {
        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plistDict = NSDictionary(contentsOfFile: plistPath) as? [String: Any],
              let clientID = plistDict[InfoKeys.googleClientID] as? String,
              !clientID.isEmpty else {
            assertionFailure("GoogleService-Info.plist 파일을 찾을 수 없거나 'CLIENT_ID'값이 존재하지 않습니다.")
            return ""
        }
        return clientID
    }
}
