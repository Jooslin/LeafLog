//
//  HomeViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import Dependencies
import ReactorKit
import RxCocoa
import RxSwift

final class HomeViewController: BaseViewController, View {
    private let homeView = HomeView()
    private var loadPlantsTask: Task<Void, Never>?
    private var waterTask: Task<Void, Never>?
    
    override func loadView() {
        view = homeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        bindPlantSelection()
//        bindPlantRegistration()
//        bindWaterButtonTap()
//        bindAlarmButton()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent || isBeingDismissed { // 완전히 뒤로가기/닫기
            loadPlantsTask?.cancel()
            waterTask?.cancel()
        }
    }
    
    func bind(reactor: HomeReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
}

extension HomeViewController {
    private func bindAction(reactor: HomeReactor) {
        self.rx.viewWillAppear
            .map { HomeReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        homeView.rx.itemSelected
            .compactMap { item -> AppStep? in
                switch item {
                case .plant(let plant):
                    if plant.emptyShelf == .none {
                        guard let id = plant.id else { return nil }
                        return AppStep.record(plantID: id)
                    } else if plant.emptyShelf == .first {
                        return AppStep.plantRegister()
                    } else {
                        return nil
                    }
                }
            }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: HomeReactor) {
        let state = reactor.state
            .asDriver(onErrorJustReturn: .init())
        
        // 등록 식물이 없을 경우
        state.map(\.isEmpty)
            .drive { [weak self] isEmpty in
                self?.homeView.showEmpty(isEmpty)
            }
            .disposed(by: disposeBag)
        
        // 상단 카드뷰 UI 업데이트
        let total = state.map(\.totalPlants) // 총 식물 수
        let watered = state.map(\.totalWater)
        
        Driver.combineLatest(total, watered)
            .drive { [weak self] total, watered in
                self?.homeView.configureCards(total: total, watered: watered)
            }
            .disposed(by: disposeBag)
        
        // 컬렉션뷰 업데이트
        state.map(\.data)
            .drive { [weak self] data in
                self?.homeView.setSnapshot(data)
            }
            .disposed(by: disposeBag)
    }
}

extension HomeViewController    
//    private func bindWaterButtonTap() {
//        homeView.rx.waterButtonTap
//            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
//            .subscribe(onNext: { [weak self] id in
//                guard let self, let id else { return }
//                
//                self.waterTask?.cancel()
//                self.waterTask = Task { [weak self] in
//                    guard let self else { return }
//                    do {
//                        let date = Date()
//                        
//                        try Task.checkCancellation()
//                        try await self.careRecordDBManager.upsertCareRecord(
//                            input: CareRecordUpsertInput(
//                                plantID: id,
//                                recordDate: localDate(from: date),
//                                recordedAt: date,
//                                watered: true
//                            ))
//                        
//                        try Task.checkCancellation()
//                        try await self.plantDBManager.updateLastWateredAt(plantID: id, date: date)
//                        
//                        try Task.checkCancellation()
//                        self.loadPlants()
//                    } catch is CancellationError {
//                        return
//                    } catch let error as AuthError {
//                        self.steps.accept(AppStep.alert("오류", error.userMessage))
//                    } catch {
//                        self.steps.accept(AppStep.alert("오류", "데이터를 저장할 수 없습니다. 잠시 후 다시 시도해주세요."))
//                    }
//                }
//            })
//            .disposed(by: disposeBag)
//    }
      
    private func bindAlarmButton() {
        homeView.rx.alarmButtonTap
            .map { AppStep.alarmCenter }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
}

// MARK: - DB
private extension HomeViewController {
    // 화면애 배치
    func applyPlants(_ plants: [MyPlant]) {
        
        // 식물 있으면 리스트 보여주기
        homeView.emptyView.isHidden = true
        homeView.collectionView.isHidden = false
        homeView.setSnapshot([.plant: makeShelfItems(from: plants)])
    }
}

// MARK: - Home Data
private extension HomeViewController {
    func makeShelfItems(from plants: [MyPlant]) -> [HomeView.Item] {
        var items: [HomeView.Item] = plants.enumerated().map { index, plant in
            let daysFromLastWatering = daysFromLastWatering(from: plant.lastWateredAt)
            
            return .plant(HomeView.ShelfPlant(
                // 식물 정보 넣기
                id: plant.id,
                category: plant.category,
                name: plant.nickname?.isEmpty == false ? plant.nickname : plant.speciesName,
                daysFromLastWatering: daysFromLastWatering,
                daysToNextWatering: max(0, plant.wateringIntervalDays - daysFromLastWatering),
                didWater: didWaterToday(plant), // 오늘 급수 여부
                emptyShelf: .none,
                shelfOrder: shelfOrder(for: index)
            ))
        }
        
        let addButtonIndex = items.count
        items.append(makeEmptyShelfItem(emptyShelf: .first, index: addButtonIndex))
        
        while items.count % 3 != 0 {
            let placeholderIndex = items.count
            let emptyShelf: EmptyShelf = items.count % 3 == 1 ? .second : .third
            items.append(makeEmptyShelfItem(emptyShelf: emptyShelf, index: placeholderIndex))
        }
        
        return items
    }
    
    func makeEmptyShelfItem(emptyShelf: EmptyShelf, index: Int) -> HomeView.Item {
        .plant(HomeView.ShelfPlant(
            id: nil,
            category: nil,
            name: nil,
            daysFromLastWatering: nil,
            daysToNextWatering: nil,
            didWater: nil,
            emptyShelf: emptyShelf,
            shelfOrder: shelfOrder(for: index)
        ))
    }
    
    // 선반 위치 지정
    func shelfOrder(for index: Int) -> ShelfOrder {
        switch index % 3 {
        case 0:
            return .first
        case 1:
            return .second
        default:
            return .third
        }
    }
    
    // 최근 급수일 계산
    func daysFromLastWatering(from date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastWateredDate = calendar.startOfDay(for: date)
        let day = calendar.dateComponents([.day], from: lastWateredDate, to: today).day ?? 0
        return max(0, day)
    }
    
    // 오늘 물 줬는지
    func didWaterToday(_ plant: MyPlant) -> Bool {
        Calendar.current.isDateInToday(plant.lastWateredAt)
    }
}
