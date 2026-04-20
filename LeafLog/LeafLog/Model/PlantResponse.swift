//
//  PlantResponse.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/6/26.
//

import Foundation

enum PlantSearchType: String, CaseIterable {
    case plantName = "sCntntsSj"
    case botanicalName = "sPlntbneNm"
    case englishName = "sPlntzrNm"

    var title: String {
        switch self {
        case .plantName:
            return "식물명"
        case .botanicalName:
            return "학명"
        case .englishName:
            return "영명"
        }
    }
}

// 필터링 검색을 위한 이넘 정의
enum PlantFilterKind: CaseIterable, Hashable {
    case searchType
    case light
    case growthStyle
    case leafColor
    case leafPattern
    case flowerColor
    case fruitColor
    case bloomingSeason
    case winterMinTemperature
    case waterCycle
    
    // UI 표시형
    var title: String {
        switch self {
        case .searchType:
            return "검색기준"
        case .light:
            return "광도요구"
        case .growthStyle:
            return "생육형태"
        case .leafColor:
            return "잎색"
        case .leafPattern:
            return "잎무늬"
        case .flowerColor:
            return "꽃색"
        case .fruitColor:
            return "열매색"
        case .bloomingSeason:
            return "꽃피는 계절"
        case .winterMinTemperature:
            return "겨울최저온도"
        case .waterCycle:
            return "물주기"
        }
    }
    
    // API 요청path
    var listPath: String {
        switch self {
        case .searchType: // 검색 타입 제외
            return ""
        case .light:
            return "lightList"
        case .growthStyle:
            return "grwhstleList"
        case .leafColor:
            return "lefcolrList"
        case .leafPattern:
            return "lefmrkList"
        case .flowerColor:
            return "flclrList"
        case .fruitColor:
            return "fmldecolrList"
        case .bloomingSeason:
            return "ignSeasonList"
        case .winterMinTemperature:
            return "winterLwetList"
        case .waterCycle:
            return "waterCycleList"
        }
    }
    
    // 파라미터
    var requestParameterName: String {
        switch self {
        case .searchType: // 검색 타입 제외
            return ""
        case .light:
            return "lightChkVal"
        case .growthStyle:
            return "grwhstleChkVal"
        case .leafColor:
            return "lefcolrChkVal"
        case .leafPattern:
            return "lefmrkChkVal"
        case .flowerColor:
            return "flclrChkVal"
        case .fruitColor:
            return "fmldecolrChkVal"
        case .bloomingSeason:
            return "ignSeasonChkVal"
        case .winterMinTemperature:
            return "winterLwetChkVal"
        case .waterCycle:
            return "waterCycleSel"
        }
    }
    
    //
    var usesServerProvidedOptions: Bool {
        self != .searchType
    }
}

// 코드는 숫자, name은 사용자 표시용
struct PlantFilterOption: Decodable, Equatable {
    let code: String
    let name: String

    private enum CodingKeys: String, CodingKey {
        case code
        case name = "codeNm"
    }
}

// 고른 필터로 상태
struct PlantFilterState: Equatable {
    var selectedOptions: [PlantFilterKind: PlantFilterOption] = [:]

    var isEmpty: Bool {
        selectedOptions.isEmpty
    }

    func option(for kind: PlantFilterKind) -> PlantFilterOption? {
        selectedOptions[kind]
    }

