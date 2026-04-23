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

final class HomeViewController: BaseViewController {
    @Dependency(\.plantDBManager) private var plantDBManager
    @Dependency(\.careRecordDBManager) private var careRecordDBManager
    
    private let homeView = HomeView()
    private var loadPlantsTask: Task<Void, Never>?
    
    override func loadView() {
        view = homeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true //TODO: 추후 삭제
        
        bindPlantSelection()
        bindPlantRegistration()
        showEmptyState()
        bindWaterButtonTap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadPlants() // 식물 데이터 불러오기
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent || isBeingDismissed { // 완전히 뒤로가기/닫기
            loadPlantsTask?.cancel()
        }
    }
}

extension HomeViewController {
    private func bindPlantSelection() {
        homeView.collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath -> AppStep? in
                // 사용자가 누른 칸의 데이터 가져옴
                guard case .plant(let shelfPlant) = self?.homeView.item(at: indexPath) else {
                    return nil
                }
                
                switch shelfPlant.emptyShelf {
                case .none:
                    guard let plantID = shelfPlant.id else {
                        return nil
                    }
                    
                    return AppStep.record(plantID: plantID)
                    
                case .first:
                    return AppStep.plantRegister()
                    
                case .second, .third:
                    return nil
                }
            }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
    
    private func bindPlantRegistration() {
        homeView.emptyView.registerButton.rx.tap
            .map { AppStep.plantRegister() }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
    
    private func bindWaterButtonTap() {
        homeView.rx.waterButtonTap
            .subscribe(onNext: { [weak self] id in
                guard let self, let id else { return }
                
                Task {
                    do {
                        try await self.careRecordDBManager.upsertCareRecord(
                            input: CareRecordUpsertInput(
                                plantID: id,
                                recordDate: LocalDate(date: Date()),
                                watered: true
                            ))
                        self.loadPlants()
                    } catch let error as AuthError {
                        self.steps.accept(AppStep.alert("오류", error.userMessage))
                    } catch {
                        self.steps.accept(AppStep.alert("오류", "데이터를 저장할 수 없습니다. 잠시 후 다시 시도해주세요."))
                    }
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - DB
private extension HomeViewController {
    func loadPlants() {
        loadPlantsTask?.cancel() // 기존 작업 취소
        
        loadPlantsTask = Task { [weak self, plantDBManager] in
            do {
                // DB에서 내가 등록한 식물들 가져오기
                let plants = try await plantDBManager.fetchMyPlants()
                
                guard let self else {
                    return
                }
                
                self.applyPlants(plants) // 가져온 식물 데이터 화면에 뿌리기
            } catch let error as AuthError {
                guard let self else {
                    return
                }
                
                self.showEmptyState()
                self.steps.accept(AppStep.alert("오류", error.userMessage))
            } catch is CancellationError {
                return
            } catch {
                guard let self else {
                    return
                }
                
                self.showEmptyState()
                self.steps.accept(AppStep.alert("오류", "식물 목록을 불러오지 못했어요. \(error.localizedDescription)"))
            }
        }
    }
    
    // 화면애 배치
    func applyPlants(_ plants: [MyPlant]) {
        homeView.totalPlant.label.text = "내 식물 \(plants.count)개"
        homeView.totalWater.label.text = "물 준 식물 \(plants.filter(didWaterToday).count)개"
        
        // 식물 데이터 0개일때
        guard !plants.isEmpty else {
            showEmptyState()
            return
        }
        
        // 식물 있으면 리스트 보여주기
        homeView.emptyView.isHidden = true
        homeView.collectionView.isHidden = false
        homeView.setSnapshot([.plant: makeShelfItems(from: plants)])
    }
    
    func showEmptyState() {
        homeView.totalPlant.label.text = "내 식물 0개"
        homeView.totalWater.label.text = "물 준 식물 0개"
        homeView.emptyView.isHidden = false
        homeView.collectionView.isHidden = true
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
