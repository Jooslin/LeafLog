//
//  PlantCareView.swift
//  LeafLog
//
//  Created by 김주희 on 4/20/26.
//

import SnapKit
import Then
import UIKit

final class PlantCareView: UIView {
    private enum Metric {
        static let headerContentInset: CGFloat = 344 // 헤더 여백
        static let segmentedTopOffset: CGFloat = 268
    }

    let headerView = TitleHeaderView(text: "", hasBackButton: true, rightButtonImage: "edit")

    let plantImageView = PlantCareCircularImageView().then {
        $0.backgroundColor = .grayScale50
        $0.contentMode = .scaleAspectFill
        $0.image = UIImage(named: "camera")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = .grayScale400
    }

    let nameLabel = UILabel(text: "name", config: .headline24).then {
        $0.textAlignment = .center
    }

    let plantNameLabel = UILabel(text: "plant name", config: .label16, color: .grayScale600).then {
        $0.textAlignment = .center
    }

    lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeCollectionViewLayout()
    ).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.contentInset = UIEdgeInsets(
            top: Metric.headerContentInset,
            left: 0,
            bottom: 32,
            right: 0
        )
        $0.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: 16,
            bottom: 0,
            trailing: 16
        )
    }

    let segmentedControl = UISegmentedControl(items: ["기록", "식물정보", "타임라인"]).then {
        $0.selectedSegmentIndex = 0
        $0.backgroundColor = .grayScale50
        $0.selectedSegmentTintColor = .primary600
        $0.setTitleTextAttributes([.foregroundColor: UIColor.grayScale400], for: .normal)
        $0.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }

    var onPreviousDateTapped: (() -> Void)?
    var onNextDateTapped: (() -> Void)?
    var onCompleteTapped: ((PlantCareRecordType) -> Void)? // 완료버튼 클릭
    var onMemoToggleTapped: ((PlantCareRecordType) -> Void)? // 메모 토클 클릭
    var onMemoSaveTapped: ((PlantCareRecordType, String) -> Void)? // 메모 저장 클릭
    var onDiaryToggleTapped: (() -> Void)?
    var onDiarySaveTapped: ((String) -> Void)?
    var onDiaryPhotoTapped: ((UIView) -> Void)?
    var onTimelineFilterTapped: ((PlantCareTimelineFilter) -> Void)?
    var onTimelineSortTapped: (() -> Void)?

    var diaryImagePickerSourceView: UIView {
        collectionView
    }

    private lazy var dataSource = makeDataSource(collectionView)
    private let headerContentLayoutGuide = UILayoutGuide()
    private var scrollAnimator: UIViewPropertyAnimator?
    private var segmentedControlTopConstraint: Constraint? // segment 위쪽 여백
    private var regularLayoutConstraints: [Constraint] = []
    private var compactLayoutConstraints: [Constraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopHeaderAnimator()
    }
}


// MARK: - Layout
private extension PlantCareView {
    func setLayout() {
        headerView.addLayoutGuide(headerContentLayoutGuide)
        headerContentLayoutGuide.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        addSubview(headerView)
        addSubview(collectionView)
        addSubview(plantImageView)
        addSubview(nameLabel)
        addSubview(plantNameLabel)
        addSubview(segmentedControl)

        headerView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        // 기본 상태: 큰 식물 사진이 화면 중앙에 위치
        regularLayoutConstraints.append(contentsOf: plantImageView.snp.prepareConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(32)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(140)
        })

        // 스크롤 상태: 사진이 헤더 왼쪽으로 작게 접힘
        compactLayoutConstraints.append(contentsOf: plantImageView.snp.prepareConstraints {
            $0.top.bottom.leading.equalTo(headerContentLayoutGuide)
            $0.size.equalTo(32)
        })

