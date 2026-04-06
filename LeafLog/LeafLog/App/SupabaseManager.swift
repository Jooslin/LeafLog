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
