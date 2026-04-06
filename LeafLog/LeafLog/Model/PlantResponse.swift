//
//  PlantResponse.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/6/26.
//

import Foundation

// 공통 XML 래퍼
struct PlantListEnvelope: Decodable {
    let response: PlantListResponse
}

struct PlantListResponse: Decodable {
    let header: PlantResponseHeader
    let body: PlantListBody?
}

struct PlantListBody: Decodable {
    let items: PlantListItems?
}

// item이 여러개일 때 처리해주는 경우
struct PlantListItems: Decodable {
    let item: SingleOrArray<PlantSummary>?
}

struct PlantDetailEnvelope: Decodable {
    let response: PlantDetailResponse
}

struct PlantDetailResponse: Decodable {
    let header: PlantResponseHeader
    let body: PlantDetailBody?
}

struct PlantDetailBody: Decodable {
    let item: PlantDetail?
}

struct PlantResponseHeader: Decodable {
    let resultCode: String
    let resultMsg: String
}

// 실제 데이터 모델
struct PlantSummary: Decodable {
    let contentNumber: String
    let name: String
    let imageURL: String?
    let thumbnailURL: String?

    private enum CodingKeys: String, CodingKey {
        case contentNumber = "cntntsNo"
        case name = "cntntsSj"
        case imageURL = "rtnFileUrl"
        case thumbnailURL = "rtnThumbFileUrl"
    }
}

struct PlantDetail: Decodable {
    let contentNumber: String
    let botanicalName: String?
    let englishName: String?
    let distributionName: String?
    let familyName: String?
    let origin: String?
    let advice: String?
    let growthHeight: String?
    let growthWidth: String?
    let leafStyle: String?
    let toxicity: String?
    let propagationSeason: String?
    let manageLevel: String?
    let growthSpeed: String?
    let growthTemperature: String?
    let winterMinimumTemperature: String?
    let humidity: String?
    let fertilizer: String?
    let soil: String?
    let springWaterCycle: String?
    let summerWaterCycle: String?
    let autumnWaterCycle: String?
    let winterWaterCycle: String?
    let pestManagement: String?
    let specialManagement: String?
    let functionality: String?
    let lightDemand: String?
    let placement: String?

    private enum CodingKeys: String, CodingKey {
        case contentNumber = "cntntsNo"
        case botanicalName = "plntbneNm"
        case englishName = "plntzrNm"
        case distributionName = "distbNm"
        case familyName = "fmlNm"
        case origin = "orgplceInfo"
        case advice = "adviseInfo"
        case growthHeight = "growthHgInfo"
        case growthWidth = "growthAraInfo"
        case leafStyle = "lefStleInfo"
        case toxicity = "toxctyInfo"
        case propagationSeason = "prpgtEraInfo"
        case manageLevel = "managelevelCodeNm"
        case growthSpeed = "grwtveCodeNm"
        case growthTemperature = "grwhTpCodeNm"
        case winterMinimumTemperature = "winterLwetTpCodeNm"
        case humidity = "hdCodeNm"
        case fertilizer = "frtlzrInfo"
        case soil = "soilInfo"
        case springWaterCycle = "watercycleSprngCodeNm"
        case summerWaterCycle = "watercycleSummerCodeNm"
        case autumnWaterCycle = "watercycleAutumnCodeNm"
        case winterWaterCycle = "watercycleWinterCodeNm"
        case pestManagement = "dlthtsManageInfo"
        case specialManagement = "speclmanageInfo"
        case functionality = "fncltyInfo"
        case lightDemand = "lighttdemanddoCodeNm"
        case placement = "postngplaceCodeNm"
    }
}


struct SingleOrArray<Element: Decodable>: Decodable {
    let values: [Element]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let array = try? container.decode([Element].self) {
            values = array
            return
        }

        if let single = try? container.decode(Element.self) {
            values = [single]
            return
        }

        values = []
    }
}
