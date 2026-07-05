//
//  SearchReactor.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/8/26.
//

import Dependencies
import Foundation
import ReactorKit
import RxSwift

final class SearchReactor: AsyncReactor {
    
    // 사용자가 한 행동
    enum Action {
        case viewDidLoad
        case updateQuery(String) // 검색어 생김
        case updateSearchType(PlantSearchType) // 식물 이름 어떤식으로 검색하는지
        case updateFilter(PlantFilterKind, PlantFilterOption?) // 필터 바꿈
        case classificationQuery([String: PlantClassificationService.Confidence]) // AI 식별 결과 받음
        case selectPlant(SearchViewController.PlantSummaryItem)
    }
    
    // 상태를 어떻게 바꿀지에 대한 변화
    enum Mutation {
        case setLoading(Bool) // 검색 전후
        case setQuery(String) // 검색어 저장
        case setSearchType(PlantSearchType) // (영명, 학명, 식물명)
        case setFilterOptions([PlantFilterKind: [PlantFilterOption]]) // 옵션 전체
        case setFilter(PlantFilterKind, PlantFilterOption?) // 선택한 옵션
        case setPlants([SearchViewController.PlantSummaryItem])
        case setResultText(String) // 결과가 나올때
        case setSelectedPlant(SelectedPlant)
        case setErrorMessage(String)
        case setTitle(String) // 타이틀 헤더의 텍스트
    }
    
    // 화면이 어떤 상태인지 표현(처음 상태)
    struct State {
        var query: String = ""
        var searchType: PlantSearchType = .plantName // 어떤걸 기준으로 검색할지
        var filterOptions: [PlantFilterKind: [PlantFilterOption]] = [:]
        var filterState = PlantFilterState()
        var plants: [SearchViewController.PlantSummaryItem] = []
        var isLoading: Bool = false
        var resultText: String = "검색어를 입력해 주세요."
        @Pulse var selectedPlant: SelectedPlant? = nil
        @Pulse var errorMessage: String? = nil
        var titleText: String = "식물 검색"
    }
    
    @Dependency(\.networkManager) private var networkManager
    
    // 최초 상태
    let initialState = State()
    
    // Action -> Mutation -> State
    // Action을 받아서 어떤 Mutation을 만들지 결정
    func mutate(action: Action, continuation: MutationStreamContinuation) async throws {
        switch action {
        case .viewDidLoad:
            continuation.yield(.setLoading(true))
            await loadFilterOptions(continuation: continuation) // 서버에서 필터 목록가져오기
            continuation.yield(.setLoading(false))
            
            // 사용자가 텍스트 입력시 실행
        case .updateQuery(let rawQuery):
            let query = cleanQuery(rawQuery)
            
            // 비었을 때
            guard !query.isEmpty else {
                continuation.yield(.setQuery(""))
                continuation.yield(.setPlants([]))
                continuation.yield(.setLoading(false))
                continuation.yield(.setResultText("검색어를 입력해 주세요."))
                continuation.yield(.setTitle("식물 검색"))
                return
            }
            
            // 로딩 시작 - 네트워크 검색 - 로딩 종료
            continuation.yield(.setQuery(query))
            continuation.yield(.setLoading(true))
            await search(
                query: query,
                searchType: currentState.searchType,
                filterState: currentState.filterState,
                continuation: continuation
            )
            continuation.yield(.setLoading(false))
            
            
            // 검색타입 바꿀때
        case .updateSearchType(let searchType):
            let currentQuery = currentState.query
            
            // 검색어 없으면 그냥 바꾸기만
            guard !currentQuery.isEmpty else {
                continuation.yield(.setSearchType(searchType))
                return
            }
            
            // 검색어 있으면 검색해줌
            continuation.yield(.setSearchType(searchType))
            continuation.yield(.setLoading(true))
            await search(
                query: currentQuery,
                searchType: searchType,
                filterState: currentState.filterState,
                continuation: continuation
            )
            continuation.yield(.setLoading(false))
            
            
            // 필터 업데이트 할 때
        case let .updateFilter(kind, option):
            let nextFilterState = currentState.filterState.applyOption(option, for: kind)
            let currentQuery = currentState.query
            
            // 검색어 없으면 그냥 필터 바꿈
            guard !currentQuery.isEmpty else {
                continuation.yield(.setFilter(kind, option))
                return
            }
            
            // 필터 적용해서 다시 검색
            continuation.yield(.setFilter(kind, option))
            continuation.yield(.setLoading(true))
            await search(
                query: currentQuery,
                searchType: currentState.searchType,
                filterState: nextFilterState,
                continuation: continuation
            )
            continuation.yield(.setLoading(false))
            
            // AI 식물 식별 결과 사용할 때
        case let .classificationQuery(classificationResult):
            // 학명 검색
            continuation.yield(.setSearchType(.botanicalName))
            continuation.yield(.setLoading(true))
            await searchClassificationResult(classifications: classificationResult, continuation: continuation)
            continuation.yield(.setLoading(false))
            continuation.yield(.setTitle("검색 결과"))
            continuation.yield(.setSearchType(.plantName))

        case .selectPlant(let item):
            await fetchSelectedPlant(from: item, continuation: continuation)
        }
    }
    
