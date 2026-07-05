//
//  NonceGenerator.swift
//  LeafLog
//
//  Created by 김주희 on 4/6/26.
//

import CryptoKit
import Foundation

enum NonceGenerator {
    static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<length).compactMap { _ in charset.randomElement() })
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
