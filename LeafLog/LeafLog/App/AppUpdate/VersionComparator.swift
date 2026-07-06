//
//  VersionComparator.swift
//  LeafLog
//
//  Created by 김주희 on 5/1/26.
//

import Foundation

// MARK: - 앱 버전 비교

struct VersionComparator {
    static func isVersion(_ currentVersion: String, lowerThan targetVersion: String) -> Bool {
        let currentParts = versionParts(from: currentVersion)
        let targetParts = versionParts(from: targetVersion)
        let count = max(currentParts.count, targetParts.count) // 더 큰 길이를 기준으로

        for index in 0..<count {
            // 숫자가 비어있으면 0 삽입
            let currentValue = index < currentParts.count ? currentParts[index] : 0
            let targetValue = index < targetParts.count ? targetParts[index] : 0

            if currentValue < targetValue { return true } // 업데이트 필요
            if currentValue > targetValue { return false }
        }

        // 완전히 같으면 false
        return false
    }

    // '.'을 기준으로 숫자 배열로 나눠주는 메서드
    private static func versionParts(from version: String) -> [Int] {
        version
            .split(separator: ".")
            .map { Int($0) ?? 0 }
    }
}