    // Mutation을 받아서 새로운 State를 생성(상태 변경 함수)
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        // 검색 시작 전엔 로딩 켜기, 검색 작업이 끝나면 로딩 끄기
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setQuery(let query): // 검색어
            newState.query = query
        case .setSearchType(let searchType): // 검색 타입(결과)
            newState.searchType = searchType
        case .setFilterOptions(let filterOptions):
            newState.filterOptions = filterOptions
        case let .setFilter(kind, option):
            newState.filterState = newState.filterState.applyOption(option, for: kind)
        case .setPlants(let plants): //검색 결과 받아와서 목록에 저장(셀 그릴 때 필요)
            newState.plants = plants
        case .setResultText(let resultText):
            newState.resultText = resultText
        case .setSelectedPlant(let selectedPlant):
            newState.selectedPlant = selectedPlant
        case .setErrorMessage(let message):
            newState.errorMessage = message
        case .setTitle(let text):
            newState.titleText = text
        }
        
        return newState
    }
    
    // 서버에서 필터 목록을 가져와서 Mutation으로 바꿔주는 역할
    private func loadFilterOptions(continuation: MutationStreamContinuation) async {
        do {
            let options = try await networkManager.fetchAllFilterOptions()
            continuation.yield(.setFilterOptions(options))
        } catch {
            continuation.yield(.setResultText("필터 옵션 로드 실패: \(error.localizedDescription)"))
        }
    }
    
    private func search(
        query: String,
        searchType: PlantSearchType,
        filterState: PlantFilterState,
        continuation: MutationStreamContinuation
    ) async {
        do {
            let plants = try await networkManager.fetchPlantList(
                keyword: query,
                searchType: searchType,
                filterState: filterState,
                pageNo: 1,
                numOfRows: 10
            )
            
            // items 추가
            let items = plants.reduce([SearchViewController.PlantSummaryItem]()) {
                
                let item = SearchViewController.PlantSummaryItem(
                    contentNumber: $1.contentNumber,
                    name: $1.name,
                    imageURL: $1.imageURL,
                    thumbnailURL: $1.thumbnailURL,
                    confidence: .unknown,
                    primaryThumbnailURL: $1.primaryImageURL,
                    primaryImageURL: $1.primaryImageURL,
                    displayThumbnailURL: $1.displayThumbnailURL)
                
                return $0 + [item]
            }
            
            // 결과 처리
            let message: String
            if plants.isEmpty {
                message = "'\(query)' 검색 결과가 없습니다."
            } else {
                message = ""
            }
            
            continuation.yield(.setPlants(items))
            // 검색이 끝나면 결과 텍스트를 바꾸는 Mutation을 보냄
            continuation.yield(.setResultText(message))
            // 에러 처리
        } catch {
            continuation.yield(.setPlants([]))
            continuation.yield(.setResultText("검색 실패: \(error.localizedDescription)"))
        }
    }
    
    private func cleanQuery(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func fetchSelectedPlant(
        from item: SearchViewController.PlantSummaryItem,
        continuation: MutationStreamContinuation
    ) async {
        do {
            let detail = try await networkManager.fetchPlantDetail(contentNumber: item.contentNumber)
            let selectedPlant = SelectedPlant(
                name: item.name,
                contentNumber: item.contentNumber,
                detail: detail,
                category: nil
            )
            continuation.yield(.setSelectedPlant(selectedPlant))
        } catch {
            let message: String
            if let networkError = error as? NetworkManager.NetworkError {
                message = networkError.errorDescription ?? "식물 정보를 불러오지 못했습니다."
            } else {
                message = error.localizedDescription
            }

            continuation.yield(.setErrorMessage(message))
        }
    }
}

extension SearchReactor {
    private func searchClassificationResult(
        classifications: [String: PlantClassificationService.Confidence],
        continuation: MutationStreamContinuation
    ) async {
        guard !classifications.isEmpty else {
            // 결과 처리
            continuation.yield(.setPlants([]))
            continuation.yield(.setResultText("AI 검색 결과 식물을 찾지 못했습니다."))
            return
        }
        
        do {
            // 일치율 높은 순으로 정렬한 식물 학명 배열
            let keywords = classifications
                .sorted(by: {
                    $0.value.rawValue < $1.value.rawValue})
                .map { String($0.key) }
            
            // API 검색 결과
            let plants = try await networkManager.fetchPlantListBy(keywords: keywords)

            let items = plants.reduce([SearchViewController.PlantSummaryItem]()) {
                guard let confidence = classifications[$1.key] else { return $0 }
                
                let item = SearchViewController.PlantSummaryItem(
                    contentNumber: $1.value.contentNumber,
                    name: $1.value.name,
                    imageURL: $1.value.imageURL,
                    thumbnailURL: $1.value.thumbnailURL,
                    confidence: confidence,
                    primaryThumbnailURL: $1.value.primaryImageURL,
                    primaryImageURL: $1.value.primaryImageURL,
                    displayThumbnailURL: $1.value.displayThumbnailURL)

                return $0 + [item]
            }

            let message: String = items.isEmpty ? "AI 검색 결과 식물을 찾지 못했습니다." : ""
            
            continuation.yield(.setPlants(items))
            // 검색이 끝나면 결과 텍스트를 바꾸는 Mutation을 보냄
            continuation.yield(.setResultText(message))
            // 에러 처리
        } catch {
            continuation.yield(.setPlants([]))
            continuation.yield(.setResultText("검색 실패: \(error.localizedDescription)"))
        }
    }
}