        regularLayoutConstraints.append(contentsOf: nameLabel.snp.prepareConstraints {
            $0.top.equalTo(plantImageView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
        })

        compactLayoutConstraints.append(contentsOf: nameLabel.snp.prepareConstraints {
            $0.leading.equalTo(plantImageView.snp.trailing)
            $0.centerY.trailing.equalTo(headerContentLayoutGuide)
        })

        plantNameLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.centerX.equalTo(nameLabel)
            $0.leading.greaterThanOrEqualToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        segmentedControl.snp.makeConstraints {
            segmentedControlTopConstraint = $0.top.equalTo(headerView.snp.bottom)
                .offset(Metric.segmentedTopOffset)
                .constraint
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        regularLayoutConstraints.forEach { $0.isActive = true }
    }
}

// MARK: - Header Animation
extension PlantCareView {
    func prepareHeaderAnimator() {
        regularLayoutConstraints.forEach { $0.isActive = false }
        compactLayoutConstraints.forEach { $0.isActive = true }

        // 1초짜리 애니메이션
        scrollAnimator = UIViewPropertyAnimator(duration: 1, curve: .easeInOut)
        scrollAnimator?.addAnimations { [weak self] in
            guard let self else { return }

            self.layoutIfNeeded()
            self.nameLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.plantNameLabel.alpha = 0
        }
        scrollAnimator?.pauseAnimation()
    }

    func updateHeaderAnimation(with contentOffset: CGPoint) {
        // 스크롤 진행도 계산
        let progress = (contentOffset.y + Metric.headerContentInset) / -Metric.headerContentInset
        scrollAnimator?.fractionComplete = min(max(0, -progress * 1.3), 1)

        let segmentOffset = max(0, -contentOffset.y - 76)
        segmentedControlTopConstraint?.update(offset: segmentOffset) // 세그먼트 붙이기
    }

    func stopHeaderAnimator() {
        guard let scrollAnimator else {
            return
        }

        switch scrollAnimator.state {
        case .active:
            scrollAnimator.stopAnimation(true)
        case .stopped:
            scrollAnimator.finishAnimation(at: .current)
        default:
            break
        }
    }
}

// MARK: - Data
extension PlantCareView {
    func configure(plant: MyPlant) {
        nameLabel.text = plant.nickname
        plantNameLabel.text = plant.speciesName
        plantImageView.image = UIImage(named: plant.defaultImageAssetName)
    }

    // 사진 추가하기
    func setPlantImage(_ image: UIImage?) {
        guard let image else {
            return
        }

        plantImageView.image = image
        plantImageView.tintColor = nil
    }

    func setDiaryPhotoImage(_ image: UIImage?) {
        collectionView.visibleCells
            .compactMap { $0 as? PlantCareDiaryCell }
            .forEach { $0.setPhotoImage(image) }
    }

    func setSelectedTab(_ tab: PlantCareTab) {
        guard segmentedControl.selectedSegmentIndex != tab.rawValue else {
            return
        }

        segmentedControl.selectedSegmentIndex = tab.rawValue
    }

    // 기록 탭 Snapshot
    func setRecordSnapshot(
        dateTitle: String,
        items: [PlantCareItem],
        diaryItem: PlantCareDiaryItem,
        animated: Bool = true
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.date, .careRecord, .diary])
        snapshot.appendItems([.date(dateTitle)], toSection: .date)
        snapshot.appendItems(items.map(Item.careRecord), toSection: .careRecord)
        snapshot.appendItems([.diary(diaryItem)], toSection: .diary)

        dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    // 타임라인 탭 Snapshot
    func setTimelineSnapshot(
        controls: PlantCareTimelineControls,
        events: [PlantCareTimelineEvent],
        animated: Bool = true
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.timelineControl, .timelineRecord])
        snapshot.appendItems([.timelineControls(controls)], toSection: .timelineControl)

        let timelineItems = makeTimelineItems(from: events)
        snapshot.appendItems(timelineItems.isEmpty ? [.timelineEmpty] : timelineItems, toSection: .timelineRecord)

        dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    // 식물정보 탭 Snapshot
    func setPlantInfoSnapshot(item: PlantCarePlantInfoItem, animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.plantInfo])
        snapshot.appendItems(item.rows.isEmpty ? [.plantInfoEmpty] : [.plantInfo(item)], toSection: .plantInfo)

        dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func makeTimelineItems(from events: [PlantCareTimelineEvent]) -> [Item] {
        var items: [Item] = []
        var previousDate: String?

        for event in events {
            if previousDate != event.recordDateRaw {
                items.append(.timelineDateHeader(PlantCareTimelineDateHeader(
                    id: event.recordDateRaw,
                    title: timelineDateTitle(from: event)
                )))
                previousDate = event.recordDateRaw
            }

            items.append(.timelineEvent(event))
        }

        return items
    }

    private func timelineDateTitle(from event: PlantCareTimelineEvent) -> String {
        if Calendar.current.isDateInToday(event.date) {
            return "오늘"
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: event.date)
    }
}

