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
    }
    
    static func getSecret(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            fatalError("\(key)를 Info.plist에서 찾을 수 없습니다.")
        }
        return value
    }

    static var supabaseURL: String { Self.getSecret(InfoKeys.url) }
    static var supabaseAnonKey: String { Self.getSecret(InfoKeys.anonKey) }
}
