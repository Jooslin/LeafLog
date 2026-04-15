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
        
        backgroundColor = .grayScale50
        collectionViewLayout = makeCompositionalLayout()
        showsVerticalScrollIndicator = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlantCollectionView {
//    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
//        let configuration = UICollectionViewCompositionalLayoutConfiguration()
//        
//        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
//            let item = NSCollectionLayoutItem(
//                layoutSize: NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1),
//                    heightDimension: .fractionalWidth(0.63)
//                ))
//            
//            let group = NSCollectionLayoutGroup.vertical(
//                layoutSize: NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1),
//                    heightDimension: .fractionalWidth(0.63)),
//                subitems: [item]
//            )
//            
//            let section = NSCollectionLayoutSection(group: group)
////            section.orthogonalScrollingBehavior = .groupPaging
//            
//            return section
//        }, configuration: configuration)
//    }
    
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            let itemWidth = environment.container.effectiveContentSize.width / 3
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(itemWidth),
                    heightDimension: .absolute(itemWidth * 0.7)
                ))
            
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(itemWidth * 2)
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
