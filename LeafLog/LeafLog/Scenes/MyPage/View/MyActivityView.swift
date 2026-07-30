//
//  MyActivityView.swift
//  LeafLog
//

import SnapKit
import Then
import UIKit

final class MyActivityView: UIView {
    let headerView = TitleHeaderView(text: "내 활동", hasBackButton: true)
    let segmentedControl = AppSegmentedControl(items: ["작성한 글", "댓글단 글"])

    private let sectionTitleLabel = UILabel(text: "게시글", config: .title16)

    private let sortButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "최신순"
        configuration.image = UIImage(named: "arrows-down-up")
        configuration.imagePlacement = .leading
        configuration.imagePadding = 6
        configuration.baseForegroundColor = .grayScale700
        configuration.contentInsets = .zero
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            return attributes
        }
        $0.configuration = configuration
        $0.isUserInteractionEnabled = false
    }

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeCollectionViewLayout()
    ).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
    }

    private let emptyView = MyActivityEmptyView().then {
        $0.isHidden = true
    }

    private let cellRegistration = UICollectionView.CellRegistration<
        MyActivityPostCell,
        MyActivityPost
    > { cell, _, post in
        cell.configure(with: post)
    }

    private lazy var dataSource = UICollectionViewDiffableDataSource<Int, MyActivityPost>(
        collectionView: collectionView
    ) { [weak self] collectionView, indexPath, post in
        guard let self else { return nil }
        return collectionView.dequeueConfiguredReusableCell(
            using: self.cellRegistration,
            for: indexPath,
            item: post
        )
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(posts: [MyActivityPost], tab: MyActivityTab, animated: Bool = true) {
        let isEmpty = posts.isEmpty
        collectionView.isHidden = isEmpty
        emptyView.isHidden = !isEmpty

        if isEmpty {
            emptyView.configure(for: tab)
        }

        var snapshot = NSDiffableDataSourceSnapshot<Int, MyActivityPost>()
        snapshot.appendSections([0])
        snapshot.appendItems(posts)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    private func setupUI() {
        [
            headerView,
            segmentedControl,
            sectionTitleLabel,
            sortButton,
            collectionView,
            emptyView
        ].forEach(addSubview)

        headerView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(48)
        }

        segmentedControl.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        sectionTitleLabel.snp.makeConstraints {
            $0.top.equalTo(segmentedControl.snp.bottom).offset(28)
            $0.leading.equalToSuperview().offset(16)
        }

        sortButton.snp.makeConstraints {
            $0.centerY.equalTo(sectionTitleLabel)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(28)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(sectionTitleLabel.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }

        emptyView.snp.makeConstraints {
            $0.top.equalTo(sectionTitleLabel.snp.bottom).offset(10)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }

    private func makeCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(154)
                )
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(154)
                ),
                subitems: [item]
            )

            return NSCollectionLayoutSection(group: group)
        }
    }
}
