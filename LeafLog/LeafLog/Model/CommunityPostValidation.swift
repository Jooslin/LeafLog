//
//  CommunityPostValidation.swift
//  LeafLog
//
//  Created by OpenAI Codex on 8/3/26.
//

import Foundation

enum CommunityPostValidation {
    static let titleMaxCount = 50
    static let contentMaxCount = 1_000

    enum ValidationResult {
        case valid(title: String, content: String)
        case invalid(message: String)

        var isValid: Bool {
            if case .valid = self { return true }
            return false
        }
    }

    static func validate(
        title: String,
        content: String
    ) -> ValidationResult {
        let normalizedTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let isContentEmpty = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        guard !normalizedTitle.isEmpty else {
            return .invalid(message: "제목을 입력해주세요.")
        }

        guard normalizedTitle.count <= titleMaxCount else {
            return .invalid(
                message: "제목은 최대 50자까지 입력할 수 있어요."
            )
        }

        guard !isContentEmpty else {
            return .invalid(message: "내용을 입력해주세요.")
        }

        guard content.count <= contentMaxCount else {
            return .invalid(
                message: "내용은 최대 1,000자까지 입력할 수 있어요."
            )
        }

        return .valid(title: normalizedTitle, content: content)
    }
}