    func applyOption(_ option: PlantFilterOption?, for kind: PlantFilterKind) -> PlantFilterState {
        var next = self
        next.selectedOptions[kind] = option
        if option == nil {
            next.selectedOptions.removeValue(forKey: kind)
        }
        return next
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

        do {
            item = try container.decode([PlantSummary].self, forKey: .item)
        } catch DecodingError.typeMismatch {
            // 배열 디코딩 실패 시 단일 객체로 시도
            let singleItem = try container.decode(PlantSummary.self, forKey: .item)
            item = [singleItem]
        } catch let error as DecodingError {
            switch error {
            case .keyNotFound, .valueNotFound:
                item = []
            default:
                throw error
            }
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


// 사진 파일 API 응답
struct PlantFileResponse: Decodable {
    let header: PlantResponseHeader
    let body: PlantFileBody?
}

struct PlantFileBody: Decodable {
    let items: PlantFileItems?
}

struct PlantFileItems: Decodable {
    let item: [PlantFileItem]

    private enum CodingKeys: String, CodingKey {
        case item
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            item = try container.decode([PlantFileItem].self, forKey: .item)
        } catch DecodingError.typeMismatch {
            let singleItem = try container.decode(PlantFileItem.self, forKey: .item)
            item = [singleItem]
        } catch let error as DecodingError {
            switch error {
            case .keyNotFound, .valueNotFound:
                item = []
            default:
                throw error
            }
        }
    }
}

// 필터용 요청
struct PlantFilterListResponse: Decodable {
    let header: PlantResponseHeader
    let body: PlantFilterListBody?
}

struct PlantFilterListBody: Decodable {
    let items: PlantFilterItems?
}

// 실제 필터용 옵션 담는 곳
struct PlantFilterItems: Decodable {
    let item: [PlantFilterOption]

    private enum CodingKeys: String, CodingKey {
        case item
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            item = try container.decode([PlantFilterOption].self, forKey: .item)
        } catch DecodingError.typeMismatch {
            let singleItem = try container.decode(PlantFilterOption.self, forKey: .item)
            item = [singleItem]
        } catch let error as DecodingError {
            switch error {
            case .keyNotFound, .valueNotFound:
                item = []
            default:
                throw error
            }
        }
    }
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

    var primaryThumbnailURL: String? {
        thumbnailURL?.firstCleanedValue
    }

    var primaryImageURL: String? {
        imageURL?.firstCleanedValue
    }

    var displayThumbnailURL: String? {
        primaryThumbnailURL ?? primaryImageURL
    }

    private enum CodingKeys: String, CodingKey {
        case contentNumber = "cntntsNo"
        case name = "cntntsSj"
        case imageURL = "rtnFileUrl"
        case thumbnailURL = "rtnThumbFileUrl"
    }
}

struct PlantDetail: Decodable {
    let contentNumber: String? // 넘버
    let familyName: String? // 과명
    let origin: String? // 원산지 정보
    let winterMinimumTemperature: String? // 겨울 최저 온도
    let springWaterCycle: String? // 봄 물주기
    let summerWaterCycle: String? // 여름 물주기
    let autumnWaterCycle: String? // 가을 물주기
    let winterWaterCycle: String? // 겨울 물주기
    let lightDemand: String?// 광도요구
    let placement: String? // 장소 추천
    let growStyle: String? // 생육 형태
    let leafColor: String? // 잎색
    let leafMark: String? // 잎 무늬
    let flowerColor: String? // 꽃색
    let flowerSeason: String? // 꽃피는 계절
    let fruitColor: String?// 과일 색
    let fruitSeason: String? // 과일 계절

    private enum CodingKeys: String, CodingKey {
        case contentNumber = "cntntsNo" // 넘버
        case familyName = "fmlCodeNm" // 과명
        case origin = "orgplceInfo" // 원산지 정보
        case winterMinimumTemperature = "winterLwetTpCodeNm" // 겨울 최저 온도
        case springWaterCycle = "watercycleSprngCodeNm" // 봄 물주기
        case summerWaterCycle = "watercycleSummerCodeNm" // 여름 물주기
        case autumnWaterCycle = "watercycleAutumnCodeNm" // 가을 물주기
        case winterWaterCycle = "watercycleWinterCodeNm" // 겨울 물주기
        case lightDemand = "lighttdemanddoCodeNm" // 광도요구
        case placement = "postngplaceCodeNm" // 장소 추천
        case growStyle = "grwhstleCodeNm" // 생육 형태
        case leafColor = "lefcolrCodeNm" // 잎색
        case leafMark = "lefmrkCodeNm" // 잎 무늬
        case flowerColor = "flclrCodeNm" // 꽃색
        case flowerSeason = "ignSeasonCodeNm" // 꽃피는 계절
        case fruitColor = "fmldecolrCodeNm" // 과일 색
        case fruitSeason = "fmldeSeasonCodeNm" // 과일 계절
    }
}

struct PlantFileItem: Decodable, Equatable {
    let contentNumber: String?
    let name: String?
    let fileCode: String?
    let fileCodeName: String?
    let fileSequence: String?
    let fileURL: String?
    let imageDescription: String?
    let imageCode: String?
    let imageCodeName: String?
    let originalFileName: String?
    let thumbnailURL: String?

    var isImage: Bool {
        fileCodeName == "이미지" || fileCode == "185002"
    }

    var primaryThumbnailURL: String? {
        thumbnailURL?.firstCleanedValue
    }

    var primaryFileURL: String? {
        fileURL?.firstCleanedValue
    }

    var displayImageURL: String? {
        primaryFileURL ?? primaryThumbnailURL
    }

    private enum CodingKeys: String, CodingKey {
        case contentNumber = "cntntsNo"
        case name = "cntntsSj"
        case fileCode = "rtnFileSeCode"
        case fileCodeName = "rtnFileSeCodeName"
        case fileSequence = "rtnFileSn"
        case fileURL = "rtnFileUrl"
        case imageDescription = "rtnImageDc"
        case imageCode = "rtnImgSeCode"
        case imageCodeName = "rtnImgSeCodeName"
        case originalFileName = "rtnOrginlFileNm"
        case thumbnailURL = "rtnThumbFileUrl"
    }
}

private extension String {
    var firstCleanedValue: String? {
        components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
    }
}
