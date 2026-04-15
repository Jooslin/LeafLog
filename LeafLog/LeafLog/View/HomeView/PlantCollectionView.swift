//
//  PlantCollectionView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit

final class PlantCollectionView: UICollectionView {
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: UICollectionViewLayout())
        
        layoutMargins = .init(top: 0, left: 8, bottom: 0, right: 8)
        backgroundColor = .grayScale50
        collectionViewLayout = makeCompositionalLayout()
        showsVerticalScrollIndicator = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlantCollectionView {    
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = .layoutMargins
        
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            let itemWidth = environment.container.effectiveContentSize.width / 3
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(itemWidth),
                    heightDimension: .fractionalHeight(1)
                ))
            
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(itemWidth * 1.8)
                ),
                repeatingSubitem: item,
                count: 3
            )
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 32
            
            return section
        }, configuration: configuration)
    }
}
