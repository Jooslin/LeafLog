//
//  AlarmSettingDetailView.swift
//  LeafLog
//
//  Created by 변예린 on 10/7/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then

final class AlarmSettingDetailView: UIView {
    let titleView = TitleHeaderView(text: "알림 설정", hasBackButton: true)
    
    fileprivate lazy var listView = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout()).then {
        $0.showsVerticalScrollIndicator = false
        $0.contentInset = .init(top: 0, left: 16, bottom: 50, right: 16)
    }
    
    fileprivate lazy var dataSource = makeCollectionViewDiffableDataSource(listView)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayout() {
        addSubview(titleView)
        addSubview(listView)
        
        titleView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(44)
        }
        
        listView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(24)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
}

//MARK: CollectionView
extension AlarmSettingDetailView {
    nonisolated
    enum Section: Int {
        case management = 0
        case community
        case app
        
        var title: String {
            switch self {
            case .management: "관리 알림"
            case .community: "커뮤니티 알림"
            case .app: "정보 수신"
            }
        }
    }
    
    enum Item: Hashable {
        case management(Setting)
        case community(Setting)
        case app(Setting)
    }
    
    nonisolated
    struct Setting: Hashable {
        let category: AppNotificationType
        let title: String
        let isOn: Bool
    }
    
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        
        configuration.headerMode = .supplementary
        
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
    
    private func makeCollectionViewDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Section, AlarmSettingDetailView.Setting> {
        let headerRegistration = UICollectionView.SupplementaryRegistration<AlarmSettingHeader>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] header, _, indexPath in
            guard let section = self?.dataSource.sectionIdentifier(for: indexPath.section) else {
                return
            }
            header.configure(section)
        }
        
        let settingCellRegistration = UICollectionView.CellRegistration<AlarmSettingCell, AlarmSettingDetailView.Setting> { cell, indexPath, item in
            cell.configure(item: item)
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Section, Setting>(collectionView: listView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: settingCellRegistration, for: indexPath, item: item)
        }
        
        dataSource.supplementaryViewProvider = {
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: $2) // $2 == indexPath
        }
         
        return dataSource
    }
    
    func setSnapshot(_ data: [Section: [Setting]]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Setting>()
        snapshot.appendSections([.management, .community, .app])
        
        for d in data {
            snapshot.appendItems(d.value, toSection: d.key)
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

//MARK: Cell
final class AlarmSettingCell: UICollectionViewCell {
    private let titleLabel = UILabel(text: "", config: .label16, color: .black)
    private let bar = UIView().then {
        $0.backgroundColor = .grayScale100
    }
    fileprivate let alarmSwitch = UISwitch().then {
        $0.onTintColor = .primary600
        $0.isOn = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, alarmSwitch]).then {
            $0.axis = .horizontal
            alarmSwitch.setContentHuggingPriority(.required, for: .horizontal)
            alarmSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        addSubview(stackView)
        addSubview(bar)
        
        stackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview()
        }
        
        bar.snp.makeConstraints {
            $0.height.equalTo(0.5)
            $0.bottom.horizontalEdges.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(item: AlarmSettingDetailView.Setting) {
        titleLabel.text = item.title
        alarmSwitch.isOn = item.isOn
    }
}

//MARK: HeaderView
final class AlarmSettingHeader: UICollectionReusableView {
        private let label = UILabel(text: "", config: .label14, color: .grayScale600, lines: 1)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(label)
            
            label.snp.makeConstraints {
                $0.verticalEdges.equalToSuperview().inset(12)
                $0.leading.equalToSuperview().inset(4)
            }
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    
    func configure(_ section: AlarmSettingDetailView.Section) {
        label.text = section.title
    }
}
