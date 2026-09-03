//
//  CommunityView.swift
//  LeafLog
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class CommunityView: UIView {
    fileprivate let categoryFilters: [PostCategory?] = [nil] + PostCategory.allCases.map(Optional.some)

    let titleView = TitleHeaderView(
        text: "",
        hasBackButton: false,
        rightButtonImage: "bell"
    )

    lazy var categoryButtons = categoryFilters.map { category in
        let button = SelectionButton(title: category?.title ?? "전체")
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }

    let writeButton = UIButton(config: .lSize, title: "글작성").then {
        $0.isSelected = true

        var configuration = $0.configuration
        configuration?.image = UIImage(named: "plus")?.withRenderingMode(.alwaysTemplate)
        configuration?.imagePlacement = .leading
        configuration?.imagePadding = 4
        configuration?.background.cornerRadius = 12
        $0.configuration = configuration
    }

    fileprivate let refreshControl = UIRefreshControl()

    private let categoryScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
        $0.alwaysBounceHorizontal = false
    }

    private lazy var categoryStackView = UIStackView(arrangedSubviews: categoryButtons).then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .center
        $0.distribution = .fill
    }

    private let categorySeparator = SeparateBar()

    fileprivate lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeCollectionViewLayout()
    ).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 88, right: 0)
    }

    private let emptyView = EmptyView(
        image: "chatColored",
        title: "아직 게시글이 없어요",
        subTitle: "궁금한 점을 질문하거나\n식물 이야기를 나눠보세요",
        needButton: false
    ).then {
        $0.isHidden = true
    }

    fileprivate var posts: [CommunityPost] = []
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
            nickname: authorNicknames[post.authorID],
            profileImageURL: authorProfileImageURLs[post.authorID],
            postImageURL: postImageURLs[post.id],
            showsCategory: true,
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
        categoryButtons.first?.isSelected = true
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(
        posts: [CommunityPost],
        authorNicknames: [UUID: String],
        authorProfileImageURLs: [UUID: URL],
        postImageURLs: [UUID: URL],
        animated: Bool = true
    ) {
        let existingPosts = Set(dataSource.snapshot().itemIdentifiers)

        self.posts = posts
        self.authorNicknames = authorNicknames
        self.authorProfileImageURLs = authorProfileImageURLs
        self.postImageURLs = postImageURLs

        let isEmpty = posts.isEmpty
        collectionView.isHidden = false
        collectionView.backgroundColor = isEmpty ? .clear : .white
        emptyView.isHidden = !isEmpty

        var snapshot = NSDiffableDataSourceSnapshot<Int, CommunityPost>()
        snapshot.appendSections([0])
        snapshot.appendItems(posts)

        let retainedPosts = posts.filter(existingPosts.contains)
        snapshot.reconfigureItems(retainedPosts)

        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    func selectCategory(_ category: PostCategory?) {
        categoryButtons.enumerated().forEach { index, button in
            button.isSelected = categoryFilters[index] == category
        }
    }

    func configureAlarmButton(hasUnreadNotification: Bool) {
        titleView.setRightButtonImage(hasUnreadNotification ? "bellOn" : "bell")
    }

    func setRefreshing(_ isRefreshing: Bool) {
        if isRefreshing {
            if !refreshControl.isRefreshing {
                refreshControl.beginRefreshing()
            }
        } else {
            refreshControl.endRefreshing()
        }
    }

    private func setupUI() {
        [
            emptyView,
            titleView,
            categoryScrollView,
            categorySeparator,
            collectionView,
            writeButton
        ].forEach(addSubview)

        categoryScrollView.addSubview(categoryStackView)
        collectionView.refreshControl = refreshControl

        categoryButtons.forEach { button in
            button.snp.makeConstraints {
                $0.width.equalTo(button.intrinsicContentSize.width)
            }
        }

        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(48)
        }

        categoryScrollView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(22)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(32)
        }

        categoryStackView.snp.makeConstraints {
            $0.verticalEdges.equalTo(categoryScrollView.contentLayoutGuide)
            $0.horizontalEdges.equalTo(categoryScrollView.contentLayoutGuide).inset(16)
            $0.height.equalTo(categoryScrollView.frameLayoutGuide)
        }

        categorySeparator.snp.makeConstraints {
            $0.top.equalTo(categoryScrollView.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(categorySeparator.snp.bottom)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }

        emptyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        writeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
            $0.height.equalTo(40)
        }
    }

    private func makeCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(180)
                )
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(180)
                ),
                subitems: [item]
            )

            return NSCollectionLayoutSection(group: group)
        }
    }
}

extension Reactive where Base: CommunityView {
    var categorySelected: Observable<PostCategory?> {
        Observable.merge(
            zip(base.categoryFilters, base.categoryButtons).map { category, button in
                button.rx.tap.map { category }
            }
        )
    }

    var writeButtonTap: ControlEvent<Void> {
        base.writeButton.rx.tap
    }
    
    var postSelected: Observable<CommunityPost> {
        base.collectionView.rx.itemSelected
            .compactMap { indexPath in
                guard base.posts.indices.contains(indexPath.item) else { return nil }
                return base.posts[indexPath.item]
            }
    }

    var refresh: ControlEvent<Void> {
        base.refreshControl.rx.controlEvent(.valueChanged)
    }
}
