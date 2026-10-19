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
    fileprivate lazy var listView = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout()).then {
        $0.showsVerticalScrollIndicator = false
        $0.contentInset = .init(top: 0, left: 0, bottom: 50, right: 0)
    }
    
    let categorySegment = UISegmentedControl(categories: ["관리", "활동"])
    
    let managementEmptyView = EmptyView(image: OthersImageAsset.bellColored.rawValue, title: "아직 관리 알림이 없어요", subTitle: "물주기나 관리 일정이 생기면\n알림으로 알려드릴게요.", needButton: false).then {
        $0.isHidden = true
    }
    
    let communityEmptyView = EmptyView(image: OthersImageAsset.bellColored.rawValue, title: "아직 활동 알림이 없어요", subTitle: "좋아요나 댓글이 달리면\n알림으로 알려드릴게요.", needButton: false).then {
        $0.isHidden = true
    }
    
    fileprivate lazy var dataSource = makeCollectionViewDiffableDataSource(listView)
    private var showsEndFooter = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayout() {
        addSubview(listView)
        addSubview(managementEmptyView)
        addSubview(communityEmptyView)
        addSubview(titleView)
        addSubview(categorySegment)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(48)
        }
        
        categorySegment.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }
        
        listView.snp.makeConstraints {
            $0.top.equalTo(categorySegment.snp.bottom).offset(24)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
        
        managementEmptyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        communityEmptyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

//MARK: CollectionView
extension NotificationCenterView {
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            let footerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(24)
                ),
                elementKind: "footerKind",
                alignment: .bottom
            )
            
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(88)
                ))
            
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(88)),
                subitems: [item]
            )
            group.interItemSpacing = .fixed(4)
            
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = [footerItem]
            section.contentInsets = .init(top: 0, leading: 0, bottom: 44, trailing: 0)
            
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
        
        let footerViewRegistration = UICollectionView.SupplementaryRegistration<NotificationFooterView>(elementKind: "footerKind") { [weak self] footer, _, _ in
            footer.setVisible(self?.showsEndFooter ?? false)
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch Section(rawValue: indexPath.section) {
            case .list:
                collectionView.dequeueConfiguredReusableCell(using: alarmCellRegistration, for: indexPath, item: item)
            default:
                fatalError("NotificationCollectionView: 유효하지 않은 섹션입니다.")
            }
        }
        
        dataSource.supplementaryViewProvider = {
            collectionView.dequeueConfiguredReusableSupplementary(using: footerViewRegistration, for: $2) // $2 == indexPath
        }
         
        return dataSource
    }
    
    func setSnapshot(_ data: [Item], showsEndFooter: Bool) {
        self.showsEndFooter = showsEndFooter
        listView.visibleSupplementaryViews(ofKind: "footerKind")
            .compactMap { $0 as? NotificationFooterView }
            .forEach { $0.setVisible(showsEndFooter) }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.list])
        snapshot.appendItems(data, toSection: .list)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func scrollToTop() {
        listView.setContentOffset(.zero, animated: false)
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
        let postID: UUID?
        let title: String
        let body: String
        let totalText: String?
        let category: AppNotificationCategory
        let detailCategory: AppNotificationType
        let sentTimeLabel: String
        let isUnread: Bool
    }
}

extension Reactive where Base: NotificationCenterView {
    var displayedAlarm: Observable<NotificationCenterView.Alarm> {
        base.listView.rx.willDisplayCell
            .compactMap { [weak base] event in
                guard let base,
                      case .alarm(let alarm)? = base.dataSource.itemIdentifier(for: event.at) else {
                    return nil
                }
                return alarm
            }
    }

    var reachedBottom: Observable<Void> {
        base.listView.rx.willDisplayCell
            .filter { [weak base] event in
                guard let base else { return false }
                let count = base.dataSource.snapshot().numberOfItems
                return count > 0 && event.at.item >= count - 3
            }
            .map { _ in }
    }

    var itemSelected: Observable<NotificationCenterView.Item> {
        base.listView.rx.itemSelected
            .compactMap { base.dataSource.itemIdentifier(for: $0) }
    }

    var backButtonTap: ControlEvent<Void> {
        base.titleView.rx.backButtonTap
    }
}

//MARK: FooterView
final class NotificationFooterView: UICollectionReusableView {
    private let label = UILabel(text: "더 이상 새로운 알림이 없어요.", config: .body14, color: .grayScale600, lines: 1)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(label)
        
        label.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setVisible(_ visible: Bool) {
        label.isHidden = !visible
    }
}
