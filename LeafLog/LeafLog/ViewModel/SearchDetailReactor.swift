//
//  SearchDetailReactor.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/16/26.
//
import Foundation
import ReactorKit
import RxSwift
import Dependencies

final class SearchDetailReactor: Reactor {

    enum Action {
        case viewDidLoad
    }

    enum Mutation {
        case setDetail(PlantDetail)
    }

    struct State {
        var contentNumber: String
        var detail: PlantDetail?
    }

    let initialState: State

    @Dependency(\.networkManager) private var networkManager

    init(contentNumber: String) {
        self.initialState = State(contentNumber: contentNumber)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return fetchDetail(contentNumber: currentState.contentNumber)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setDetail(let detail):
            newState.detail = detail
        }

        return newState
    }

    private func fetchDetail(contentNumber: String) -> Observable<Mutation> {
        Observable.create { [networkManager] observer in
            let task = Task {
                do {
                    let detail = try await networkManager.fetchPlantDetail(contentNumber: contentNumber)
                    
                    observer.onNext(.setDetail(detail))
                    observer.onCompleted()
                } catch {
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
}