// MARK: - CollectionView
private extension PlantCareView {
    func makeCollectionViewLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration().then {
            $0.contentInsetsReference = .layoutMargins
        }

        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, _ in
            guard let section = self?.dataSource.sectionIdentifier(for: sectionIndex) else {
                return nil
            }

            switch section {
            case .date:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(48)
                    )
                )

                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(48)
                    ),
                    subitems: [item]
                )

                return NSCollectionLayoutSection(group: group)

            case .careRecord, .diary, .timelineRecord, .plantInfo:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .estimated(100)
                    )
                )

                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .estimated(100)
                    ),
                    subitems: [item]
                )

                return NSCollectionLayoutSection(group: group).then {
                    $0.interGroupSpacing = section == .careRecord ? 24 : 0
                    $0.contentInsets = NSDirectionalEdgeInsets(
                        top: section == .careRecord ? 16 : 0,
                        leading: 0,
                        bottom: section == .careRecord ? 24 : 40,
                        trailing: 0
                    )
                }

            case .timelineControl:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(80)
                    )
                )

                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(80)
                    ),
                    subitems: [item]
                )

                return NSCollectionLayoutSection(group: group).then {
                    $0.contentInsets = NSDirectionalEdgeInsets(top: 0.1, leading: 0, bottom: 8, trailing: 0)
                }
            }
        }, configuration: configuration)
    }

    func makeDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Section, Item> {
        let dateCellRegistration = UICollectionView.CellRegistration<PlantCareDateCell, Item> { [weak self] cell, _, item in
            guard case .date(let dateTitle) = item else {
                return
            }

            cell.configure(dateTitle: dateTitle)
            cell.onPreviousTapped = { [weak self] in
                self?.onPreviousDateTapped?() // 전날 버튼 눌림
            }
            cell.onNextTapped = { [weak self] in
                self?.onNextDateTapped?() // 다음날 버튼 눌림
            }
        }

        let recordCellRegistration = UICollectionView.CellRegistration<PlantCareRecordCell, Item> { [weak self] cell, _, item in
            guard case .careRecord(let careItem) = item else {
                return
            }

            cell.configure(item: careItem)
            cell.onCompleteTapped = { [weak self] type in
                self?.onCompleteTapped?(type)
            }
            cell.onMemoToggleTapped = { [weak self] type in
                self?.onMemoToggleTapped?(type)
            }
            cell.onMemoSaveTapped = { [weak self] type, memo in
                self?.onMemoSaveTapped?(type, memo)
            }
        }

        let diaryCellRegistration = UICollectionView.CellRegistration<PlantCareDiaryCell, Item> { [weak self] cell, _, item in
            guard case .diary(let diaryItem) = item else {
                return
            }

            cell.configure(item: diaryItem)
            cell.onDiaryToggleTapped = { [weak self] in
                self?.onDiaryToggleTapped?()
            }
            cell.onDiarySaveTapped = { [weak self] diaryText in
                self?.onDiarySaveTapped?(diaryText)
            }
            cell.onDiaryPhotoTapped = { [weak self] sourceView in
                self?.onDiaryPhotoTapped?(sourceView)
            }
        }

        let timelineControlCellRegistration = UICollectionView.CellRegistration<PlantCareTimelineControlCell, Item> { [weak self] cell, _, item in
            guard case .timelineControls(let controls) = item else {
                return
            }

            cell.configure(controls: controls)
            cell.onFilterTapped = { [weak self] filter in
                self?.onTimelineFilterTapped?(filter)
            }
            cell.onSortTapped = { [weak self] in
                self?.onTimelineSortTapped?()
            }
        }

        let timelineDateCellRegistration = UICollectionView.CellRegistration<PlantCareTimelineDateCell, Item> { cell, _, item in
            guard case .timelineDateHeader(let header) = item else {
                return
            }

            cell.configure(title: header.title)
        }

        let timelineEventCellRegistration = UICollectionView.CellRegistration<PlantCareTimelineEventCell, Item> { cell, _, item in
            guard case .timelineEvent(let event) = item else {
                return
            }

            cell.configure(event: event)
        }

        let plantDetailCellRegistration = UICollectionView.CellRegistration<PlantDetailCell, Item> { cell, _, item in
            guard case .plantInfo(let infoItem) = item else {
                return
            }

            cell.configure(
                rows: infoItem.rows.map {
                    PlantDetailCell.RowData(title: $0.title, value: $0.value)
                },
                guide: PlantDetailCell.GuideData(
                    watering: infoItem.guide.watering,
                    temperature: infoItem.guide.temperature,
                    humidity: infoItem.guide.humidity,
                    pest: infoItem.guide.pest
                )
            )
        }

        let emptyCellRegistration = UICollectionView.CellRegistration<PlantCareEmptyCell, Item> { cell, _, item in
            switch item {
            case .plantInfoEmpty:
                cell.configure(message: "식물정보를 불러오는 중이에요.")
            case .timelineEmpty:
                cell.configure(message: "아직 기록된 타임라인이 없어요.")
            default:
                break
            }
        }

        return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .date:
                return collectionView.dequeueConfiguredReusableCell(
                    using: dateCellRegistration,
                    for: indexPath,
                    item: item
                )

            case .careRecord:
                return collectionView.dequeueConfiguredReusableCell(
                    using: recordCellRegistration,
                    for: indexPath,
                    item: item
                )

            case .diary:
                return collectionView.dequeueConfiguredReusableCell(
                    using: diaryCellRegistration,
                    for: indexPath,
                    item: item
                )

            case .timelineControls:
                return collectionView.dequeueConfiguredReusableCell(
                    using: timelineControlCellRegistration,
                    for: indexPath,
                    item: item
                )

            case .timelineDateHeader:
                return collectionView.dequeueConfiguredReusableCell(
                    using: timelineDateCellRegistration,
                    for: indexPath,
                    item: item
                )

            case .timelineEvent:
                return collectionView.dequeueConfiguredReusableCell(
                    using: timelineEventCellRegistration,
                    for: indexPath,
                    item: item
                )

            case .plantInfo:
                return collectionView.dequeueConfiguredReusableCell(
                    using: plantDetailCellRegistration,
                    for: indexPath,
                    item: item
                )

            case .timelineEmpty, .plantInfoEmpty:
                return collectionView.dequeueConfiguredReusableCell(
                    using: emptyCellRegistration,
                    for: indexPath,
                    item: item
                )
            }
        }
    }
}

