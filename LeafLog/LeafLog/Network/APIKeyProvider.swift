//
//  APIKeyProvider.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/7/26.
//

import Foundation

struct APIKeyProvider {
    func nongsaroAPIKey() -> String {
        AppConfig.apiKey
    }
}
