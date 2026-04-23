//
//  PlantCareViewController.swift
//  LeafLog
//
//  Created by 김주희 on 4/20/26.
//

import Dependencies
import PhotosUI
import ReactorKit
import RxCocoa
import RxSwift
import UIKit
import RxKeyboard

final class PlantCareViewController: BaseViewController, View {
    @Dependency(\.supabaseManager) private var supabaseManager

    private let plantCareView = PlantCareView()
    private var imageLoadTask: Task<Void, Never>?
    private var diaryImageLoadTask: Task<Void, Never>?
    private weak var diaryPhotoPickerSourceView: UIView?

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
        setKeyboardDismissGesture() // 키보드 내리기
        bindKeyboard() // 키보드 텍스트 필드 위치 조정
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        plantCareView.syncHeaderAnimationWithCurrentOffset()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isMovingFromParent || isBeingDismissed {
            imageLoadTask?.cancel()
            diaryImageLoadTask?.cancel()
        }
    }

    func bind(reactor: PlantCareReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    // 키보드 위로 텍스트 필드 올라오는 메서드
    func bindKeyboard() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardHeight in
                guard let self else { return }

                let bottomInset: CGFloat = keyboardHeight > 0 ? keyboardHeight + 32 : 32

                self.plantCareView.collectionView.contentInset.bottom = bottomInset
                self.plantCareView.collectionView.verticalScrollIndicatorInsets.bottom = bottomInset

                if keyboardHeight > 0 {
                    self.scrollToCurrentResponderIfNeeded()
                }
            })
            .disposed(by: disposeBag)
    }

    // 텍스트필드까지 화면 끌어올리기
    private func scrollToCurrentResponderIfNeeded() {
        guard let responder = view.currentFirstResponder, // 지금 타자치고있는 필드
              responder.isDescendant(of: plantCareView.collectionView) else {
            return
        }

        let responderFrame = responder.convert(responder.bounds, to: plantCareView.collectionView)
        let visibleRect = responderFrame.insetBy(dx: 0, dy: -16)
        // 스크롤 올리기
        plantCareView.collectionView.scrollRectToVisible(visibleRect, animated: true)
    }
}

// 키보드를 띄우게 한 뷰 찾기
private extension UIView {
    var currentFirstResponder: UIView? {
        if isFirstResponder {
            return self
        }

        for subview in subviews {
            if let responder = subview.currentFirstResponder {
                return responder
            }
        }

        return nil
    }
}

private struct PlantCareSnapshotState: Equatable {
    let selectedTab: PlantCareTab
    let dateTitle: String
    let items: [PlantCareItem]
    let diaryItem: PlantCareDiaryItem
    let plantInfoItem: PlantCarePlantInfoItem
    let timelineControls: PlantCareTimelineControls
    let timelineEvents: [PlantCareTimelineEvent]
}

// MARK: - Bind
private extension PlantCareViewController {
    func bindAction(reactor: PlantCareReactor) {
        Observable.just(PlantCareReactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        rx.viewWillAppear
            .skip(1)
            .map { _ in PlantCareReactor.Action.viewDidLoad }
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
            .do(onNext: { [weak self] _ in
                // 탭 바뀔때마다 스크롤 맨위로 리셋
                self?.plantCareView.resetHeaderScrollPosition()
            })
            .map(PlantCareReactor.Action.changeTab)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        plantCareView.headerView.backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.steps.accept(AppStep.pageBack)
            })
            .disposed(by: disposeBag)

        plantCareView.headerView.rightButton.rx.tap
            .compactMap { reactor.currentState.plant }
            .map(AppStep.plantEdit)
            .bind(to: steps)
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

        plantCareView.onDiaryPhotoTapped = { [weak self] sourceView in
            self?.diaryPhotoPickerSourceView = sourceView
            self?.steps.accept(AppStep.diaryImageSourceSheet)
        }

        plantCareView.onTimelineFilterTapped = { [weak reactor] filter in
            reactor?.action.onNext(.selectTimelineFilter(filter))
        }

        plantCareView.onTimelineSortTapped = { [weak reactor] in
            reactor?.action.onNext(.toggleTimelineSort)
        }

        plantCareView.onGuideEnabledChanged = { [weak reactor] isEnabled in
            reactor?.action.onNext(.setGuideEnabled(isEnabled))
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
                    plantInfoItem: PlantCarePlantInfoItem(
                        rows: state.plantInfoRows,
                        guide: state.plantGuideItem,
                        isGuideEnabled: state.plant?.guideEnabled ?? true
                    ), // 식물 상세
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
                    loadDiaryImage(from: snapshot.diaryItem.diaryPhotoPath)
                    
                case .plantInfo:
                    plantCareView.setPlantInfoSnapshot(item: snapshot.plantInfoItem)

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

        reactor.pulse(\.$successMessage)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("알림", message))
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
        let filteredEvents = state.timelineEvents.filter {
            state.timelineFilter.matches($0)
        }

        return filteredEvents.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                return lhs.kind.sortOrder < rhs.kind.sortOrder
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

                self.plantCareView.setPlantImage(image)
            } catch {
                // 이미지 로딩 실패 시 카테고리 기본 이미지를 그대로 보여준다.
            }
        }
    }

    func loadDiaryImage(from storedValue: String?) {
        diaryImageLoadTask?.cancel()

        guard let storedValue, !storedValue.isEmpty else {
            plantCareView.setDiaryPhotoImage(nil)
            return
        }

        diaryImageLoadTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                guard let url = try await self.supabaseManager.resolveDiaryImageURL(from: storedValue) else {
                    return
                }

                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let image = UIImage(data: data) else {
                    return
                }

                await MainActor.run {
                    self.plantCareView.setDiaryPhotoImage(image)
                }
            } catch {
                await MainActor.run {
                    self.plantCareView.setDiaryPhotoImage(nil)
                }
            }
        }
    }
}


// Flow가 필요로 하는 정보 제공
extension PlantCareViewController {
    // 액션 시트 기준 뷰
    var diaryImagePickerSourceView: UIView {
        diaryPhotoPickerSourceView ?? plantCareView.diaryImagePickerSourceView
    }

    // 현재 일기 사진이 있는지 여부
    var hasDiaryPhoto: Bool {
        reactor?.currentState.diaryItem.diaryPhotoPath?.isEmpty == false
    }

    // 삭제 버튼 눌렀을때 Reactor로 액션 전달
    func deleteDiaryPhoto() {
        reactor?.action.onNext(.deleteDiaryPhoto)
    }
}

// 앨범 선택 결과 처리
extension PlantCareViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let item = results.first,
              item.itemProvider.canLoadObject(ofClass: UIImage.self) else {
            picker.dismiss(animated: true)
            return
        }

        picker.dismiss(animated: true)

        item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            guard let selectedImage = image as? UIImage else {
                return
            }

            Task { @MainActor [weak self] in
                self?.reactor?.action.onNext(.saveDiaryPhoto(selectedImage)) // 선택한 이미지 보내기
            }
        }
    }
}

// 카메라 촬영 결과 처리
extension PlantCareViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)

        guard let selectedImage = info[.originalImage] as? UIImage else {
            return
        }

        reactor?.action.onNext(.saveDiaryPhoto(selectedImage)) // 찍은 사진 보내기
    }
}