// MARK: - Section, Item
extension PlantCareView {
    nonisolated
    enum Section: Int {
        case date // 날짜
        case careRecord // 기록 카드들
        case diary // 오늘의 일기
        case timelineControl // 필터, 정렬
        case timelineRecord // 날짜별 타임라인
        case plantInfo // 식물정보 임시 상태
    }

    nonisolated
    enum Item: Hashable {
        case date(String) // 날짜 구역에 들어갈 글자 데이터
        case careRecord(PlantCareItem) // 카드 구역에 들어갈 식물 관리 데이터
        case diary(PlantCareDiaryItem) // 오늘의 일기 데이터
        case timelineControls(PlantCareTimelineControls)
        case timelineDateHeader(PlantCareTimelineDateHeader)
        case timelineEvent(PlantCareTimelineEvent)
        case plantInfo(PlantCarePlantInfoItem) // 식물 상세 사항
        case timelineEmpty
        case plantInfoEmpty
    }
}


private final class PlantCareDateCell: UICollectionViewCell {
    var onPreviousTapped: (() -> Void)?
    var onNextTapped: (() -> Void)?

    private let previousButton = UIButton(type: .system).then {
        $0.setImage(UIImage(named: "arrowLeft"), for: .normal)
        $0.tintColor = .black
    }

