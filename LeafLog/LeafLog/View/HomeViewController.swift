//
//  HomeViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import ReactorKit

final class HomeViewController: BaseViewController {
    private let homeView = HomeView()
    
    override func loadView() {
        view = homeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true //TODO: 추후 삭제
        
        let sample = sampled()
        homeView.setSnapshot([.plant: sample])
    }
}

extension HomeViewController {
    func sampled() -> [HomeView.Item] {
        // 1. 식물이 3개 꽉 찬 경우
        let fullShelf: HomeView.Item = .plant([
            HomeView.ShelfPlant(
                id: UUID(),
                category: .upright,
                name: "몬스테라",
                daysFromLastWatering: 3,
                daysToNextWatering: 4,
                didWater: false
            ),
            HomeView.ShelfPlant(
                id: UUID(),
                category: .shrub,
                name: "장미",
                daysFromLastWatering: 1,
                daysToNextWatering: 2,
                didWater: true
            ),
            HomeView.ShelfPlant(
                id: UUID(),
                category: .succulent,
                name: "다육이",
                daysFromLastWatering: 10,
                daysToNextWatering: 20,
                didWater: false
            )
        ])
        // 2. 식물이 2개 있고 마지막이 nil인 경우
        let partialShelf2: HomeView.Item = .plant([
            HomeView.ShelfPlant(
                id: UUID(),
                category: .vine,
                name: "아이비",
                daysFromLastWatering: 2,
                daysToNextWatering: 5,
                didWater: true
            ),
            HomeView.ShelfPlant(
                id: UUID(),
                category: .grass,
                name: "행운목",
                daysFromLastWatering: 5,
                daysToNextWatering: 5,
                didWater: false
            ),
            nil // 세 번째 공간은 비어있음
        ])
        // 3. 식물이 1개 있고 나머지가 nil인 경우
        let partialShelf1: HomeView.Item = .plant([
            HomeView.ShelfPlant(
                id: UUID(),
                category: .rosette,
                name: "에케베리아",
                daysFromLastWatering: 15,
                daysToNextWatering: 5,
                didWater: false
            ),
            nil,
            nil
        ])
        // 4. 스냅샷 등에 사용하기 위한 배열 예시
        let shelfItems: [HomeView.Item] = [fullShelf, partialShelf2, partialShelf1]
        return shelfItems
    }
}
