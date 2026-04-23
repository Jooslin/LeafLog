//
//  NotificationCenterView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/23/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class NotificationCenterView: UIView {
    fileprivate let titleView = TitleHeaderView(text: "알림 센터", hasBackButton: true)
    private lazy var listView = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout()).then {
        $0.showsVerticalScrollIndicator = false
        $0.contentInset = .init(top: 0, left: 0, bottom: 50, right: 0)
    }
    private lazy var dataSource = makeCollectionViewDiffableDataSource(listView)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayout() {
        addSubview(titleView)
        addSubview(listView)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(48)
        }
        
        listView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(24)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
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
        let alarmCellRegistration = UICollectionView.CellRegistration<NotificationAlarmCell, Item> { cell, indexPath, item in
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
        case alarm(Alarm)
    }
    
    struct Alarm: Hashable {
        let id: UUID
        let title: String
        let body: String
        let category: AppNotificationCategory
        let sentTimeLabel: String
    }
}

extension Reactive where Base: NotificationCenterView {
    var backButtonTap: ControlEvent<Void> {
        base.titleView.rx.backButtonTap
    }
}
