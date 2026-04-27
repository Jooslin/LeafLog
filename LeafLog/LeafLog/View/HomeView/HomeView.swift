//
//  HomeView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class HomeView: UIView {
    //MARK: properties
    let collectionView = PlantCollectionView()
    fileprivate lazy var dataSource = makeCollectionViewDiffableDataSource(collectionView)
    
    let titleView = TitleHeaderView(text: "", hasBackButton: false, rightButtonImage: "bell")
    let totalPlant = TotalCardView(image: Badge.sprout.bigImage, text: "내 식물 N개")
    let totalWater = TotalCardView(image: Badge.water.bigImage, text: "물 준 식물 N개")
    
    let emptyView = EmptyPlantView().then {
        $0.isHidden = true
    }
    
    fileprivate let waterButtonTap = PublishRelay<UUID?>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .grayScale50
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HomeView {
    private func setLayout() {
        let cardStack = UIStackView(arrangedSubviews: [totalPlant, totalWater]).then {
            $0.axis = .horizontal
            $0.spacing = 16
            $0.distribution = .fillEqually
        }
        
        addSubview(titleView)
        addSubview(cardStack)
        addSubview(emptyView)
        addSubview(collectionView)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(48)
        }
        
        cardStack.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        
        emptyView.snp.makeConstraints {
            $0.top.equalTo(totalPlant.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(totalPlant.snp.bottom)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
}

//MARK: CollectionView
extension HomeView {
    private func makeCollectionViewDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Section, Item> {
        let shelfCellRegistration = UICollectionView.CellRegistration<PlantShelfCell, Item> { [weak self] cell, indexPath, item in
            guard let self else { return }
            
            switch item {
            case .plant(let plant):
                cell.configure(plant)
                
                cell.rx.waterButtonTap
                    .map { plant.id }
                    .bind(to: self.waterButtonTap)
                    .disposed(by: cell.disposeBag)
            }
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch Section(rawValue: indexPath.section) {
            case .plant:
                collectionView.dequeueConfiguredReusableCell(using: shelfCellRegistration, for: indexPath, item: item)
            default:
                fatalError("PlantCollectionView: 유효하지 않은 섹션입니다.")
            }
        }
        
        return dataSource
    }
    
    func setSnapshot(_ data: [Section: [Item]]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        snapshot.appendSections([.plant])
        snapshot.appendItems(data[.plant] ?? [], toSection: .plant)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func item(at indexPath: IndexPath) -> Item? {
        dataSource.itemIdentifier(for: indexPath)
    }
}

//MARK: Configure
extension HomeView {
    func showEmpty(_ isEmpty: Bool) {
        if isEmpty {
            emptyView.isHidden = false
            collectionView.isHidden = true
        } else {
            emptyView.isHidden = true
            collectionView.isHidden = false
        }
    }
    
    func configureCards(total: Int, watered: Int) {
        totalPlant.label.text = "내 식물 \(total)개"
        totalWater.label.text = "물 준 식물 \(watered)개"
    }
}

//MARK: CollectionView - Section, Item
extension HomeView {
    enum Section: Int {
        case plant
    }
    
    nonisolated
    enum Item: Hashable {
        case plant(ShelfPlant)
    }
    
    nonisolated
    struct ShelfPlant: Hashable {
        let id: UUID? // 식물의 uuid
        let category: PlantCategory?
        let name: String? // 식물의 이름(별명)
        let daysFromLastWatering: Int? // 최근 급수일 - N일 전
        let daysToNextWatering: Int? // 다음 급수일 - N일 후
        let didWater: Bool? // 금일 급수 여부
        let emptyShelf: EmptyShelf
        let shelfOrder: ShelfOrder
    }
}

nonisolated
enum EmptyShelf {
    case none
    case first, second, third
}

nonisolated
enum ShelfOrder: Int {
    case first = 0
    case second
    case third
}

extension Reactive where Base: HomeView {
    var waterButtonTap: PublishRelay<UUID?> {
        base.waterButtonTap
    }
  
    var alarmButtonTap: ControlEvent<Void> {
        base.titleView.rightButton.rx.tap
    }
    
    var itemSelected: Observable<HomeView.Item> {
        base.collectionView.rx.itemSelected
            .compactMap {
                base.dataSource.itemIdentifier(for: $0)
            }
    }
}
