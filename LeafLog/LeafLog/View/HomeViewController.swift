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
        
        let single = singleSample()
        homeView.setSnapshot([.plant: single])
    }
}

extension HomeViewController {
    
    func singleSample() -> [HomeView.Item] {
        // 1. 실제 식물 정보가 들어있는 single 아이템
        let singlePlant: HomeView.Item = .plant(HomeView.ShelfPlant(
            id: UUID(),
            category: .shrub,
            name: "로즈마리",
            daysFromLastWatering: 2,
            daysToNextWatering: 3,
            didWater: false,
            emptyShelf: .none
        ))

        // 2. 식물 추가 버튼 역할을 하는 아이템 (isAddButton 사용)
        let addBottonItem: HomeView.Item = .plant(HomeView.ShelfPlant(
            id: nil,
            category: nil,
            name: nil,
            daysFromLastWatering: nil,
            daysToNextWatering: nil,
            didWater: nil,
            emptyShelf: .first
        ))

        // 3. 아무것도 정보가 없는 완전 빈 아이템 (PlaceHolder용)
        let emptyItem: HomeView.Item = .plant(HomeView.ShelfPlant(
            id: UUID(),
            category: nil,
            name: nil,
            daysFromLastWatering: nil,
            daysToNextWatering: nil,
            didWater: nil,
            emptyShelf: .second
        ))
        
        let emptyItem2: HomeView.Item = .plant(HomeView.ShelfPlant(
            id: UUID(),
            category: nil,
            name: nil,
            daysFromLastWatering: nil,
            daysToNextWatering: nil,
            didWater: nil,
            emptyShelf: .third
        ))

        // 1. 덩굴성 식물 (아이비) - 오늘 물주기 완료함
        let ivyPlant: HomeView.Item = .plant(HomeView.ShelfPlant(
            id: UUID(),
            category: .vine,
            name: "잉글리쉬 아이비",
            daysFromLastWatering: 0, // 오늘 물줌
            daysToNextWatering: 7,
            didWater: true,
            emptyShelf: .none
        ))

        // 2. 다육형 식물 (선인장) - 물 줄 때가 다 되어감
        let cactusPlant: HomeView.Item = .plant(HomeView.ShelfPlant(
            id: UUID(),
            category: .succulent,
            name: "황금사",
            daysFromLastWatering: 20,
            daysToNextWatering: 1, // 내일 물주기
            didWater: false,
            emptyShelf: .none
        ))

        
        // 활용 예시 (스냅샷 전송 시)
        let items: [HomeView.Item] = [singlePlant, ivyPlant, cactusPlant, addBottonItem, emptyItem, emptyItem2]
        return items
    }
}
