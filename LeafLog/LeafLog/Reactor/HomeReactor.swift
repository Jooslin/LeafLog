//
//  HomeReactor.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/27/26.
//

import Foundation
import ReactorKit
import Supabase
import Dependencies

final class HomeReactor: Reactor {
    enum Action {
        case viewWillAppear
    }
    
    enum Mutation {
        case setEmpty(Bool)
        case setTotalCard(Int, Int)
        case error(String)
    }
    
    struct State {
        var isEmpty: Bool = true
        var totalPlants: Int = 0
        var totalWater: Int = 0
        @Pulse var errorMessage: String? = nil
    }
    
    let initialState = State()
    
    //MARK: Properties
    @Dependency(\.plantDBManager) private var plantDBManger
    @Dependency(\.careRecordDBManager) private var careRecordDBManager
    private let calendar = Calendar.current
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return loadPlants()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setTotalCard(let total, let totalWater):
            newState.totalPlants = total
            newState.totalWater = totalWater
            
        case .setEmpty(let isEmpty):
            newState.isEmpty = isEmpty
            
        case .error(let message):
            newState.errorMessage = message
        }
        return newState
    }
}

extension HomeReactor {
    private func loadPlants() -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            
            let task = Task {
                do {
                    let plants = try await self.plantDBManger.fetchMyPlants()
                    
                    let total = plants.count // 총 식물 개수
                    let totalWater = plants.count {
                        self.calendar.isDateInToday($0.lastWateredAt)
                    } // 오늘 물 준 총 식물 개수
                    
                    observer.onNext(.setTotalCard(total, totalWater))
                    
                    if plants.count <= 0 {
                        observer.onNext(.setEmpty(true))
                    } else {
                        observer.onNext( .setEmpty(false))
                    }
                    
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.error(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.error("식물 목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요."))
                    observer.onCompleted()
                }
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}

//MARK: Convert to Items
extension HomeReactor {
    private func plantConverToItem(plants: [MyPlant]) -> [HomeView.Item] {
        guard !plants.isEmpty else { return [] }
        
        plants.sorted(by: {
            
        })
    }
}

//MARK: Calculation
extension HomeReactor {
    // 최근 급수일부터 경과 일수 계산
    private func daysFromLastWatering(from date: Date) -> Int {
        let today = calendar.startOfDay(for: Date()) // 오늘
        let lastWateredAt = calendar.startOfDay(for: date) // 마지막 급수일
        
        let distance = lastWateredAt.distance(to: today)
        let days = Int(distance / 3600 / 24)
        
        return days
    }
    
    // 다음 급수일까지 남은 일수 계산
    private func daysToNextWatering(from date: Date, interval: Int) -> Int {
        let today = calendar.startOfDay(for: Date()) // 오늘
        guard let nextWatering = calendar.date(byAdding: .day, value: interval, to: date) else { return -1 } // 다음 급수일
        
        let distance = today.distance(to: nextWatering)
        let days = Int(distance / 3600 / 24)
        
        return days
    }
}
