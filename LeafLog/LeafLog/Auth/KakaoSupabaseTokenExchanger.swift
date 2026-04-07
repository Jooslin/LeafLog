//
//  KakaoSupabaseTokenExchanger.swift
//  LeafLog
//
//  Created by 김주희 on 4/5/26.
//

import Foundation

// 카카오 토큰을 Supabase와 교환해 유저정보 받아오기
struct KakaoSupabaseTokenExchanger {
    private let supabaseURL: String
    private let anonKey: String
    
    init(supabaseURL: String, anonKey: String) {
        self.supabaseURL = supabaseURL
        self.anonKey = anonKey
    }
    
    func exchange(idToken: String) async throws -> (accessToken: String, refreshToken: String) {
        guard let url = URL(string: "https://\(supabaseURL)/auth/v1/token?grant_type=id_token") else {
            throw AuthError.loginFailed("잘못된 Supabase URL입니다.")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "provider": "kakao",
            "id_token": idToken
        ])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorStr = String(data: data, encoding: .utf8) ?? "알 수 없는 에러"
            throw AuthError.loginFailed("Supabase API 통신 에러: \(errorStr)")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String else {
            throw AuthError.loginFailed("토큰 파싱 실패")
        }
        
        return (accessToken: accessToken, refreshToken: refreshToken)
    }
}
