//
//  PlantResponse.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/6/26.
//

import Foundation

enum PlantSearchType: String, CaseIterable {
    case name = "sCntntsSj"
    case botanicalName = "sPlntbneNm"
    case englishName = "sPlntzrNm"

    var title: String {
        switch self {
        case .name:
            return "식물명"
        case .botanicalName:
            return "학명"
        case .englishName:
            return "영명"
        }
    }
}

// 검색용 API 모델
struct PlantListResponse: Decodable {
    let header: PlantResponseHeader
    let body: PlantListBody
}

struct PlantListBody: Decodable {
    let items: PlantListItems
}

struct PlantListItems: Decodable {
    let item: [PlantSummary]
    let numOfRows: String?
    let pageNo: String?
    let totalCount: String?

    private enum CodingKeys: String, CodingKey {
        case item
        case numOfRows
        case pageNo
        case totalCount
    }
    
    // 기본 디코더 대신 사용 할 것이기 때문에 init
    // XML은 item으로 올 수도 있고 [item]올 수도 있어서 이렇게 처리함
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let items = try? container.decode([PlantSummary].self, forKey: .item) {
            item = items
        } else if let singleItem = try? container.decode(PlantSummary.self, forKey: .item) {
            item = [singleItem]
        } else {
            item = []
        }
        
        numOfRows = try container.decodeIfPresent(String.self, forKey: .numOfRows)
        pageNo = try container.decodeIfPresent(String.self, forKey: .pageNo)
        totalCount = try container.decodeIfPresent(String.self, forKey: .totalCount)
    }
}

// 디테일 API 응답
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
