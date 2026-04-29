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
    fileprivate lazy var collectionView = CalendarCollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout())
    fileprivate lazy var dataSource = makeCollectionViewDiffableDataSource(collectionView)
    
    fileprivate let headerPreviousButtonTap = PublishRelay<Void>()
    fileprivate let headerNextButtonTap = PublishRelay<Void>()
    fileprivate let alarmButtonTap = PublishRelay<Void>()
    fileprivate let filterButtonTap = PublishRelay<Int>()
    
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
        
        let titleCellRegistration = UICollectionView.CellRegistration<CalendarTitleCell, Item> { [weak self] cell,indexPath,item in
            guard let self else { return }
            cell.rx.alarmButtonTap
                .bind(to: self.alarmButtonTap)
                .disposed(by: cell.disposeBag)
        }
        
        let headerCellRegistration = UICollectionView.CellRegistration<CalendarHeaderCell, Item> { [weak self] cell, indexPath, item in
            guard let self else { return }
            
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
        
        let filterCellRegistartion = UICollectionView.CellRegistration<CalendarFilterCell, Item> { [weak self] cell, indexPath, item in
            guard let self else { return }
            
            switch item {
            case .filter(let filters):
                cell.configure(selectedTags: filters)
                
                cell.rx.filterButtonTap
                    .bind(to: self.filterButtonTap)
                    .disposed(by: cell.disposeBag)
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
        dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            guard let self else { return }
            
            guard let selectedItem = data[.calendar]?.first(where: {
                guard case .calendar(let info) = $0 else { return false }
                return info.isSelected
            }) else { return }
            
            guard let indexPath = self.dataSource.indexPath(for: selectedItem) else { return }
            
            self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
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
        let isSelected: Bool
        let day: Int
        let date: Date
        let badge: Set<Badge>
    }
    
    nonisolated
    struct DetailManageInfo: Hashable {
        let id: UUID // 식물의 uuid
        let date: Date // 기록 날짜
        let name: String // 식물의 이름(별명)
        let badge: Badge
    }
}

//MARK: CollectionView - Layout
extension CalendarView {
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = .layoutMargins
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
            guard let section = self?.dataSource.sectionIdentifier(for: sectionIndex) else { return nil }
            
            let calendarHeaderItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(50)
                ),
                elementKind: "headerKind",
                alignment: .top
            )
            
            let detailHeaderItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(48)
                ),
                elementKind: "headerKind",
                alignment: .top
            )
  
            let calendarBackgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: "calendarBackground")
            
            let detailBackgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: "detailBackground")
            detailBackgroundItem.contentInsets = .init(top: 0, leading: 0, bottom: 24, trailing: 0)
            
            switch section {
            case .title, .header:
                let section = self?.singleItemSectionLayout()
                return section
                
            case .filter:
                let section = self?.singleItemSectionLayout(height: 88)
                return section
                
            case .calendar:
                let section = self?.calendarSectionLayout(environment)
                section?.boundarySupplementaryItems = [calendarHeaderItem]
                section?.decorationItems = [calendarBackgroundItem]
                section?.contentInsets = .init(top: 0, leading: 24, bottom: 24, trailing: 24)
                
                return section
                
            case .label:
                let section = self?.singleItemSectionLayout(height: 64)
                return section
                
            case .water, .grow, .sprout, .treat:
                let section = self?.detailSectionLayout()
                section?.boundarySupplementaryItems = [detailHeaderItem]
                section?.decorationItems = [detailBackgroundItem]
                section?.contentInsets = .init(top: 0, leading: 0, bottom: 24, trailing: 0)
                
                return section
            }
            
        }, configuration: configuration)
        
        layout.register(CalendarBackgroundView.self, forDecorationViewOfKind: "calendarBackground")
        layout.register(CalendarBackgroundView.self, forDecorationViewOfKind: "detailBackground")
        return layout
    }
    
    private func singleItemSectionLayout(height: CGFloat = 48) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(height)
            ))
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(height)),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    private func calendarSectionLayout(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let width = environment.container.effectiveContentSize.width - 48
        let itemWidth = width / 7
        
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .absolute(itemWidth),
                heightDimension: .absolute(itemWidth * 1.7))
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(itemWidth * 1.7)
            ),
            repeatingSubitem: item,
            count: 7
        )
        
        let section = NSCollectionLayoutSection(group: group)
        
        return section
    }
    
    private func detailSectionLayout() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(45))
            )
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(45)),
            subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        return section
    }
}


extension Reactive where Base: CalendarView {
    var headerPreviousButtonTap: PublishRelay<Void> {
        base.headerPreviousButtonTap
    }
    
    var headerNextButtonTap: PublishRelay<Void> {
        base.headerNextButtonTap
    }
    
    var filterButtonTap: PublishRelay<Int> {
        base.filterButtonTap
    }
    
    var itemSelected: Observable<CalendarView.Item> {
        base.collectionView.rx.itemSelected
            .compactMap {
                base.dataSource.itemIdentifier(for: $0)
            }
    }
    
    var alarmButtonTap: PublishRelay<Void> {
        base.alarmButtonTap
    }
}
