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
    let collectionView = PlantCollectionView()
    private lazy var dataSource = makeCollectionViewDiffableDataSource(collectionView)
    
    let titleView = TitleHeaderView(text: "", hasBackButton: false, rightButtonImage: "bell")
    let totalPlant = TotalCardView(image: Badge.sprout.bigImage, text: "내 식물 N개")
    let totalWater = TotalCardView(image: Badge.water.bigImage, text: "물 준 식물 N개")
    
    let emptyView = EmptyPlantView().then {
        $0.isHidden = true
    }
    
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
            $0.top.equalTo(totalPlant.snp.bottom).offset(32)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
}

//MARK: CollectionView
extension HomeView {
    private func makeCollectionViewDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Section, Item> {
        let shelfCellRegistration = UICollectionView.CellRegistration<PlantShelfCell, Item> { cell, indexPath, item in
            switch item {
            case .plant(let plant):
                cell.configure(plant)
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
    
    enum EmptyShelf {
        case none
        case first, second, third
    }
    
    enum ShelfOrder {
        case first
        case second
        case third
    }
}

//TODO: 추후 삭제 필요 - 전역 모델 사용
extension HomeView {
    enum PlantCategory: String, Codable, CaseIterable {
        case upright = "직립형"
        case shrub = "관목형"
        case vine = "덩굴성"
        case grass = "풀모양"
        case rosette = "로제트형"
        case succulent = "다육형"
        case other = "기타"

        // 카테고리 별 식물 기본 이미지 (사용자 등록 이미지가 없을 때 대체 이미지)
        var defaultImageAssetName: String {
            switch self {
            case .upright:
                return "plantCategoryUpright"
            case .shrub:
                return "plantCategoryShrub"
            case .vine:
                return "plantCategoryVine"
            case .grass:
                return "plantCategoryGrass"
            case .rosette:
                return "plantCategoryRosette"
            case .succulent:
                return "plantCategorySucculent"
            case .other:
                return "plantCategoryOther"
            }
        }
    }
}
