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
        case updateQuery(String) // 검색어 생김
    }
    
    // 상태를 어떻게 바꿀지에 대한 변화
    enum Mutation {
        case setLoading(Bool) // 검색 전후
        case setResultText(String) // 결과가 나올때
    }
    
    // 화면이 어떤 상태인지 표현(처음 상태)
    struct State {
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
            // 사용자가 텍스트 입력시 실행
        case .updateQuery(let rawQuery):
            let query = cleanQuery(rawQuery)
            
            // 비었을 때
            guard !query.isEmpty else {
                return .concat([
                    .just(.setLoading(false)),
                    .just(.setResultText("검색어를 입력해 주세요."))
                ])
            }
            
            // 로딩 시작 - 네트워크 검색 - 로딩 종료
            return .concat([
                .just(.setLoading(true)),
                search(query: query),
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
        case .setResultText(let resultText):
            newState.resultText = resultText
        }

        return newState
    }
    
    
    private func search(query: String) -> Observable<Mutation> {
        Observable.create { [networkManager] observer in
            let task = Task {
                do {
                    let plants = try await networkManager.fetchPlantList(
                        keyword: query,
                        pageNo: 1,
                        numOfRows: 10
                    )
                    
                    // 결과 처리
                    let message: String
                    if plants.isEmpty {
                        message = "'\(query)' 검색 결과가 없습니다."
                    } else {
                        // 검색 결과가 있으면 앞의 세개만 보여줌
                        let names = plants.prefix(10).map { $0.name }.joined(separator: "\n")
                        message = """
                        검색어: \(query)
                        결과 수: \(plants.count)

                        \(names)
                        """
                    }
                    
                    // 검색이 끝나면 결과 텍스트를 바꾸는 Mutation을 보냄
                    observer.onNext(.setResultText(message))
                    observer.onCompleted()
                    // 에러 처리
                } catch {
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