    private let nextButton = UIButton(type: .system).then {
        $0.setImage(UIImage(named: "arrowRight"), for: .normal)
        $0.tintColor = .black
    }

    private let dateLabel = UILabel(text: "", config: .label16).then {
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
        setActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(dateTitle: String) {
        dateLabel.text = dateTitle
    }

    private func setLayout() {
        contentView.addSubview(previousButton)
        contentView.addSubview(dateLabel)
        contentView.addSubview(nextButton)

        previousButton.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        nextButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        dateLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(previousButton.snp.trailing).offset(8)
            $0.trailing.lessThanOrEqualTo(nextButton.snp.leading).offset(-8)
        }
    }

    private func setActions() {
        previousButton.addAction(UIAction { [weak self] _ in
            self?.onPreviousTapped?()
        }, for: .touchUpInside)

        nextButton.addAction(UIAction { [weak self] _ in
            self?.onNextTapped?()
        }, for: .touchUpInside)
    }
}

private final class PlantCareRecordCell: UICollectionViewCell {
    var onCompleteTapped: ((PlantCareRecordType) -> Void)? // 완료 버튼
    var onMemoToggleTapped: ((PlantCareRecordType) -> Void)? // 메모 토글 버튼
    var onMemoSaveTapped: ((PlantCareRecordType, String) -> Void)? // 메모 저장 누름

    private var item: PlantCareItem?

    private let cardView = UIView().then {
        $0.backgroundColor = .grayScale50
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.snp.makeConstraints {
            $0.size.equalTo(24)
        }
    }

    private let titleLabel = UILabel(text: "", config: .title14)
    private let completeButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "완료"
        configuration.background.cornerRadius = 8
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        $0.configuration = configuration
    }
    private let memoLabel = UILabel(text: "메모 추가", config: .label14, color: .black)

    private let chevronButton = UIButton(type: .system).then {
        $0.tintColor = .grayScale600
    }

    private let textView = UITextView().then {
        $0.backgroundColor = .white
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = .grayScale900
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.grayScale100.cgColor
        $0.textContainerInset = UIEdgeInsets(top: 12, left: 15, bottom: 20, right: 15)
        $0.isScrollEnabled = true
        $0.snp.makeConstraints {
            $0.height.equalTo(120)
        }
    }

    private let saveButton = UIButton(config: .sSize, title: "저장")
    private lazy var saveButtonRow = UIView().then {
        $0.addSubview(saveButton)

        saveButton.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.width.equalTo(49)
            $0.height.equalTo(28)
        }
    }

    private lazy var memoContentStack = UIStackView(arrangedSubviews: [textView, saveButtonRow]).then {
        $0.axis = .vertical
        $0.spacing = 8
        $0.alignment = .fill
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
        setActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(item: PlantCareItem) {
        self.item = item
        titleLabel.text = item.type.title
        iconImageView.image = UIImage(named: item.type.badge.smallImage)
        textView.text = item.memoText
        memoContentStack.isHidden = !item.isMemoExpanded
        chevronButton.setImage(
            UIImage(named: item.isMemoExpanded ? "arrowUp" : "arrowDown"),
            for: .normal
        )
        configureCompleteButton(isCompleted: item.isCompleted)
    }

    private func setLayout() {
        let titleStack = UIStackView(arrangedSubviews: [iconImageView, titleLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }

        // 아이콘, 제목, 완료 버튼
        let headerRow = UIStackView(arrangedSubviews: [titleStack, completeButton]).then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.distribution = .equalSpacing
        }

        // 메모 추가 + 토글
        let memoRow = UIView()
        memoRow.addSubview(memoLabel)
        memoRow.addSubview(chevronButton)

        memoLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }

        chevronButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview().inset(8)
            $0.size.equalTo(24)
        }

        let divider = SeparateBar()
        let stackView = UIStackView(arrangedSubviews: [headerRow, divider, memoRow, memoContentStack]).then {
            $0.axis = .vertical
            $0.spacing = 8
        }

        contentView.addSubview(cardView)
        cardView.addSubview(stackView)

        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }

        headerRow.snp.makeConstraints {
            $0.height.equalTo(28)
        }

        memoRow.snp.makeConstraints {
            $0.height.equalTo(28)
        }

        saveButtonRow.snp.makeConstraints {
            $0.height.equalTo(28)
        }
    }

    private func setActions() {
        completeButton.addAction(UIAction { [weak self] _ in
            guard let item = self?.item else {
                return
            }

            self?.onCompleteTapped?(item.type)
        }, for: .touchUpInside)

        chevronButton.addAction(UIAction { [weak self] _ in
            guard let item = self?.item else {
                return
            }

            self?.onMemoToggleTapped?(item.type)
        }, for: .touchUpInside)

        saveButton.addAction(UIAction { [weak self] _ in
            guard let self, let item else {
                return
            }

            onMemoSaveTapped?(item.type, textView.text.trimmingCharacters(in: .whitespacesAndNewlines))
        }, for: .touchUpInside)
    }

    private func configureCompleteButton(isCompleted: Bool) {
        var configuration = completeButton.configuration ?? UIButton.Configuration.plain()
        configuration.title = isCompleted ? "취소" : "완료"
        configuration.baseForegroundColor = isCompleted ? .grayScale600 : .grayScale700
        configuration.background.backgroundColor = isCompleted ? .grayScale100 : .white
        completeButton.configuration = configuration
    }
}

