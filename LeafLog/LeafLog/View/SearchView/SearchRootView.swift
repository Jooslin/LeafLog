//
//  SearchRootView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/13/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import UIKit
import Then

final class SearchRootView: UIView {
    private enum Layout {
        static let itemHeight: CGFloat = 104
        static let footerHeight: CGFloat = 188
    }

    let searchBarView = SearchBarView().then {
        $0.textField.placeholder = "식물 이름을 검색해 주세요"
    }

    let titleHeaderView = TitleHeaderView(text: "식물 검색", hasBackButton: true, rightButtonImage: "info")

    let filterScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
    }

    let filterStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .fill
        $0.distribution = .fillProportionally
    }

    private(set) var filterButtons: [PlantFilterKind: DropdownFilterButton] = [:]

    let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: SearchRootView.makeLayout()
    ).then {
        $0.backgroundColor = .clear
        $0.showsVerticalScrollIndicator = false
        $0.keyboardDismissMode = .onDrag
    }

    let emptyLabel = UILabel().then {
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 15, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.text = "검색어를 입력해 주세요."
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleHeaderView)
        addSubview(searchBarView)
        addSubview(filterScrollView)
        filterScrollView.addSubview(filterStackView)
        addSubview(collectionView)
        addSubview(emptyLabel)

        titleHeaderView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(8)
            $0.horizontalEdges.equalToSuperview()
        }

        searchBarView.snp.makeConstraints {
            $0.top.equalTo(titleHeaderView.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }

        filterScrollView.snp.makeConstraints {
            $0.top.equalTo(searchBarView.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(40)
        }

        filterStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            $0.height.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(filterScrollView.snp.bottom).offset(16)
            $0.horizontalEdges.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints {
            $0.top.equalTo(filterScrollView.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(32)
        }
    }

    func configureFilterButtons(kinds: [PlantFilterKind]) {
        filterStackView.arrangedSubviews.forEach { view in
            filterStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        filterButtons.removeAll()

        kinds.forEach { kind in
            let button = DropdownFilterButton(title: kind.title)
            button.showsMenuAsPrimaryAction = true
            filterButtons[kind] = button
            filterStackView.addArrangedSubview(button)
        }
    }

    private static func makeLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(Layout.itemHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(Layout.itemHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 0
        )

        let footerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(Layout.footerHeight)
        )
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
        section.boundarySupplementaryItems = [footer]

        return UICollectionViewCompositionalLayout(section: section)
    }
}
