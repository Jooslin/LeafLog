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
    enum Badge: String {
        case grow = "분갈이"
        case sprout = "비료"
        case water = "물주기"
        case treat = "치료"
        
        var smallImage: String {
            switch self {
            case .grow: "badgeGrowSmall"
            case .sprout: "badgeSproutSmall"
            case .water: "badgeWaterSmall"
            case .treat: "badgeTreatSmall"
            }
        }
        
        var bigImage: String {
            switch self {
            case .grow: "badgeGrowBig"
            case .sprout: "badgeSproutBig"
            case .water: "badgeWaterBig"
            case .treat: "badgeTreatBig"
            }
        }
    }
    
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
    }
    
    enum Section: Int {
        case calendar = 0
        case water
        case grow
        case sprout
        case treat
    }
    
    nonisolated
    enum Item: Hashable {
        case calendar(ManageInfoByDate)
        case water(DetailManageInfo)
        case grow(DetailManageInfo)
        case sprout(DetailManageInfo)
        case treat(DetailManageInfo)
    }
    
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
        
        let calendarFooterViewRegistration = UICollectionView.SupplementaryRegistration<CalendarDateFooterView>(elementKind: "footerKind") { supplementaryView, elementKind, indexPath in
            //TODO: 수정 필요
            supplementaryView.configure("4월 13일 월요일")
        }
        
        let dateCellRegistration = UICollectionView.CellRegistration<CalendarDateCell, Item> { cell,indexPath,item in
            switch item {
            case .calendar(let info):
                cell.configure(info)
            default:
                break
            }
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch Section(rawValue: indexPath.section) {
            case .calendar:
                collectionView.dequeueConfiguredReusableCell(using: dateCellRegistration, for: indexPath, item: item)
            default:
                fatalError("CalendarCollectionView: 유효하지 않은 섹션입니다.")
            }
        }
        
        dataSource.supplementaryViewProvider = { _, kind, indexPath in
            switch kind {
            case "headerKind":
                return collectionView.dequeueConfiguredReusableSupplementary(using: calendarHeaderViewRegistration, for: indexPath)
            case "footerKind":
                return collectionView.dequeueConfiguredReusableSupplementary(using: calendarFooterViewRegistration, for: indexPath)
            default:
                return UICollectionReusableView()
            }
            
            
        }

        return dataSource
    }
    
    func setSnapshot(_ data: [ManageInfoByDate]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ManageInfoByDate>()
        snapshot.appendSections([.calendar])
        
        snapshot.appendItems(data, toSection: .calendar)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
