//
//  HomeView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then

final class HomeView: UIView {
    //MARK: properties
    private let collectionView = PlantCollectionView()
    private lazy var dataSource = makeCollectionViewDiffableDataSource(collectionView)
    
    let titleView = TitleHeaderView(text: "", hasBackButton: false, rightButtonImage: "bell")
    //TODO: image 추후 변경 필요
    let totalPlant = TotalCardView(image: "badgeSproutBig", text: "내 식물 N개")
    let totalWater = TotalCardView(image: "badgeWaterBig", text: "물 준 식물 N개")
    
    let emptyView = EmptyPlantView()
    
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
    func setLayout() {
        addSubview(titleView)
        addSubview(totalPlant)
        addSubview(totalWater)
        addSubview(emptyView)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        totalPlant.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(48)
            $0.width.equalTo(135)
        }
        
        totalWater.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.leading.equalTo(totalPlant.snp.trailing).offset(16)
            $0.height.equalTo(48)
            $0.width.equalTo(150)
        }
        
        emptyView.snp.makeConstraints {
            $0.top.equalTo(totalPlant.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
    }
}

//MARK: CollectionView
extension HomeView {
    private func makeCollectionViewDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Section, Item> {
        let shelfCellRegistration = UICollectionView.CellRegistration<PlantShelfCell, Item> { cell,indexPath,item in
            
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch Section(rawValue: indexPath.section) {
            case .title:
                collectionView.dequeueConfiguredReusableCell(using: titleCellRegistration, for: indexPath, item: item)
            case .header:
                collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration, for: indexPath, item: item)
            case .filter:
                collectionView.dequeueConfiguredReusableCell(using: filterCellRegistartion, for: indexPath, item: item)
            case .calendar:
                collectionView.dequeueConfiguredReusableCell(using: dateCellRegistration, for: indexPath, item: item)
            case .water, .grow, .sprout, .treat:
                collectionView.dequeueConfiguredReusableCell(using: detailCellRegistration, for: indexPath, item: item)
            default:
                fatalError("CalendarCollectionView: 유효하지 않은 섹션입니다.")
            }
        }
        
        return dataSource
    }
    
    func setSnapshot(_ data: [Section: [Item]]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        for target in data.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            if !target.value.isEmpty {
                snapshot.appendSections([target.key])
                snapshot.appendItems(target.value, toSection: target.key)
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

//MARK: CollectionView - Section, Item
extension HomeView {
    enum Section: Int {
        case plant
    }
    
    nonisolated
    enum Item: Hashable {
        case plant([ShelfPlant])
    }
    
    nonisolated
    struct ShelfPlant: Hashable {
        let id: UUID // 식물의 uuid
        let name: String // 식물의 이름(별명)
        let daysFromLastWatering: Int // 최근 급수일 - N일 전
        let daysToNextWatering: Int // 다음 급수일 - N일 후
        let didWater: Bool // 금일 급수 여부
    }
}
