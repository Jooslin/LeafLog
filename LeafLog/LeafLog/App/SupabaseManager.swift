//
//  SupabaseManager.swift
//  LeafLog
//
//  Created by 김주희 on 4/6/26.
//

import Foundation
import Supabase

final class SupabaseManager {
    
    static let shared = SupabaseManager()
    private init() {}
    
    let client: SupabaseClient = {
        let baseURL = getSecret(for: "SUPABASE_URL")
        let anonKey = getSecret(for: "SUPABASE_ANON_KEY")

        guard let supabaseURL = URL(string: "https://\(baseURL)") else {
            fatalError("유효하지 않은 Supabase URL입니다.")
        }

        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }()

    private static func getSecret(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty else {
            fatalError("\(key)를 Info.plist에서 찾을 수 없습니다.")
        }
        return value
    }
}
