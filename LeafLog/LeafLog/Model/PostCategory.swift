//
//  PostCategory.swift
//  LeafLog
//
//  Created by 변예린 on 7/9/26.
//

import Foundation

nonisolated enum PostCategory: Int, Codable, CaseIterable, Sendable {
    case plantLife = 0
    case plantHelp
    case greenTrip

    var databaseValue: String {
        switch self {
        case .plantLife: "plant_life"
        case .plantHelp: "plant_help"
        case .greenTrip: "green_trip"
        }
    }

    init?(databaseValue: String) {
        switch databaseValue {
        case "plant_life":
            self = .plantLife
        case "plant_help":
            self = .plantHelp
        case "green_trip":
            self = .greenTrip
        default:
            return nil
        }
    }
    
    var title: String {
        switch self {
        case .plantLife: "식물 일상"
        case .plantHelp: "식물 고민"
        case .greenTrip: "초록별 여행"
        }
    }
}

extension PostCategory {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let databaseValue = try container.decode(String.self)

        guard let category = PostCategory(databaseValue: databaseValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "지원하지 않는 게시글 카테고리입니다."
            )
        }

        self = category
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(databaseValue)
    }
}
