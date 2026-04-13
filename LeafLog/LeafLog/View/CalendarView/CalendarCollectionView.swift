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
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(50)
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
  
            let backgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: "calendarBackground")
            backgroundItem.contentInsets = .init(top: 0, leading: 0, bottom: 70, trailing: 0)
            
            let section = self?.calendarSectionLayout(environment: environment)
            section?.boundarySupplementaryItems = [headerItem, footerItem]
            section?.decorationItems = [backgroundItem]
            section?.contentInsets = .init(top: 0, leading: 24, bottom: 32, trailing: 24)
            
            return section
        }, configuration: configuration)
        
        layout.register(CalendarBackgroundView.self, forDecorationViewOfKind: "calendarBackground")
        return layout
    }
    
    private func calendarSectionLayout(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
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
}
