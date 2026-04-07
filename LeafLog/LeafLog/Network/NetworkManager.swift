//
//  NetworkManager.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/3/26.
//

import Alamofire
import Foundation
import XMLCoder

final class NetworkManager {
    static let shared = NetworkManager()

    private let session: Session
    private let decoder: XMLDecoder //XML 데이터용
    private let baseURL = "http://api.nongsaro.go.kr/service/garden"

    init(session: Session = .default) {
        self.session = session
        self.decoder = XMLDecoder()
        self.decoder.shouldProcessNamespaces = false
    }

    func fetchPlantList(apiKey: String, keyword: String, pageNo: Int = 1, numOfRows: Int = 10) async throws -> [PlantSummary] {
        let response: PlantListEnvelope = try await request(
            path: "gardenList",
            parameters: [
                "apiKey": apiKey,
                "sType": "sCntntsSj",
                "sText": keyword,
                "pageNo": String(pageNo),
                "numOfRows": String(numOfRows)
            ]
        )
        // HTTP 요청이 아닌 농사로 자체 API 확인(내부 resultCode 확인)
        try validate(header: response.response.header)
        // 검색 결과가 없으면 빈값 리턴
        return response.response.body?.items?.item?.values ?? []
    }

    func fetchPlantDetail(apiKey: String, contentNumber: String) async throws -> PlantDetail {
        let response: PlantDetailEnvelope = try await request(
            path: "gardenDtl",
            parameters: [
                "apiKey": apiKey,
                "cntntsNo": contentNumber // 목록 조회에서 받은 걸 여기 넣어서 상세 호출
            ]
        )
        // 성공여부 검사
        try validate(header: response.response.header)
        // 상세는 배열이 아니고 item 하나라서 에러 던짐
        guard let detail = response.response.body?.item else {
            throw NetworkError.emptyResult
        }

        return detail
    }
    
    // 공통 메서드
    // T가 PlantListEnvelope일 수도 있고 PlantDetailEnvelope일 수도 있음
    private func request<T: Decodable>(path: String, parameters: Parameters) async throws -> T {
        let url = "\(baseURL)/\(path)"

        do {
            let data = try await session
                .request(url, method: .get, parameters: parameters, encoding: URLEncoding.default) // GET 생성
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
