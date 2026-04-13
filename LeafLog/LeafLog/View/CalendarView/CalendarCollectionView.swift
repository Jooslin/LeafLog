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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarCollectionView {
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
//            let item = NSCollectionLayoutItem(
//                layoutSize: NSCollectionLayoutSize(
//                    widthDimension: .absolute(42),
//                    heightDimension: .absolute(74)
//                ))
            
            let width = environment.container.effectiveContentSize.width
            let itemWidth = width / 7
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(width / 7),
                    heightDimension: .absolute(itemWidth * 1.76))
            )
            
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(itemWidth * 1.76)
                ),
                repeatingSubitem: item,
                count: 7
            )
            
            let section = NSCollectionLayoutSection(group: group)
            
            return section
        }, configuration: configuration)
    }
}
