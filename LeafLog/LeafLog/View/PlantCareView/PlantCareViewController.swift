//
//  PlantCareViewController.swift
//  LeafLog
//
//  Created by 김주희 on 4/20/26.
//

import Dependencies
import ReactorKit
import RxCocoa
import RxSwift
import UIKit

final class PlantCareViewController: BaseViewController, View {
    @Dependency(\.supabaseManager) private var supabaseManager

    private let plantCareView = PlantCareView()
    private var imageLoadTask: Task<Void, Never>?
    private var didPrepareHeaderAnimator = false

    init(reactor: PlantCareReactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = plantCareView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !didPrepareHeaderAnimator else {
            return
        }

        didPrepareHeaderAnimator = true
        plantCareView.prepareHeaderAnimator()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isMovingFromParent || isBeingDismissed {
            imageLoadTask?.cancel()
        }
    }

    func bind(reactor: PlantCareReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
}

private struct PlantCareSnapshotState: Equatable {
    let selectedTab: PlantCareTab
    let dateTitle: String
    let items: [PlantCareItem]
    let diaryItem: PlantCareDiaryItem
    let timelineControls: PlantCareTimelineControls
    let timelineEvents: [PlantCareTimelineEvent]
}

// MARK: - Bind
private extension PlantCareViewController {
    func bindAction(reactor: PlantCareReactor) {
        Observable.just(PlantCareReactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        plantCareView.collectionView.rx.contentOffset
            .observe(on: MainScheduler.instance)
            .bind { [weak self] contentOffset in
                self?.plantCareView.updateHeaderAnimation(with: contentOffset)
            }
            .disposed(by: disposeBag)

        plantCareView.segmentedControl.rx.selectedSegmentIndex
            .skip(1)
            .compactMap { PlantCareTab(rawValue: $0) }
            .map(PlantCareReactor.Action.changeTab)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        plantCareView.headerView.backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.steps.accept(AppStep.pageBack)
            })
            .disposed(by: disposeBag)

        plantCareView.onPreviousDateTapped = { [weak reactor] in
            reactor?.action.onNext(.changeDate(-1))
        }

        plantCareView.onNextDateTapped = { [weak reactor] in
            reactor?.action.onNext(.changeDate(1))
        }

        plantCareView.onCompleteTapped = { [weak reactor] type in
            reactor?.action.onNext(.completeTapped(type))
        }

        plantCareView.onMemoToggleTapped = { [weak reactor] type in
            reactor?.action.onNext(.toggleMemo(type))
        }

        plantCareView.onMemoSaveTapped = { [weak reactor] type, memo in
            reactor?.action.onNext(.saveMemo(type, memo))
        }

        plantCareView.onDiaryToggleTapped = { [weak reactor] in
            reactor?.action.onNext(.toggleDiary)
        }

        plantCareView.onDiarySaveTapped = { [weak reactor] diaryText in
            reactor?.action.onNext(.saveDiary(diaryText))
        }

        plantCareView.onTimelineFilterTapped = { [weak reactor] filter in
            reactor?.action.onNext(.selectTimelineFilter(filter))
        }

        plantCareView.onTimelineSortTapped = { [weak reactor] in
            reactor?.action.onNext(.toggleTimelineSort)
        }
    }

    func bindState(reactor: PlantCareReactor) {
        reactor.state
            .compactMap(\.plant)
            .distinctUntilChanged { $0.id == $1.id && $0.updatedAt == $1.updatedAt }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] plant in
                self?.plantCareView.configure(plant: plant)
                self?.loadPlantImage(from: plant.imagePath)
            })
            .disposed(by: disposeBag)

        let snapshotState: Observable<PlantCareSnapshotState> = reactor.state
            .map { state -> PlantCareSnapshotState in
                PlantCareSnapshotState(
                    selectedTab: state.selectedTab,
                    dateTitle: Self.dateTitle(from: state.selectedDate),
                    items: state.items,
                    diaryItem: state.diaryItem,
                    timelineControls: PlantCareTimelineControls(
                        selectedFilter: state.timelineFilter,
                        sort: state.timelineSort
                    ),
                    timelineEvents: Self.visibleTimelineEvents(from: state)
                )
            }

        snapshotState
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] snapshot in
                guard let self else {
                    return
                }

                plantCareView.setSelectedTab(snapshot.selectedTab)

                switch snapshot.selectedTab {
                case .record:
                    plantCareView.setRecordSnapshot(
                        dateTitle: snapshot.dateTitle,
                        items: snapshot.items,
                        diaryItem: snapshot.diaryItem
                    )

                case .plantInfo:
                    plantCareView.setPlantInfoSnapshot()

                case .timeline:
                    plantCareView.setTimelineSnapshot(
                        controls: snapshot.timelineControls,
                        events: snapshot.timelineEvents
                    )
                }
            })
            .disposed(by: disposeBag)

        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("오류", message))
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UI
private extension PlantCareViewController {
    static func dateTitle(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: date)
    }

    static func visibleTimelineEvents(from state: PlantCareReactor.State) -> [PlantCareTimelineEvent] {
        let filteredEvents: [PlantCareTimelineEvent]
        if let selectedType = state.timelineFilter.recordType {
            filteredEvents = state.timelineEvents.filter { $0.type == selectedType }
        } else {
            filteredEvents = state.timelineEvents
        }

        return filteredEvents.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                return lhs.type.rawValue < rhs.type.rawValue
            }

            switch state.timelineSort {
            case .latestFirst:
                return lhs.date > rhs.date
            case .oldestFirst:
                return lhs.date < rhs.date
            }
        }
    }

    func loadPlantImage(from storedValue: String?) {
        imageLoadTask?.cancel()

        guard let storedValue, !storedValue.isEmpty else {
            return
        }

        imageLoadTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                guard let url = try await self.supabaseManager.resolvePlantImageURL(from: storedValue) else {
                    return
                }

                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let image = UIImage(data: data) else {
                    return
                }

                await MainActor.run {
                    self.plantCareView.setPlantImage(image)
                }
            } catch {
                // 이미지 로딩 실패 시 카테고리 기본 이미지를 그대로 보여준다.
            }
        }
    }
}
