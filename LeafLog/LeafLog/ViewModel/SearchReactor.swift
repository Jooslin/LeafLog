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

final class SearchReactor: Reactor {
    
    // 사용자가 한 행동
    enum Action {
        case viewDidLoad
        case updateQuery(String) // 검색어 생김
        case updateSearchType(PlantSearchType) // 식물 이름 어떤식으로 검색하는지
        case updateFilter(PlantFilterKind, PlantFilterOption?) // 필터 바꿈
    }
    
    // 상태를 어떻게 바꿀지에 대한 변화
    enum Mutation {
        case setLoading(Bool) // 검색 전후
        case setQuery(String) // 검색어 저장
        case setSearchType(PlantSearchType) // (영명, 학명, 식물명)
        case setFilterOptions([PlantFilterKind: [PlantFilterOption]]) // 옵션 전체
        case setFilter(PlantFilterKind, PlantFilterOption?) // 선택한 옵션
        case setPlants([PlantSummary])
        case setResultText(String) // 결과가 나올때
    }
    
    // 화면이 어떤 상태인지 표현(처음 상태)
    struct State {
        var query: String = ""
        var searchType: PlantSearchType = .plantName // 어떤걸 기준으로 검색할지
        var filterOptions: [PlantFilterKind: [PlantFilterOption]] = [:]
        var filterState = PlantFilterState()
        var plants: [PlantSummary] = []
        var isLoading: Bool = false
        var resultText: String = "검색어를 입력해 주세요."
    }

    @Dependency(\.networkManager) private var networkManager
    
    // 최초 상태
    let initialState = State()
    
    // Action -> Mutation -> State
    // Action을 받아서 어떤 Mutation을 만들지 결정
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .concat([
                .just(.setLoading(true)),
                loadFilterOptions(), // 서버에서 필터 목록가져오기
                .just(.setLoading(false))
            ])

            // 사용자가 텍스트 입력시 실행
        case .updateQuery(let rawQuery):
            let query = cleanQuery(rawQuery)
            
            // 비었을 때
            guard !query.isEmpty else {
                return .concat([
                    .just(.setQuery("")),
                    .just(.setPlants([])),
                    .just(.setLoading(false)),
                    .just(.setResultText("검색어를 입력해 주세요."))
                ])
            }
            
            // 로딩 시작 - 네트워크 검색 - 로딩 종료
            return .concat([
                .just(.setQuery(query)),
                .just(.setLoading(true)),
                search(
                    query: query,
                    searchType: currentState.searchType,
                    filterState: currentState.filterState
                ),
                .just(.setLoading(false))
            ])
            
            
            // 검색타입 바꿀때
        case .updateSearchType(let searchType):
            let currentQuery = currentState.query
            
            // 검색어 없으면 그냥 바꾸기만
            guard !currentQuery.isEmpty else {
                return .just(.setSearchType(searchType))
            }
            
            // 검색어 있으면 검색해줌
            return .concat([
                .just(.setSearchType(searchType)),
                .just(.setLoading(true)),
                search(
                    query: currentQuery,
                    searchType: searchType,
                    filterState: currentState.filterState
                ),
                .just(.setLoading(false))
            ])
            
            
            // 필터 업데이트 할 때
        case let .updateFilter(kind, option):
            let nextFilterState = currentState.filterState.applyOption(option, for: kind)
            let currentQuery = currentState.query
            
            // 검색어 없으면 그냥 필터 바꿈
            guard !currentQuery.isEmpty else {
                return .just(.setFilter(kind, option))
            }
            
            // 필터 적용해서 다시 검색
            return .concat([
                .just(.setFilter(kind, option)),
                .just(.setLoading(true)),
                search(
                    query: currentQuery,
                    searchType: currentState.searchType,
                    filterState: nextFilterState
                ),
                .just(.setLoading(false))
            ])
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
        }

        return newState
    }
    
    // 서버에서 필터 목록을 가져와서 Mutation으로 바꿔주는 역할
    private func loadFilterOptions() -> Observable<Mutation> {
        Observable.create { [networkManager] observer in
            let task = Task {
                do {
                    let options = try await networkManager.fetchAllFilterOptions()
                    observer.onNext(.setFilterOptions(options))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setResultText("필터 옵션 로드 실패: \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    
    private func search(
        query: String,
        searchType: PlantSearchType,
        filterState: PlantFilterState
    ) -> Observable<Mutation> {
        Observable.create { [networkManager] observer in
            let task = Task {
                do {
                    let plants = try await networkManager.fetchPlantList(
                        keyword: query,
                        searchType: searchType,
                        filterState: filterState,
                        pageNo: 1,
                        numOfRows: 10
                    )
                    
                    // 결과 처리
                    let message: String
                    if plants.isEmpty {
                        message = "'\(query)' 검색 결과가 없습니다."
                    } else {
                        message = ""
                    }
                    
                    observer.onNext(.setPlants(plants))
                    // 검색이 끝나면 결과 텍스트를 바꾸는 Mutation을 보냄
                    observer.onNext(.setResultText(message))
                    observer.onCompleted()
                    // 에러 처리
                } catch {
                    observer.onNext(.setPlants([]))
                    observer.onNext(.setResultText("검색 실패: \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }
            
            // 구독이 해제되면 실행중인 Task 취소
            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func cleanQuery(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
