//
//  SearchMainCollectionViewDataSource.swift
//  LeafLog
//
//  Created by Yeseul Jang on 9/1/26.
//

import UIKit

final class SearchMainCollectionViewDataSource: NSObject {
    private enum Layout {
        static let plantItemHeight: CGFloat = 104
        static let emptyItemHeight: CGFloat = 104
        static let bottomGuideItemHeight: CGFloat = 188
    }

    private var itemsByIdentifier: [String: SearchPlantSummaryItem] = [:]
    private var dataSource: UICollectionViewDiffableDataSource<String, SearchListItem>?

    var onSelectButtonTap: ((SearchPlantSummaryItem) -> Void)?
    var onPlantCellTap: ((SearchPlantSummaryItem) -> Void)?
    var onRegisterOtherTap: (() -> Void)?

    func configure(collectionView: UICollectionView) {
        collectionView.register(
            SearchResultCell.self,
            forCellWithReuseIdentifier: SearchResultCell.reuseIdentifier
        )
        collectionView.register(
            SearchEmptyResultCell.self,
            forCellWithReuseIdentifier: SearchEmptyResultCell.reuseIdentifier
        )
        collectionView.register(
            SearchBottomGuideCell.self,
            forCellWithReuseIdentifier: SearchBottomGuideCell.reuseIdentifier
        )
        collectionView.delegate = self
        configureDataSource(collectionView: collectionView)
    }

    func apply(
        listItems: [SearchListItem],
        plants: [SearchPlantSummaryItem],
        animated: Bool = true
    ) {
        itemsByIdentifier = Dictionary(
            uniqueKeysWithValues: plants.map { ($0.contentNumber, $0) }
        )

        var snapshot = NSDiffableDataSourceSnapshot<String, SearchListItem>()
        snapshot.appendSections(["main"])
        snapshot.appendItems(listItems, toSection: "main")
        dataSource?.apply(snapshot, animatingDifferences: animated)
    }

    private func configureDataSource(collectionView: UICollectionView) {
        dataSource = UICollectionViewDiffableDataSource<String, SearchListItem>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            self?.cell(collectionView: collectionView, indexPath: indexPath, item: item) ?? UICollectionViewCell()
        }
    }

    private func cell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: SearchListItem
    ) -> UICollectionViewCell {
        switch item {
        case .plant(let identifier):
            return plantCell(collectionView: collectionView, indexPath: indexPath, identifier: identifier)

        case .empty(let message):
            return emptyCell(collectionView: collectionView, indexPath: indexPath, message: message)

        case .bottomGuide:
            return bottomGuideCell(collectionView: collectionView, indexPath: indexPath)
        }
    }

    private func plantCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        identifier: String
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SearchResultCell.reuseIdentifier,
            for: indexPath
        ) as? SearchResultCell,
              let plant = itemsByIdentifier[identifier]
        else {
            return UICollectionViewCell()
        }

        cell.configure(
            plantName: plant.name,
            confidence: plant.confidence,
            thumbnailURLString: plant.displayThumbnailURL
        )
        cell.onSelectButtonTap = { [weak self] in
            self?.onSelectButtonTap?(plant)
        }
        return cell
    }

    private func emptyCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        message: String
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SearchEmptyResultCell.reuseIdentifier,
            for: indexPath
        ) as? SearchEmptyResultCell else {
            return UICollectionViewCell()
        }

        cell.configure(message: message)
        return cell
    }

    private func bottomGuideCell(
        collectionView: UICollectionView,
        indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SearchBottomGuideCell.reuseIdentifier,
            for: indexPath
        ) as? SearchBottomGuideCell else {
            return UICollectionViewCell()
        }

        cell.onRegisterOtherTap = { [weak self] in
            self?.onRegisterOtherTap?()
        }
        return cell
    }
}

extension SearchMainCollectionViewDataSource: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard case .plant(let identifier) = dataSource?.itemIdentifier(for: indexPath),
              let plant = itemsByIdentifier[identifier]
        else { return }

        onPlantCellTap?(plant)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let height: CGFloat

        switch dataSource?.itemIdentifier(for: indexPath) {
        case .plant:
            height = Layout.plantItemHeight

        case .empty:
            height = Layout.emptyItemHeight

        case .bottomGuide:
            height = Layout.bottomGuideItemHeight

        case .none:
            height = Layout.plantItemHeight
        }

        return CGSize(width: collectionView.bounds.width, height: height)
    }
}
