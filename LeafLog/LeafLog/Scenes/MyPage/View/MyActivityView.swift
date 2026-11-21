//
//  MyActivityView.swift
//  LeafLog
//
//  Created by 김주희 on 8/19/26.
//

import RxCocoa
import RxRelay
import RxSwift
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
        $0.showsMenuAsPrimaryAction = true
    }

    private let sortSelectionRelay = PublishRelay<PlantCareTimelineSort>()

    var sortSelected: Observable<PlantCareTimelineSort> {
        sortSelectionRelay.asObservable()
    }

    var postSelected: Observable<CommunityPost> {
        collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            }
    }

    var loadNextPage: Observable<Void> {
        collectionView.rx.loadNextPage
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

    var emptyActionButtonTap: ControlEvent<Void> {
        emptyView.actionButtonTap
    }

    private var posts: [CommunityPost] = []
    private var likedPostIDs: Set<UUID> = []
    private var authorNicknames: [UUID: String] = [:]
    private var authorProfileImageURLs: [UUID: URL] = [:]
    private var postImageURLs: [UUID: URL] = [:]

    private lazy var cellRegistration = UICollectionView.CellRegistration<
        CommunityPostCell,
        CommunityPost
    > { [weak self] cell, indexPath, post in
        guard let self else { return }
        cell.configure(
            with: post,
            isLiked: likedPostIDs.contains(post.id),
            nickname: authorNicknames[post.authorID],
            profileImageURL: authorProfileImageURLs[post.authorID],
            postImageURL: postImageURLs[post.id],
            showsCategory: false,
            showsSeparator: indexPath.item < posts.count - 1
        )
    }

    private lazy var dataSource = UICollectionViewDiffableDataSource<Int, CommunityPost>(
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
        _ = cellRegistration
        backgroundColor = .white
        setupUI()
        configureSortButton(sort: .latestFirst)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(
        posts: [CommunityPost],
        tab: MyActivityTab,
        likedPostIDs: Set<UUID>,
        authorNicknames: [UUID: String],
        authorProfileImageURLs: [UUID: URL],
        postImageURLs: [UUID: URL],
        animated: Bool = true
    ) {
        self.posts = posts
        self.likedPostIDs = likedPostIDs
        self.authorNicknames = authorNicknames
        self.authorProfileImageURLs = authorProfileImageURLs
        self.postImageURLs = postImageURLs

        let isEmpty = posts.isEmpty
        collectionView.isHidden = isEmpty

        if isEmpty {
            emptyView.configure(for: tab)
        }

        var snapshot = NSDiffableDataSourceSnapshot<Int, CommunityPost>()
        snapshot.appendSections([0])
        snapshot.appendItems(posts)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    func setEmptyStateVisible(_ isVisible: Bool) {
        emptyView.isHidden = !isVisible
    }

    func scrollToTop() {
        collectionView.setContentOffset(
            CGPoint(x: 0, y: -collectionView.adjustedContentInset.top),
            animated: false
        )
    }

    func configureSortButton(sort: PlantCareTimelineSort) {
        var configuration = sortButton.configuration
        configuration?.title = sort == .latestFirst ? "최신순" : "오래된 순"
        configuration?.image = UIImage(named: sort.iconName)
        sortButton.configuration = configuration

        let options: [PlantCareTimelineSort] = [.latestFirst, .oldestFirst]
        sortButton.menu = UIMenu(options: .singleSelection, children: options.map { option in
            UIAction(
                title: option == .latestFirst ? "최신순" : "오래된 순",
                state: option == sort ? .on : .off
            ) { [weak self] _ in
                guard option != sort else { return }
                self?.sortSelectionRelay.accept(option)
            }
        })
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