private final class PlantCareDiaryCell: UICollectionViewCell {
    var onDiaryToggleTapped: (() -> Void)?
    var onDiarySaveTapped: ((String) -> Void)?
    var onDiaryPhotoTapped: ((UIView) -> Void)?

    private let cardView = UIView().then {
        $0.backgroundColor = .grayScale50
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    private let iconImageView = UIImageView().then {
        $0.image = UIImage(named: "sprout")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = .primary600
        $0.contentMode = .scaleAspectFit
        $0.snp.makeConstraints {
            $0.size.equalTo(24)
        }
    }

    private let titleLabel = UILabel(text: "오늘의 일기", config: .title14)
    private let completeButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "완료"
        configuration.background.cornerRadius = 8
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        $0.configuration = configuration
        $0.isUserInteractionEnabled = false
    }

    private let photoLabel = UILabel(text: "사진 기록", config: .label14, color: .black)
    private let cameraButton = UIButton(type: .system).then {
        $0.setImage(UIImage(named: "camera")?.withRenderingMode(.alwaysTemplate), for: .normal)
        $0.tintColor = .grayScale600
    }

    private let photoImageView = UIImageView().then {
        $0.backgroundColor = .grayScale100
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 12
    }

    private let photoPlaceholderLabel = UILabel(text: "사진을 불러오는 중이에요.", config: .label14, color: .grayScale600).then {
        $0.textAlignment = .center
    }

    private lazy var photoPreviewView = UIView().then {
        $0.backgroundColor = .grayScale100
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.isHidden = true

        $0.addSubview(photoImageView)
        $0.addSubview(photoPlaceholderLabel)

        photoImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        photoPlaceholderLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        $0.snp.makeConstraints {
            $0.height.equalTo(200)
        }
    }

    private let diaryLabel = UILabel(text: "일기 기록", config: .label14, color: .black)
    private let chevronButton = UIButton(type: .system).then {
        $0.tintColor = .grayScale600
    }

    private let textView = UITextView().then {
        $0.backgroundColor = .white
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = .grayScale900
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.grayScale100.cgColor
        $0.textContainerInset = UIEdgeInsets(top: 12, left: 15, bottom: 20, right: 15)
        $0.isScrollEnabled = true
        $0.snp.makeConstraints {
            $0.height.equalTo(120)
        }
    }

