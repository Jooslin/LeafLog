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
        case grow = "badgeGrow"
        case sprout = "badgeSprout"
        case water = "badgeWater"
        case treat = "badgeTreat"
    }
    
    enum Section: Int {
        case calendar = 0
    }
    
    nonisolated
    struct ManageInfoByDate: Hashable {
        let currentMonth: Bool // 표시되는 달 여부
        let day: Int
        let badge: [Badge]
    }
    
    //MARK: properties
    private let collectionView = CalendarCollectionView()
    private lazy var dataSource = makeCollectionViewDiffableDataSource()
    
    init() {
        super.init(frame: .zero)
        self.setLayout()
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
    private func makeCollectionViewDiffableDataSource() -> UICollectionViewDiffableDataSource<Section, ManageInfoByDate> {
        let dateCellRegistration = UICollectionView.CellRegistration<CalendarDateCell, ManageInfoByDate> { cell,indexPath,item in
            cell.configure(item)
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Section, ManageInfoByDate>(collectionView: collectionView) { collectionView, indexPath, item in
            switch Section(rawValue: indexPath.section) {
            case .calendar:
                collectionView.dequeueConfiguredReusableCell(using: dateCellRegistration, for: indexPath, item: item)
            default:
                fatalError("CalendarCollectionView: 유효하지 않은 섹션입니다.")
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
