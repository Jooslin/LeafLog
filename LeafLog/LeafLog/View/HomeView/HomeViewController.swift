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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func bind(reactor: HomeReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
}

extension HomeViewController {
    private func bindAction(reactor: HomeReactor) {
        // 화면 진입시
        self.rx.viewWillAppear
            .map { HomeReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // 컬렉션뷰 아이템 선택시
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
        
        // 알림 버튼 탭시
        homeView.rx.alarmButtonTap
            .map { AppStep.alarmCenter }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        // 물주기 버튼 탭시
        homeView.rx.waterButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .compactMap { id in
                guard let id else { return nil }
                return HomeReactor.Action.waterButtonTap(id)
            }
            .bind(to: reactor.action)
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