    private let saveButton = UIButton(config: .sSize, title: "저장")
    private lazy var saveButtonRow = UIView().then {
        $0.addSubview(saveButton)

        saveButton.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.width.equalTo(49)
            $0.height.equalTo(28)
        }
    }

    private lazy var diaryContentStack = UIStackView(arrangedSubviews: [textView, saveButtonRow]).then {
        $0.axis = .vertical
        $0.spacing = 8
        $0.alignment = .fill
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
        setActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(item: PlantCareDiaryItem) {
        textView.text = item.diaryText
        diaryContentStack.isHidden = !item.isDiaryExpanded
        chevronButton.setImage(
            UIImage(named: item.isDiaryExpanded ? "arrowUp" : "arrowDown"),
            for: .normal
        )
        configurePhotoPreview(hasPhoto: item.diaryPhotoPath?.isEmpty == false)
        configureCompleteButton(isCompleted: item.isCompleted)
    }

    func setPhotoImage(_ image: UIImage?) {
        photoPreviewView.isHidden = image == nil
        photoImageView.image = image
        photoImageView.isHidden = image == nil
        photoPlaceholderLabel.isHidden = image != nil
    }

    private func setLayout() {
        let titleStack = UIStackView(arrangedSubviews: [iconImageView, titleLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }

        let headerRow = UIStackView(arrangedSubviews: [titleStack, completeButton]).then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.distribution = .equalSpacing
        }

        let photoRow = UIView()
        photoRow.addSubview(photoLabel)
        photoRow.addSubview(cameraButton)


        photoLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }

        cameraButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview().inset(8)
            $0.size.equalTo(24)
        }

        let diaryRow = UIView()
        diaryRow.addSubview(diaryLabel)
        diaryRow.addSubview(chevronButton)

        diaryLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }

        chevronButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview().inset(8)
            $0.size.equalTo(24)
        }

        let divider = SeparateBar()
        let stackView = UIStackView(arrangedSubviews: [
            headerRow,
            divider,
            photoRow,
            photoPreviewView,
            diaryRow,
            diaryContentStack
        ]).then {
            $0.axis = .vertical
            $0.spacing = 8
        }

        contentView.addSubview(cardView)
        cardView.addSubview(stackView)

        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }

        headerRow.snp.makeConstraints {
            $0.height.equalTo(28)
        }

        photoRow.snp.makeConstraints {
            $0.height.equalTo(28)
        }

        diaryRow.snp.makeConstraints {
            $0.height.equalTo(28)
        }

        saveButtonRow.snp.makeConstraints {
            $0.height.equalTo(28)
        }
    }

    private func setActions() {
        cameraButton.addAction(UIAction { [weak self] _ in
            guard let self else {
                return
            }

            onDiaryPhotoTapped?(cameraButton)
        }, for: .touchUpInside)

        chevronButton.addAction(UIAction { [weak self] _ in
            self?.onDiaryToggleTapped?()
        }, for: .touchUpInside)

        saveButton.addAction(UIAction { [weak self] _ in
            guard let self else {
                return
            }

            onDiarySaveTapped?(textView.text.trimmingCharacters(in: .whitespacesAndNewlines))
        }, for: .touchUpInside)
    }

    private func configurePhotoPreview(hasPhoto: Bool) {
        photoPreviewView.isHidden = !hasPhoto
        photoImageView.image = nil
        photoImageView.isHidden = true
        photoPlaceholderLabel.isHidden = !hasPhoto
    }

    private func configureCompleteButton(isCompleted: Bool) {
        var configuration = completeButton.configuration ?? UIButton.Configuration.plain()
        configuration.baseForegroundColor = isCompleted ? .grayScale600 : .grayScale700
        configuration.background.backgroundColor = isCompleted ? .grayScale100 : .white
        completeButton.configuration = configuration
    }
}

private final class PlantCareTimelineControlCell: UICollectionViewCell {
    var onFilterTapped: ((PlantCareTimelineFilter) -> Void)?
    var onSortTapped: (() -> Void)?

