//
//  NetworkManager.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/3/26.
//

import Alamofire
import Dependencies
import Foundation
import XMLCoder

final class NetworkManager {
    static let shared = NetworkManager()

    private let session: Session
    private let decoder: XMLDecoder //XML 데이터용
    private let baseURL = AppConfig.baseURL

    init(session: Session = .default) {
        self.session = session
        self.decoder = XMLDecoder()
        self.decoder.shouldProcessNamespaces = false
    }

    func fetchPlantList(
        keyword: String,
        searchType: PlantSearchType = .name,
        filterState: PlantFilterState = .init(),
        pageNo: Int = 1,
        numOfRows: Int = 10
    ) async throws -> [PlantSummary] {
        var parameters: Parameters = [
            "apiKey": AppConfig.apiKey,
            "sType": searchType.rawValue,
            "sText": keyword,
            "pageNo": String(pageNo),
            "numOfRows": String(numOfRows)
        ]

        for (kind, option) in filterState.selectedOptions {
            parameters[kind.requestParameterName] = option.code
        }

        let response: PlantListResponse = try await request(
            path: "gardenList",
            parameters: parameters
        )
        // HTTP 요청이 아닌 농사로 자체 API 확인(내부 resultCode 확인)
        try validate(header: response.header)

        return response.body.items.item
    }

    func fetchPlantDetail(contentNumber: String) async throws -> PlantDetail {
        let response: PlantDetailResponse = try await request(
            path: "gardenDtl",
            parameters: [
                "apiKey": AppConfig.apiKey,
                "cntntsNo": contentNumber // 목록 조회에서 받은 걸 여기 넣어서 상세 호출
            ]
        )
        // 성공여부 검사
        try validate(header: response.header)
        // 상세는 배열이 아니고 item 하나라서 에러 던짐
        guard let detail = response.body?.item else {
            throw NetworkError.emptyResult
        }

        return detail
    }
    
    // 필터 코드 목록 하나 보내는 거 분리
    func fetchFilterOptions(kind: PlantFilterKind) async throws -> [PlantFilterOption] {
        let response: PlantFilterListResponse = try await request(
            path: kind.listPath,
            parameters: [
                "apiKey": AppConfig.apiKey
            ]
        )

        try validate(header: response.header)
        return response.body?.items?.item ?? []
    }
    
    //필터 오래걸리니까 병렬로 보내기
    func fetchAllFilterOptions() async throws -> [PlantFilterKind: [PlantFilterOption]] {
        // withThrowingTaskGroup 이용해서 병렬 호출
        try await withThrowingTaskGroup(of: (PlantFilterKind, [PlantFilterOption]).self) { group in
            // 케이스 돌면서 작업 등록
            for kind in PlantFilterKind.allCases {
                group.addTask { [self] in
                    (kind, try await fetchFilterOptions(kind: kind))
                }
            }

            var results: [PlantFilterKind: [PlantFilterOption]] = [:]
            
            // 모이면 여기에 딕셔너리에 모음(어떤 버튼에 어떤 옵션인지 붙이기 쉽게)
            for try await (kind, options) in group {
                results[kind] = options
            }
            return results
        }
    }
    
    // 공통 메서드
    private func request<T: Decodable>(path: String, parameters: Parameters) async throws -> T {
        let url = "\(baseURL)/\(path)"
        let request = session.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default)

        do {
            let data = try await request // GET 생성
                .validate(statusCode: 200 ..< 300) // HTTP 상태코드
                .serializingData().value
            
            return try decoder.decode(T.self, from: data)
        } catch let error as AFError { //AE 에러 사용
            throw NetworkError.transportError(error)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    // API 에러 따로 처리
    private func validate(header: PlantResponseHeader) throws {
        guard header.resultCode == "00" else {
            throw NetworkError.apiError(code: header.resultCode, message: header.resultMsg)
        }
    }
}

extension NetworkManager {
    enum NetworkError: LocalizedError {
        case apiError(code: String, message: String) // API 내부 결과코드 실패
        case emptyResult
        case decodingFailed(Error) // XML 디코딩 실패
        case transportError(AFError) // 네트워크 요청 실패

        var errorDescription: String? {
            switch self {
            case let .apiError(code, message):
                return "API 오류가 발생했습니다. code: \(code), message: \(message)"
            case .emptyResult:
                return "조회 결과가 없습니다."
            case .decodingFailed(let error):
                return "XML 디코딩에 실패했습니다. \(error.localizedDescription)"
            case .transportError(let error):
                return "네트워크 요청에 실패했습니다. \(error.localizedDescription)"
            }
        }
    }
}

extension NetworkManager: DependencyKey {
    static var liveValue: NetworkManager {
        .shared
    }
}

extension DependencyValues {
    var networkManager: NetworkManager {
        get { self[NetworkManager.self] }
        set { self[NetworkManager.self] = newValue }
    }
}
