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
    private func plantConverToItem(plants: [MyPlant]) throws -> [HomeView.Item] {
        guard !plants.isEmpty else { return [] }
        
        // 다음 급수일까지 남은 일수가 적은 순으로 정렬
        let sortedPlants = try plants.sorted(by: {
            let lhsElapsedDays = try daysFromLastWatering(from: $0.lastWateredAt)
            
            let rhsElapsedDays = try daysFromLastWatering(from: $1.lastWateredAt)
            
            return ($0.wateringIntervalDays - lhsElapsedDays) < ($1.wateringIntervalDays - rhsElapsedDays)
        })
        
        // 아이템 변환
        var items: [HomeView.Item] = try sortedPlants.enumerated().map { index, element in
            guard let shelfOrder = ShelfOrder(rawValue: index % 3)
            else {
                throw HomeError.invalidShelfOrder
            }
            
            let elapsedDays = try daysFromLastWatering(from: element.lastWateredAt)
            
            let didWater = calendar.isDateInToday(element.lastWateredAt)
            
            let shelfPlant = HomeView.ShelfPlant(
                id: element.id,
                category: element.category,
                name: element.nickname ?? element.speciesName,
                daysFromLastWatering: elapsedDays,
                daysToNextWatering: element.wateringIntervalDays - elapsedDays,
                didWater: didWater,
                emptyShelf: .none,
                shelfOrder: shelfOrder)
            
            return HomeView.Item.plant(shelfPlant)
        }
        
        // 3의 배수로 배열 생성
        let emptyPlants = generateEmptyPlants(count: items.count)
        
        return items + emptyPlants
    }
    
    private func generateEmptyPlants(count: Int) -> [HomeView.Item] {
        let emptyIndex = count % 3 // 마지막 빈 식물의 위치
        
        return (0...emptyIndex).reduce([HomeView.Item]()) {
            guard let emptyShelf = EmptyShelf(rawValue: $1),
                  let shelfOrder = ShelfOrder(rawValue: (count + $1) % 3) else { return $0 }
            
            let emptyPlant = HomeView.ShelfPlant(emptyShelf: emptyShelf, shelfOrder: shelfOrder)
            
            let item = HomeView.Item.plant(emptyPlant)
            
            return $0 + [item]
        }
    }
}

//MARK: Calculation
extension HomeReactor {
    // 최근 급수일부터 경과 일수 계산
    private func daysFromLastWatering(from date: Date) throws -> Int {
        let today = calendar.startOfDay(for: Date()) // 오늘
        let lastWateredAt = calendar.startOfDay(for: date) // 마지막 급수일
        
        guard let days = calendar.dateComponents([.day], from: lastWateredAt, to: today)
            .day else {
            throw HomeError.calculationError
        }
        return days
    }
}

extension HomeReactor {
    enum HomeError: Error {
        case calculationError
        case invalidShelfOrder
    }
}