    private let filterScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
    }

    private let filterStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .center
    }

    private let sortButton = UIButton(type: .system)

    private var filterButtons: [PlantCareTimelineFilter: UIButton] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
        setActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(controls: PlantCareTimelineControls) {
        for (filter, button) in filterButtons {
            configureFilterButton(button, title: filter.title, isSelected: filter == controls.selectedFilter)
        }

        var configuration = UIButton.Configuration.plain()
        configuration.title = controls.sort.title
        configuration.image = UIImage(named: controls.sort.iconName)
        configuration.imagePlacement = .leading
        configuration.imagePadding = 4
        configuration.baseForegroundColor = .grayScale700
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        

        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            return outgoing
        }
        
        sortButton.configuration = configuration
    }

    private func setLayout() {
        contentView.addSubview(filterScrollView)
        contentView.addSubview(sortButton)
        filterScrollView.addSubview(filterStackView)

        PlantCareTimelineFilter.allCases.forEach { filter in
            let button = UIButton(type: .system)
            button.tag = filter.rawValue
            filterButtons[filter] = button
            filterStackView.addArrangedSubview(button)

            button.snp.makeConstraints {
                $0.height.equalTo(32)
            }
        }

        filterScrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(36)
        }

        filterStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }

        sortButton.snp.makeConstraints {
            $0.top.equalTo(filterScrollView.snp.bottom).offset(8)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(28)
        }
    }

    private func setActions() {
        filterButtons.forEach { filter, button in
            button.addAction(UIAction { [weak self] _ in
                self?.onFilterTapped?(filter)
            }, for: .touchUpInside)
        }

        sortButton.addAction(UIAction { [weak self] _ in
            self?.onSortTapped?()
        }, for: .touchUpInside)
    }

    private func configureFilterButton(_ button: UIButton, title: String, isSelected: Bool) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = isSelected ? .primary700 : .grayScale500
        configuration.background.backgroundColor = isSelected ? .primary100 : .white
        configuration.background.strokeColor = isSelected ? .primary600 : .grayScale100
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = 12
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        button.configuration = configuration
    }
}

private final class PlantCareTimelineDateCell: UICollectionViewCell {
    private let lineView = UIView().then {
        $0.backgroundColor = .grayScale100
    }

    private let dotView = UIView().then {
        $0.backgroundColor = .primary600
        $0.layer.cornerRadius = 4
    }

    private let dateLabel = UILabel(text: "", config: .title14, color: .grayScale800)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        dateLabel.text = title
    }

    private func setLayout() {
        contentView.addSubview(lineView)
        contentView.addSubview(dotView)
        contentView.addSubview(dateLabel)

        dotView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(8)
        }

        lineView.snp.makeConstraints {
            $0.top.equalTo(dotView.snp.bottom).offset(16)
            $0.bottom.equalToSuperview()
            $0.centerX.equalTo(dotView)
            $0.width.equalTo(2)
        }

        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(dotView.snp.trailing).offset(12)
            $0.top.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
        }
    }
}

private final class PlantCareTimelineEventCell: UICollectionViewCell {
    private let lineView = UIView().then {
        $0.backgroundColor = .grayScale100
    }

    private let cardView = UIView().then {
        $0.backgroundColor = .grayScale50
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.snp.makeConstraints {
            $0.size.equalTo(24)
        }
    }

    private let titleLabel = UILabel(text: "", config: .title14)
    private let memoLabel = UILabel(text: "", config: .label14, color: .black, lines: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(event: PlantCareTimelineEvent) {
        iconImageView.image = UIImage(named: event.type.badge.smallImage)
        titleLabel.text = event.type.title

        let memo = event.memoText.trimmingCharacters(in: .whitespacesAndNewlines)
        memoLabel.text = memo.isEmpty ? "\(event.type.title) 완료했어요." : memo
    }

    private func setLayout() {
        let titleStack = UIStackView(arrangedSubviews: [iconImageView, titleLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }

        let stackView = UIStackView(arrangedSubviews: [titleStack, SeparateBar(), memoLabel]).then {
            $0.axis = .vertical
            $0.spacing = 8
            $0.alignment = .fill
        }

        contentView.addSubview(lineView)
        contentView.addSubview(cardView)
        cardView.addSubview(stackView)

        lineView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(3)
            $0.width.equalTo(1)
        }

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(8)
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }

        titleStack.snp.makeConstraints {
            $0.height.equalTo(28)
        }
    }
}

private final class PlantCareEmptyCell: UICollectionViewCell {
    private let label = UILabel(text: "", config: .label14, color: .grayScale600).then {
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: String) {
        label.text = message
    }

    private func setLayout() {
        contentView.addSubview(label)

        label.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(32)
        }
    }
}

final class PlantCareCircularImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) * 0.5
        clipsToBounds = true
    }
}
