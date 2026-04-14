//
//  CalendarCollectionView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/12/26.
//

import UIKit

final class CalendarCollectionView: UICollectionView {
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: UICollectionViewLayout())
        collectionViewLayout = makeCompositionalLayout()
        layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
        contentInset = .init(top: 0, left: 0, bottom: 50, right: 0)
        showsVerticalScrollIndicator = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarCollectionView {
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = .layoutMargins
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
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
                    heightDimension: .absolute(80)
                ),
                elementKind: "headerKind",
                alignment: .top
            )
            
            let footerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(70)
                ),
                elementKind: "footerKind",
                alignment: .bottom
            )
  
            let calendarBackgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: "calendarBackground")
            calendarBackgroundItem.contentInsets = .init(top: 0, leading: 0, bottom: 70, trailing: 0)
            
            let detailBackgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: "detailBackground")
            detailBackgroundItem.contentInsets = .init(top: 24, leading: 0, bottom: 0, trailing: 0)
            
            switch CalendarView.Section(rawValue: sectionIndex) {
            case .title, .header, .filter:
                let section = self?.singleItemSectionLayout()
                return section
                
            case .calendar:
                let section = self?.calendarSectionLayout(environment)
                section?.boundarySupplementaryItems = [calendarHeaderItem, footerItem]
                section?.decorationItems = [calendarBackgroundItem]
                section?.contentInsets = .init(top: 0, leading: 24, bottom: 24, trailing: 24)
                
                return section
            default:
                let section = self?.detailSectionLayout()
                section?.boundarySupplementaryItems = [detailHeaderItem]
                section?.decorationItems = [detailBackgroundItem]
                
                return section
            }
            
        }, configuration: configuration)
        
        layout.register(CalendarBackgroundView.self, forDecorationViewOfKind: "calendarBackground")
        layout.register(CalendarBackgroundView.self, forDecorationViewOfKind: "detailBackground")
        return layout
    }
    
    private func singleItemSectionLayout() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(48)
            ))
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(48)),
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
        return section
    }
}
