//
//  CalendarView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/12/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class CalendarView: UIView {
    //MARK: properties
    fileprivate let collectionView = CalendarCollectionView()
    fileprivate lazy var dataSource = makeCollectionViewDiffableDataSource(collectionView)
    
    fileprivate let headerPreviousButtonTap = PublishRelay<Void>()
    fileprivate let headerNextButtonTap = PublishRelay<Void>()
    
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
        
        let titleCellRegistration = UICollectionView.CellRegistration<CalendarTitleCell, Item> { cell,indexPath,item in
            
        }
        
        let headerCellRegistration = UICollectionView.CellRegistration<CalendarHeaderCell, Item> { cell, indexPath, item in
            switch item {
            case .header(let year, let month):
                cell.configure(year: year, month: month)
                
                cell.rx.headerPreviousButtonTap
                    .bind(to: self.headerPreviousButtonTap)
                    .disposed(by: cell.disposeBag)
                
                cell.rx.headerNextButtonTap
                    .bind(to: self.headerNextButtonTap)
                    .disposed(by: cell.disposeBag)
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
            case .filter(let filters):
                cell.configure(selectedTags: filters)
            default:
                break
            }
        }
        
        let dateLabelCellRegistration = UICollectionView.CellRegistration<CalendarDateLabelCell, Item> { cell, indexPath, item in
            switch item {
            case .label(let text):
                cell.configure(text)
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
        
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            
            guard let section = self?.dataSource.sectionIdentifier(for: indexPath.section) else {
                fatalError("CalendarCollectionView: 유효하지 않은 섹션입니다.")
            }
            
            return switch section {
            case .title:
                collectionView.dequeueConfiguredReusableCell(using: titleCellRegistration, for: indexPath, item: item)
            case .header:
                collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration, for: indexPath, item: item)
            case .filter:
                collectionView.dequeueConfiguredReusableCell(using: filterCellRegistartion, for: indexPath, item: item)
            case .label:
                collectionView.dequeueConfiguredReusableCell(using: dateLabelCellRegistration, for: indexPath, item: item)
            case .calendar:
                collectionView.dequeueConfiguredReusableCell(using: dateCellRegistration, for: indexPath, item: item)
            case .water, .grow, .sprout, .treat:
                collectionView.dequeueConfiguredReusableCell(using: detailCellRegistration, for: indexPath, item: item)
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
                
            default:
                return UICollectionReusableView()
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
extension CalendarView {
    enum Section: Int {
        case title = 0
        case header
        case filter
        case calendar
        case label
        case water
        case grow
        case sprout
        case treat
    }
    
    nonisolated
    enum Item: Hashable {
        case title
        case header(Int, Int) // 년, 월
        case filter(Set<Int>)
        case calendar(ManageInfoByDate)
        case label(String)
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
        let isCurrentMonth: Bool // 표시되는 달 여부
        let day: Int
        let date: Date
        let badge: Set<Badge>
    }
    
    nonisolated
    struct DetailManageInfo: Hashable {
        let id: UUID // 식물의 uuid
        let name: String // 식물의 이름(별명)
        let badge: Badge
    }
}

extension Reactive where Base: CalendarView {
    var headerPreviousButtonTap: PublishRelay<Void> {
        base.headerPreviousButtonTap
    }
    
    var headerNextButtonTap: PublishRelay<Void> {
        base.headerNextButtonTap
    }
    
    var filterButtonTap: ControlEvent<Int> {
        let filterButtonTap = base.collectionView.rx.willDisplayCell
            .compactMap { cell, _ in cell as? CalendarFilterCell }
            .flatMapLatest { $0.rx.filterButtonTap.asObservable() }
        return ControlEvent(events: filterButtonTap)
    }
    
    var itemSelected: Observable<CalendarView.Item> {
        base.collectionView.rx.itemSelected
            .compactMap {
                base.dataSource.itemIdentifier(for: $0)
            }
    }
}
