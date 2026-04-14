//
//  CalendarView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/12/26.
//

import UIKit
import SnapKit
import Then

final class CalendarView: UIView {
    //MARK: properties
    private let collectionView = CalendarCollectionView()
    private lazy var dataSource = makeCollectionViewDiffableDataSource(collectionView)
    
    init() {
        super.init(frame: .zero)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarView {
    private func setLayout() {
        self.addSubview(collectionView)
        
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

//MARK: CollectionView
extension CalendarView {
    private func makeCollectionViewDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Section, Item> {
        let calendarHeaderViewRegistration = UICollectionView.SupplementaryRegistration<CalendarWeekdayHeaderView>(elementKind: "headerKind") { supplementaryView, elementKind, indexPath in
            
        }
        
        let detailHeaderViewRegistration = UICollectionView.SupplementaryRegistration<CalendarDetailHeaderView>(elementKind: "headerKind") { [weak self] supplementaryView, elementKind, indexPath in
            guard let section = self?.dataSource.sectionIdentifier(for: indexPath.section) else { return }
            
            switch section {
            case .water:
                supplementaryView.configure(.water)
            case .grow:
                supplementaryView.configure(.grow)
            case .sprout:
                supplementaryView.configure(.sprout)
            case .treat:
                supplementaryView.configure(.treat)
            default:
                break
            }
        }
        
        let calendarFooterViewRegistration = UICollectionView.SupplementaryRegistration<CalendarDateFooterView>(elementKind: "footerKind") { supplementaryView, elementKind, indexPath in
            //TODO: 수정 필요
            supplementaryView.configure("4월 13일 월요일")
        }
        
        let titleCellRegistration = UICollectionView.CellRegistration<CalendarTitleCell, Item> { cell,indexPath,item in
            
        }
        
        let headerCellRegistration = UICollectionView.CellRegistration<CalendarHeaderCell, Item> { cell, indexPath, item in
            switch item {
            case .header(let date):
                cell.configure(date)
            default:
                break
            }
        }
        
        let dateCellRegistration = UICollectionView.CellRegistration<CalendarDateCell, Item> { cell,indexPath,item in
            switch item {
            case .calendar(let info):
                cell.configure(info)
            default:
                break
            }
        }
        
        let filterCellRegistartion = UICollectionView.CellRegistration<CalendarFilterCell, Item> { cell, indexPath, item in
            switch item {
            case .filter(let texts):
                cell.configure(texts)
            default:
                break
            }
        }
        
        let detailCellRegistration = UICollectionView.CellRegistration<CalendarDetailCell, Item> { cell, indexPath, item in
            switch item {
            case .water(let info), .grow(let info), .sprout(let info), .treat(let info):
                cell.configure(info)
            default:
                break
            }
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
        
        dataSource.supplementaryViewProvider = { [weak self] _, kind, indexPath in
            guard let section = self?.dataSource.sectionIdentifier(for: indexPath.section) else {
                return UICollectionReusableView()
            }
            
            switch kind {
            case "headerKind":
                switch section {
                case .calendar:
                    return collectionView.dequeueConfiguredReusableSupplementary(using: calendarHeaderViewRegistration, for: indexPath)
                default:
                    return collectionView.dequeueConfiguredReusableSupplementary(using: detailHeaderViewRegistration, for: indexPath)
                }
               
            case "footerKind":
                return collectionView.dequeueConfiguredReusableSupplementary(using: calendarFooterViewRegistration, for: indexPath)
                
            default:
                return UICollectionReusableView()
            }
        }

        return dataSource
    }
    
    func setSnapshot(_ data: [[Item]]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        let sections: [Section] = [.calendar, .water, .grow, .sprout, .treat]
        
        snapshot.appendSections([.title, .header, .filter])
        
        snapshot.appendItems([Item.title], toSection: .title)
        snapshot.appendItems(data[0], toSection: .header)
        snapshot.appendItems([Item.filter(["전체", "물주기", "분갈이", "비료", "치료"])], toSection: .filter)
        
        for section in sections {
            let index = section.rawValue - 2
            let items = data[index]
            
            // 데이터가 있는 경우에만 섹션과 아이템 추가
            if !items.isEmpty {
                snapshot.appendSections([section])
                snapshot.appendItems(items, toSection: section)
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

//MARK: Badge enum
extension CalendarView {
    enum Badge: String {
        case water = "물주기"
        case grow = "분갈이"
        case sprout = "비료"
        case treat = "치료"
        
        var smallImage: String {
            switch self {
            case .water: "badgeWaterSmall"
            case .grow: "badgeGrowSmall"
            case .sprout: "badgeSproutSmall"
            case .treat: "badgeTreatSmall"
            }
        }
        
        var bigImage: String {
            switch self {
            case .water: "badgeWaterBig"
            case .grow: "badgeGrowBig"
            case .sprout: "badgeSproutBig"
            case .treat: "badgeTreatBig"
            }
        }
        
        var color: UIColor {
            switch self {
            case .water: .subBlue
            case .grow: .subBrown
            case .sprout: .primary600
            case .treat: .subRed
            }
        }
    }
}

//MARK: CollectionView - Section, Item
extension CalendarView {
    enum Section: Int {
        case title = 0
        case header
        case filter
        case calendar
        case water
        case grow
        case sprout
        case treat
    }
    
    nonisolated
    enum Item: Hashable {
        case title
        case header(String)
        case filter([String])
        case calendar(ManageInfoByDate)
        case water(DetailManageInfo)
        case grow(DetailManageInfo)
        case sprout(DetailManageInfo)
        case treat(DetailManageInfo)
    }
}

//MARK: CollectionView - Item Model
extension CalendarView {
    nonisolated
    struct ManageInfoByDate: Hashable {
        let currentMonth: Bool // 표시되는 달 여부
        let day: Int
        let badge: Set<Badge>
    }
    
    nonisolated
    struct DetailManageInfo: Hashable {
        let id: UUID // 식물의 uuid
        let name: String // 식물의 이름(별명)
        let badge: Badge
    }
}
