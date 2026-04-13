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
        
        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(18)
                ),
                elementKind: "headerKind",
                alignment: .top
            )
            
            let section = self?.calendarSectionLayout(environment: environment)
            section?.boundarySupplementaryItems = [headerItem]
            
            return section
        }, configuration: configuration)
    }
    
    private func calendarSectionLayout(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let width = environment.container.effectiveContentSize.width
        let itemWidth = width / 7
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .absolute(width / 7),
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
