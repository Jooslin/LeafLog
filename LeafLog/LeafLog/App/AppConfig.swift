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

    private static func value(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            value.isEmpty == false
        else {
            fatalError("\(key)를 info.plist에서 찾을 수 없습니다.")
        }

        return value
    }
}
