//
//  NotificationCenterView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/23/26.
//

import UIKit
import SnapKit
import Then

final class NotificationCenterView: UIView {
    let title = TitleHeaderView(text: "알림 센터", hasBackButton: true)
    private lazy var listView = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout()).then {
        $0.showsVerticalScrollIndicator = false
    }
    private lazy var dataSource = makeCollectionViewDiffableDataSource(listView)
}

//MARK: CollectionView
extension NotificationCenterView {
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(74)
                ))
            
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(74)),
                subitems: [item]
            )
            
            let section = NSCollectionLayoutSection(group: group)
            return section
        }, configuration: configuration)
    }
    
    private func makeCollectionViewDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Section, Item> {
        let alarmCellRegistration = UICollectionView.CellRegistration<CalendarDetailCell, Item> { cell, indexPath, item in
            switch item {
            case .alarm(let alarm):
                cell.configure(alarm)
            }
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch Section(rawValue: indexPath.section) {
            case .list:
                collectionView.dequeueConfiguredReusableCell(using: alarmCellRegistration, for: indexPath, item: item)
            default:
                fatalError("CalendarCollectionView: 유효하지 않은 섹션입니다.")
            }
        }
        
        return dataSource
    }
    
    func setSnapshot(_ data: [Item]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.list])
        snapshot.appendItems(data, toSection: .list)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension NotificationCenterView {
    nonisolated
    enum Section: Int {
        case list = 0
    }
    
    nonisolated
    enum Item: Hashable {
        case alarm(AppNotification)
    }
}
