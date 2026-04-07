//
//  AppConfig.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/7/26.
//

import Foundation

enum AppConfig {
    static var apiKey: String {
        value(for: "NongsaroAPIKey")
    }

    static var baseURL: String {
        value(for: "NongsaroBaseURL")
    }
    
    // 배포를 대비해서 넣음
    static var environment: String {
        value(for: "AppEnvironment")
    }
    
    // 실제 Bundle.main에서 값을 꺼냄
    private static func value(for key: String) -> String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            value.isEmpty == false
        else {
            // TODO: 오류처리 따로 하기
            fatalError("\(key)를 info.plist에서 찾을 수 없습니다.")
        }

        return value
    }
}
