//
//  MyPlant.swift
//  LeafLog
//
//  Created by OpenAI Codex on 4/13/26.
//

import Foundation
import UIKit

// MARK: - 식물 카테고리 Enum
enum PlantCategory: String, Codable, CaseIterable {
    case upright = "직립형"
    case shrub = "관목형"
    case vine = "덩굴성"
    case grass = "풀모양"
    case rosette = "로제트형"
    case succulent = "다육형"
    case other = "기타"

    // 카테고리 별 식물 기본 이미지 (사용자 등록 이미지가 없을 때 대체 이미지)
    var defaultImageAssetName: String {
        switch self {
        case .upright:
            return "plantCategoryUpright"
        case .shrub:
            return "plantCategoryShrub"
        case .vine:
            return "plantCategoryVine"
        case .grass:
            return "plantCategoryGrass"
        case .rosette:
            return "plantCategoryRossette"
        case .succulent:
            return "plantCategorySucculent"
        case .other:
            return "plantCategoryOther"
        }
    }
}


// MARK: - 식물 위치 Enum
enum PlantLocation: String, Codable, CaseIterable {
    case livingRoom = "거실"
    case bedroom = "침실"
    case kitchen = "주방"
    case veranda = "베란다"
    case bathroom = "화장실"
    case entrance = "현관"
    case other = "기타"
}


// MARK: - 사용자 Input Model
// VC에서 PlantRegistrationService로 전달할 때 사용
struct PlantCreateInput {
    let id: UUID = UUID()
    let category: PlantCategory
    let location: PlantLocation?
    let nickname: String
    let speciesName: String?
    let contentNumber: String?
    let image: UIImage?
    let wateringIntervalDays: Int
    let lastWateredAt: Date
}

// MARK: - 사용자 Update Input Model
// VC에서 PlantRegistrationService로 전달할 때 사용
struct PlantUpdateInput {
    let id: UUID // 수정할 식물의 ID
    let category: PlantCategory
    let location: PlantLocation?
    let nickname: String?
    let speciesName: String?
    let contentNumber: String?
    
    let image: UIImage? // 사용자가 새로 선택한 이미지 (없으면 nil)
    let existingImagePath: String? // 기존에 저장되어 있던 이미지 경로 (새 이미지가 없을 때 유지)
    
    let wateringIntervalDays: Int
    let lastWateredAt: Date
}

// MARK: - 앱 내에서 전반적으로 사용할 내 식물 모델
struct MyPlant: Codable, Hashable {
    let id: UUID // 식물 자체 고유 ID
    let userID: UUID
    let category: PlantCategory
    let location: PlantLocation?
    let nickname: String?
    let speciesName: String
    let imagePath: String?
    let wateringIntervalDays: Int
    let lastWateredAt: Date
    let healthStatus: String
    let guideEnabled: Bool
    let createdAt: Date
    let updatedAt: Date
    let contentNumber: String?

    // 기본 이미지
    var defaultImageAssetName: String {
        category.defaultImageAssetName // 기본 이미지
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case category
        case location
        case nickname
        case speciesName = "species_name"
        case imagePath = "image_path"
        case wateringIntervalDays = "watering_interval_days"
        case lastWateredAt = "last_watered_at"
        case healthStatus = "health_status"
        case guideEnabled = "guide_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case contentNumber
    }
}
