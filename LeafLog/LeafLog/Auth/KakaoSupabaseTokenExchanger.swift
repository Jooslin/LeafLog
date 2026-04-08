//
//  KakaoSupabaseTokenExchanger.swift
//  LeafLog
//
//  Created by 김주희 on 4/5/26.
//

import Alamofire
import Foundation

protocol KakaoTokenExchanging {
    func exchange(idToken: String) async throws -> (accessToken: String, refreshToken: String)
}

// 카카오 토큰을 Supabase와 교환해 유저정보 받아오기
struct KakaoSupabaseTokenExchanger: KakaoTokenExchanging {
    private struct TokenExchangeResponse: Decodable {
        let accessToken: String
        let refreshToken: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
        }
    }

    private let supabaseURL: String
    private let anonKey: String
    
    init(supabaseURL: String, anonKey: String) {
        self.supabaseURL = supabaseURL
        self.anonKey = anonKey
    }
    
    func exchange(idToken: String) async throws -> (accessToken: String, refreshToken: String) {
        let endpoint = "https://\(supabaseURL)/auth/v1/token?grant_type=id_token"
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "apikey": anonKey
        ]
        let parameters: Parameters = [
            "provider": "kakao",
            "id_token": idToken
        ]

        let response = await AF.request(
            endpoint,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .validate(statusCode: 200..<300)
        .serializingData()
        .response

        switch response.result {
        case .success(let data):
            do {
                let tokenResponse = try JSONDecoder().decode(TokenExchangeResponse.self, from: data)
                return (tokenResponse.accessToken, tokenResponse.refreshToken)
            } catch {
                throw AuthError.sessionFailed("토큰 파싱 실패: \(error.localizedDescription)")
            }
        case .failure(let error):
            if let responseData = response.data,
               let errorMessage = String(data: responseData, encoding: .utf8),
               errorMessage.isEmpty == false {
                throw AuthError.sessionFailed("Supabase API 통신 에러: \(errorMessage)")
            }
            throw AuthError.sessionFailed("카카오 세션 생성 실패: \(error.localizedDescription)")
        }
    }
}
