//
//  PlantCareReactor.swift
//  LeafLog
//
//  Created by 김주희 on 4/20/26.
//

import Auth
import Dependencies
import Foundation
import ReactorKit
import RxSwift
import Supabase
import UIKit

nonisolated
enum PlantCareTab: Int, Hashable {
    case record // 기록
    case plantInfo // 상세 정보
    case timeline // 타임 라인
}

nonisolated
enum PlantCareRecordType: Int, CaseIterable, Hashable {
    case watering // 물주기
    case repotting // 분갈이
    case fertilizing // 비료
    case treating // 치료

    var title: String {
        switch self {
        case .watering:
            return "물주기"
        case .repotting:
            return "분갈이"
        case .fertilizing:
            return "비료주기"
        case .treating:
            return "치료하기"
        }
    }

    var badge: Badge {
        switch self {
        case .watering:
            return .water
        case .repotting:
            return .grow
        case .fertilizing:
            return .sprout
        case .treating:
            return .treat
        }
    }

    // 완료 여부
    func isCompleted(in record: CareRecord?) -> Bool {
        switch self {
        case .watering:
            return record?.watered ?? false
        case .repotting:
            return record?.repotted ?? false
        case .fertilizing:
            return record?.fertilized ?? false
        case .treating:
            return record?.treated ?? false
        }
    }

    // 메모
    func memo(in record: CareRecord?) -> String {
        switch self {
        case .watering:
            return record?.wateredNote ?? ""
        case .repotting:
            return record?.repottedNote ?? ""
        case .fertilizing:
            return record?.fertilizedNote ?? ""
        case .treating:
            return record?.treatedNote ?? ""
        }
    }
}

nonisolated
// 타임라인 전용 타입
enum PlantCareTimelineEventKind: Hashable {
    case care(PlantCareRecordType) // 식물 관리 기록
    case diary // 일기

    var sortOrder: Int {
        switch self {
        case .care(let type):
            return type.rawValue
        case .diary:
            return PlantCareRecordType.allCases.count
        }
    }
}


nonisolated
enum PlantCareTimelineFilter: Int, CaseIterable, Hashable {
    case all
    case watering
    case repotting
    case fertilizing
    case treating
    case diary

    var title: String {
        switch self {
        case .all:
            return "전체"
        case .watering:
            return PlantCareRecordType.watering.title
        case .repotting:
            return PlantCareRecordType.repotting.title
        case .fertilizing:
            return "비료"
        case .treating:
            return "치료"
        case .diary:
            return "일기"
        }
    }

    func matches(_ event: PlantCareTimelineEvent) -> Bool {
        switch self {
        case .all:
            return true
        case .watering:
            return event.kind == .care(.watering)
        case .repotting:
            return event.kind == .care(.repotting)
        case .fertilizing:
            return event.kind == .care(.fertilizing)
        case .treating:
            return event.kind == .care(.treating)
        case .diary:
            return event.kind == .diary
        }
    }
}

nonisolated
enum PlantCareTimelineSort: Hashable {
    case latestFirst
    case oldestFirst

    var title: String {
        switch self {
        case .latestFirst:
            return "최신순"
        case .oldestFirst:
            return "오래된순"
        }
    }

    var iconName: String {
        switch self {
        case .latestFirst:
            return "arrows-down-up"
        case .oldestFirst:
            return "arrows-down-up"
        }
    }

    var toggled: PlantCareTimelineSort {
        switch self {
        case .latestFirst:
            return .oldestFirst
        case .oldestFirst:
            return .latestFirst
        }
    }
}

nonisolated
// 카드 하나에 들어갈 데이터
struct PlantCareItem: Hashable {
    let type: PlantCareRecordType
    var isCompleted: Bool
    var memoText: String
    var isMemoExpanded: Bool
}

nonisolated
enum PlantCareStatus: String, CaseIterable, Hashable {
    case healthy
    case sick
    case unrecoverable

    var title: String {
        switch self {
        case .healthy:
            return "건강함"
        case .sick:
            return "아픔"
        case .unrecoverable:
            return "회복불가"
        }
    }

    static func make(from value: String?) -> PlantCareStatus? {
        switch value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case healthy.rawValue, healthy.title:
            return .healthy
        case sick.rawValue, sick.title:
            return .sick
        case unrecoverable.rawValue, unrecoverable.title, "dead":
            return .unrecoverable
        default:
            return nil
        }
    }
}

nonisolated
struct PlantCareStatusItem: Hashable {
    var selectedStatus: PlantCareStatus?
}

nonisolated
// 식물 일기용 데이터
struct PlantCareDiaryItem: Hashable {
    var diaryText: String
    var diaryPhotoPath: String?
    var diaryPhotoURL: URL?
    var diaryPhotoCacheKey: String?
    var isDiaryExpanded: Bool

    var isCompleted: Bool {
        !diaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || diaryPhotoPath?.isEmpty == false
    }
}

nonisolated
// 타임라인 이벤트
struct PlantCareTimelineControls: Hashable {
    let selectedFilter: PlantCareTimelineFilter
    let sort: PlantCareTimelineSort
}

nonisolated
struct PlantCareTimelineDateHeader: Hashable {
    let id: String
    let title: String
}

nonisolated
struct PlantCareTimelineEvent: Hashable {
    let id: String
    let recordDateRaw: String
    let date: Date
    let kind: PlantCareTimelineEventKind
    let memoText: String
    let photoPath: String?
    let photoURL: URL?
    let photoCacheKey: String?
}

// 식물 정보
nonisolated
struct PlantCarePlantInfoRow: Hashable {
    let title: String
    let value: String
}

nonisolated
struct PlantCarePlantInfoItem: Hashable {
    let rows: [PlantCarePlantInfoRow]
    let guide: PlantCarePlantGuideItem
    let isGuideEnabled: Bool
}

nonisolated
struct PlantCarePlantGuideItem: Hashable {
    let watering: String
    let temperature: String
    let humidity: String
    let pest: String
}


// MARK: - PlantCareReactor
final class PlantCareReactor: Reactor {

    enum Action {
        case viewDidLoad
        case changeTab(PlantCareTab)
        case changeDate(Int)
        case selectTimelineFilter(PlantCareTimelineFilter)
        case toggleTimelineSort
        case selectStatus(PlantCareStatus)
        case toggleMemo(PlantCareRecordType)
        case completeTapped(PlantCareRecordType)
        case saveMemo(PlantCareRecordType, String)
        case toggleDiary
        case saveDiary(String)
        case saveDiaryPhoto(UIImage)
        case deleteDiaryPhoto
        case setGuideEnabled(Bool)
    }

    enum Mutation {
        case setLoading(Bool)
        case setPlant(MyPlant)
        case setPlantDetail(PlantDetail)
        case setSelectedTab(PlantCareTab)
        case setSelectedDate(Date)
        case setStatusItem(PlantCareStatusItem)
        case setItems([PlantCareItem])
        case setDiaryItem(PlantCareDiaryItem)
        case setTimelineEvents([PlantCareTimelineEvent])
        case setTimelineFilter(PlantCareTimelineFilter)
        case setTimelineSort(PlantCareTimelineSort)
        case setErrorMessage(String?)
        case setSuccessMessage(String?)
    }

    struct State {
        let plantID: UUID
        var plant: MyPlant?
        var selectedTab: PlantCareTab = .record
        var selectedDate: Date
        var isLoading = false
        var statusItem: PlantCareStatusItem
        var items: [PlantCareItem]
        var diaryItem: PlantCareDiaryItem
        var plantInfoRows: [PlantCarePlantInfoRow] = []
        var plantGuideItem = PlantCarePlantGuideItem(
            watering: "정보 없음",
            temperature: "정보 없음",
            humidity: "정보 없음",
            pest: "정보 없음"
        )
        var timelineEvents: [PlantCareTimelineEvent] = []
        var timelineFilter: PlantCareTimelineFilter = .all
        var timelineSort: PlantCareTimelineSort = .latestFirst
        @Pulse var errorMessage: String?
        @Pulse var successMessage: String?
    }

    @Dependency(\.careRecordDBManager) private var careRecordDBManager
    @Dependency(\.plantDBManager) private var plantDBManager
    @Dependency(\.networkManager) private var networkManager
    @Dependency(\.supabaseManager) private var supabaseManager

    let initialState: State

    init(plantID: UUID, selectedDate: Date = Date()) {
        let startDate = Calendar.current.startOfDay(for: selectedDate)

        initialState = State(
            plantID: plantID,
            plant: nil,
            selectedDate: startDate,
            statusItem: PlantCareStatusItem(selectedStatus: nil),
            items: Self.makeItems(from: nil, previousItems: []),
            diaryItem: PlantCareDiaryItem(
                diaryText: "",
                diaryPhotoPath: nil,
                diaryPhotoURL: nil,
                diaryPhotoCacheKey: nil,
                isDiaryExpanded: false
            )
        )
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .concat([
                .just(.setLoading(true)),
                loadPlant(),
                loadRecord(
                    for: currentState.selectedDate,
                    previousItems: currentState.items,
                    previousDiaryItem: currentState.diaryItem
                ),
                loadTimelineEvents(),
                .just(.setLoading(false))
            ])

        case .changeTab(let tab):
            return .just(.setSelectedTab(tab))

        case .changeDate(let dayOffset):
            let nextDate = Calendar.current.date(
                byAdding: .day,
                value: dayOffset,
                to: currentState.selectedDate
            ) ?? currentState.selectedDate

            return .concat([
                .just(.setSelectedDate(nextDate)),
                .just(.setLoading(true)),
                loadRecord(for: nextDate, previousItems: [], previousDiaryItem: nil),
                .just(.setLoading(false))
            ])

        case .selectTimelineFilter(let filter):
            return .just(.setTimelineFilter(filter))

        case .toggleTimelineSort:
            return .just(.setTimelineSort(currentState.timelineSort.toggled))

        case .selectStatus(let status):
            let originalStatusItem = currentState.statusItem
            return .concat([
                .just(.setStatusItem(PlantCareStatusItem(selectedStatus: status))),
                saveStatus(status, date: currentState.selectedDate, originalStatusItem: originalStatusItem)
            ])

        case .toggleMemo(let type):
            var nextItems = currentState.items
            guard let index = nextItems.firstIndex(where: { $0.type == type }) else {
                return .empty()
            }

            nextItems[index].isMemoExpanded.toggle()
            return .just(.setItems(nextItems))

        case .completeTapped(let type):
            guard let item = currentState.items.first(where: { $0.type == type }) else {
                return .empty()
            }

            let nextIsCompleted = !item.isCompleted
            if type == .watering,
               !nextIsCompleted,
               // 유일한 물주기 기록인지
               Self.isLastRemainingWateringRecord(
                date: currentState.selectedDate,
                timelineEvents: currentState.timelineEvents
               ) {
                return .just(.setErrorMessage("마지막 물주기 기록은 취소할 수 없어요. 다른 날짜에 물주기 기록을 추가한 뒤 다시 시도해주세요."))
            }

            let originalItems = currentState.items
            var nextItems = currentState.items
            if let index = nextItems.firstIndex(where: { $0.type == type }) {
                nextItems[index].isCompleted.toggle()
            }

            return .concat([
                .just(.setItems(nextItems)),
                saveCompletion(
                    type: type,
                    isCompleted: nextIsCompleted,
                    date: currentState.selectedDate,
                    originalItems: originalItems
                )
            ])

        case let .saveMemo(type, memo):
            return saveMemo(
                type: type,
                memo: memo,
                date: currentState.selectedDate,
                originalItems: currentState.items
            )

        case .toggleDiary:
            var diaryItem = currentState.diaryItem
            diaryItem.isDiaryExpanded.toggle()
            return .just(.setDiaryItem(diaryItem))

        case .saveDiary(let diaryText):
            return saveDiary(
                diaryText: diaryText,
                date: currentState.selectedDate,
                originalDiaryItem: currentState.diaryItem
            )

        case .saveDiaryPhoto(let image):
            return saveDiaryPhoto(
                image: image,
                date: currentState.selectedDate,
                originalDiaryItem: currentState.diaryItem
            )

        case .deleteDiaryPhoto:
            return deleteDiaryPhoto(
                date: currentState.selectedDate,
                originalDiaryItem: currentState.diaryItem
            )

        case .setGuideEnabled(let isEnabled):
            return updateGuideEnabled(isEnabled)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setPlant(let plant):
            newState.plant = plant
            newState.plantInfoRows = Self.makePlantInfoRows(from: plant) // 식물 정보

        case .setPlantDetail(let detail):
            newState.plantGuideItem = Self.makePlantGuideItem(from: detail)

        case .setSelectedTab(let selectedTab):
            newState.selectedTab = selectedTab

        case .setSelectedDate(let selectedDate):
            newState.selectedDate = Calendar.current.startOfDay(for: selectedDate)

        case .setStatusItem(let statusItem):
            newState.statusItem = statusItem

        case .setItems(let items):
            newState.items = items

        case .setDiaryItem(let diaryItem):
            newState.diaryItem = diaryItem

        case .setTimelineEvents(let events):
            newState.timelineEvents = events

        case .setTimelineFilter(let filter):
            newState.timelineFilter = filter

        case .setTimelineSort(let sort):
            newState.timelineSort = sort

        case .setErrorMessage(let message):
            newState.isLoading = false
            newState.errorMessage = message

        case .setSuccessMessage(let message):
            newState.successMessage = message
        }

        return newState
    }
}

// MARK: - DB
private extension PlantCareReactor {
    func loadPlant() -> Observable<Mutation> {
        let plantID = currentState.plantID

        return Observable.create { [plantDBManager, networkManager] observer in
            let task = Task {
                do {
                    let plant = try await plantDBManager.fetchPlant(plantID: plantID)
                    observer.onNext(.setPlant(plant))

                    if let contentNumber = plant.contentNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !contentNumber.isEmpty {
                        let detail = try await networkManager.fetchPlantDetail(contentNumber: contentNumber)
                        observer.onNext(.setPlantDetail(detail))
                    }

                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage("식물 정보를 불러오지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func updateGuideEnabled(_ isEnabled: Bool) -> Observable<Mutation> {
        let plantID = currentState.plantID
        let originalPlant = currentState.plant

        return Observable.create { [plantDBManager] observer in
            let task = Task {
                do {
                    let plant = try await plantDBManager.updateGuideEnabled(
                        plantID: plantID,
                        isEnabled: isEnabled
                    )
                    observer.onNext(.setPlant(plant))
                    observer.onCompleted()
                } catch let error as AuthError {
                    if let originalPlant {
                        observer.onNext(.setPlant(originalPlant))
                    }
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    if let originalPlant {
                        observer.onNext(.setPlant(originalPlant))
                    }
                    observer.onNext(.setErrorMessage("가이드 설정을 저장하지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func loadRecord(
        for date: Date,
        previousItems: [PlantCareItem],
        previousDiaryItem: PlantCareDiaryItem?
    ) -> Observable<Mutation> {
        let plantID = currentState.plantID

        return Observable.create { [careRecordDBManager, supabaseManager] observer in
            let task = Task {
                do {
                    let recordDate = localDate(from: date)
                    let record = try await careRecordDBManager.fetchCareRecord(
                        plantID: plantID,
                        recordDate: recordDate
                    )

                    observer.onNext(.setStatusItem(Self.makeStatusItem(from: record)))
                    observer.onNext(.setItems(Self.makeItems(from: record, previousItems: previousItems)))
                    observer.onNext(.setDiaryItem(
                        try await Self.makeDiaryItem(
                            from: record,
                            previousItem: previousDiaryItem,
                            supabaseManager: supabaseManager
                        )
                    ))
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage("관리 기록을 불러오지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func loadTimelineEvents() -> Observable<Mutation> {
        let plantID = currentState.plantID

        return Observable.create { [careRecordDBManager, supabaseManager] observer in
            let task = Task {
                do {
                    let records = try await careRecordDBManager.fetchCareRecords(plantID: plantID)
                    let events = try await Self.makeTimelineEvents(
                        from: records,
                        supabaseManager: supabaseManager
                    )
                    observer.onNext(.setTimelineEvents(events))
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage("타임라인을 불러오지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func saveStatus(
        _ status: PlantCareStatus,
        date: Date,
        originalStatusItem: PlantCareStatusItem
    ) -> Observable<Mutation> {
        let plantID = currentState.plantID

        return Observable.create { [careRecordDBManager, plantDBManager] observer in
            let task = Task {
                do {
                    var input = Self.emptyInput(plantID: plantID, date: date)
                    input.status = status.rawValue

                    let record = try await careRecordDBManager.upsertCareRecord(input: input)
                    observer.onNext(.setStatusItem(Self.makeStatusItem(from: record)))

                    do {
                        let records = try await careRecordDBManager.fetchCareRecords(plantID: plantID)
                        let plant = try await plantDBManager.updateHealthStatus(
                            plantID: plantID,
                            healthStatus: Self.latestHealthStatus(from: records)
                        )
                        observer.onNext(.setPlant(plant))
                    } catch let error as AuthError {
                        observer.onNext(.setErrorMessage(error.userMessage))
                    } catch {
                        observer.onNext(.setErrorMessage("식물 현재 상태를 동기화하지 못했어요. \(error.localizedDescription)"))
                    }

                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setStatusItem(originalStatusItem))
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setStatusItem(originalStatusItem))
                    observer.onNext(.setErrorMessage("식물 상태를 저장하지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func saveCompletion(
        type: PlantCareRecordType,
        isCompleted: Bool,
        date: Date,
        originalItems: [PlantCareItem]
    ) -> Observable<Mutation> {
        let plantID = currentState.plantID

        return Observable.create { [careRecordDBManager, supabaseManager] observer in
            let task = Task {
                do {
                    var input = Self.emptyInput(plantID: plantID, date: date)
                    Self.applyCompletion(type: type, isCompleted: isCompleted, to: &input)

                    let record = try await careRecordDBManager.upsertCareRecord(input: input)
                    observer.onNext(.setItems(Self.makeItems(from: record, previousItems: originalItems)))
                    try? await Self.syncTimelineEvents(
                        plantID: plantID,
                        manager: careRecordDBManager,
                        supabaseManager: supabaseManager,
                        observer: observer
                    )
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setItems(originalItems))
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setItems(originalItems))
                    observer.onNext(.setErrorMessage("관리 기록을 저장하지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func saveMemo(
        type: PlantCareRecordType,
        memo: String,
        date: Date,
        originalItems: [PlantCareItem]
    ) -> Observable<Mutation> {
        let plantID = currentState.plantID

        return Observable.create { [careRecordDBManager, supabaseManager] observer in
            let task = Task {
                do {
                    var input = Self.emptyInput(plantID: plantID, date: date)
                    Self.applyMemo(type: type, memo: memo, to: &input)
                    Self.applyCompletion(type: type, isCompleted: true, to: &input) // 메모 저장해도 완료로

                    let record = try await careRecordDBManager.upsertCareRecord(input: input)
                    observer.onNext(.setItems(Self.makeItems(from: record, previousItems: originalItems)))
                    try? await Self.syncTimelineEvents(
                        plantID: plantID,
                        manager: careRecordDBManager,
                        supabaseManager: supabaseManager,
                        observer: observer
                    )
                    observer.onNext(.setSuccessMessage("\(type.title) 메모가 저장되었습니다."))
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage("메모를 저장하지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func saveDiary(
        diaryText: String,
        date: Date,
        originalDiaryItem: PlantCareDiaryItem
    ) -> Observable<Mutation> {
        let plantID = currentState.plantID

        return Observable.create { [careRecordDBManager, supabaseManager] observer in
            let task = Task {
                do {
                    var input = Self.emptyInput(plantID: plantID, date: date)
                    input.diaryText = diaryText // 일기 텍스트 저장

                    let record = try await careRecordDBManager.upsertCareRecord(input: input)
                    observer.onNext(.setDiaryItem(
                        try await Self.makeDiaryItem(
                            from: record,
                            previousItem: originalDiaryItem,
                            supabaseManager: supabaseManager
                        )
                    ))
                    // 타임라인 새로고침
                    try? await Self.syncTimelineEvents(
                        plantID: plantID,
                        manager: careRecordDBManager,
                        supabaseManager: supabaseManager,
                        observer: observer
                    )
                    observer.onNext(.setSuccessMessage("오늘의 일기가 저장되었습니다."))
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage("오늘의 일기를 저장하지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    // 사진 경로 저장
    func saveDiaryPhoto(
        image: UIImage,
        date: Date,
        originalDiaryItem: PlantCareDiaryItem
    ) -> Observable<Mutation> {
        let plantID = currentState.plantID

        return Observable.create { [careRecordDBManager, supabaseManager] observer in
            let task = Task {
                do {
                    let recordDate = localDate(from: date)
                    let user = try await supabaseManager.client.auth.user()
                    // 이미지 업로드하고 path값 받기
                    let photoPath = try await supabaseManager.uploadDiaryImage(
                        image,
                        userID: user.id,
                        plantID: plantID,
                        recordDate: recordDate
                    )

                    var input = Self.emptyInput(plantID: plantID, date: date)
                    input.diaryPhotoPath = photoPath

                    let record = try await careRecordDBManager.upsertCareRecord(input: input)
                    observer.onNext(.setDiaryItem(
                        try await Self.makeDiaryItem(
                            from: record,
                            previousItem: originalDiaryItem,
                            supabaseManager: supabaseManager
                        )
                    ))
                    try? await Self.syncTimelineEvents(
                        plantID: plantID,
                        manager: careRecordDBManager,
                        supabaseManager: supabaseManager,
                        observer: observer
                    )
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage("일기 사진을 저장하지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    // 사진 삭제 함수
    func deleteDiaryPhoto(
        date: Date,
        originalDiaryItem: PlantCareDiaryItem
    ) -> Observable<Mutation> {
        let plantID = currentState.plantID
        let photoPath = originalDiaryItem.diaryPhotoPath // 현재 일기의 사진 경로

        return Observable.create { [careRecordDBManager, supabaseManager] observer in
            let task = Task {
                do {
                    var input = Self.emptyInput(plantID: plantID, date: date)
                    input.clearsDiaryPhotoPath = true

                    let record = try await careRecordDBManager.upsertCareRecord(input: input)

                    // db 사진 삭제
                    if let photoPath, !photoPath.isEmpty {
                        try? await supabaseManager.deleteDiaryImage(path: photoPath)
                    }

                    observer.onNext(.setDiaryItem(
                        try await Self.makeDiaryItem(
                            from: record,
                            previousItem: originalDiaryItem,
                            supabaseManager: supabaseManager
                        )
                    ))
                    try? await Self.syncTimelineEvents(
                        plantID: plantID,
                        manager: careRecordDBManager,
                        supabaseManager: supabaseManager,
                        observer: observer
                    )
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage("일기 사진을 삭제하지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
}

// MARK: - Helpers
private extension PlantCareReactor {
    static func syncTimelineEvents(
        plantID: UUID,
        manager: CareRecordDBManager,
        supabaseManager: SupabaseManager,
        observer: AnyObserver<Mutation>
    ) async throws {
        let records = try await manager.fetchCareRecords(plantID: plantID)
        let events = try await makeTimelineEvents(
            from: records,
            supabaseManager: supabaseManager
        )
        observer.onNext(.setTimelineEvents(events))
    }

    static func makeStatusItem(from record: CareRecord?) -> PlantCareStatusItem {
        PlantCareStatusItem(selectedStatus: PlantCareStatus.make(from: record?.status))
    }

    static func latestHealthStatus(from records: [CareRecord]) -> String {
        records
            .compactMap { PlantCareStatus.make(from: $0.status)?.rawValue }
            .first ?? PlantCareStatus.healthy.rawValue
    }

    static func makeItems(from record: CareRecord?, previousItems: [PlantCareItem]) -> [PlantCareItem] {
        PlantCareRecordType.allCases.map { type in
            let previousItem = previousItems.first { $0.type == type }

            return PlantCareItem(
                type: type,
                isCompleted: type.isCompleted(in: record),
                memoText: type.memo(in: record),
                isMemoExpanded: previousItem?.isMemoExpanded ?? false
            )
        }
    }

    static func makeDiaryItem(
        from record: CareRecord?,
        previousItem: PlantCareDiaryItem?,
        supabaseManager: SupabaseManager
    ) async throws -> PlantCareDiaryItem {
        let diaryPhotoPath = record?.diaryPhotoPath?.trimmingCharacters(in: .whitespacesAndNewlines)
        let diaryPhotoCacheKey = makeImageCacheKey(from: diaryPhotoPath, updatedAt: record?.updatedAt)
        let diaryPhotoURL = try? await supabaseManager.resolveDiaryImageURL(
            from: diaryPhotoPath,
            cacheKey: diaryPhotoCacheKey
        )

        return PlantCareDiaryItem(
            diaryText: record?.diaryText ?? "",
            diaryPhotoPath: diaryPhotoPath,
            diaryPhotoURL: diaryPhotoURL,
            diaryPhotoCacheKey: diaryPhotoCacheKey,
            isDiaryExpanded: previousItem?.isDiaryExpanded ?? false
        )
    }

    static func makeTimelineEvents(
        from records: [CareRecord],
        supabaseManager: SupabaseManager
    ) async throws -> [PlantCareTimelineEvent] {
        var timelineEvents: [PlantCareTimelineEvent] = []

        for record in records {
            var events = PlantCareRecordType.allCases.compactMap { type -> PlantCareTimelineEvent? in
                guard type.isCompleted(in: record) else {
                    return nil
                }

                return PlantCareTimelineEvent(
                    id: "\(record.id.uuidString)-\(type.rawValue)",
                    recordDateRaw: record.recordDate.rawValue,
                    date: record.recordDate.date ?? record.recordedAt,
                    kind: .care(type),
                    memoText: type.memo(in: record),
                    photoPath: nil,
                    photoURL: nil,
                    photoCacheKey: nil
                )
            }
            
            // 오늘의 일기 이벤트 추가
            let diaryText = record.diaryText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let diaryPhotoPath = record.diaryPhotoPath?.trimmingCharacters(in: .whitespacesAndNewlines)
            let diaryPhotoCacheKey = makeImageCacheKey(from: diaryPhotoPath, updatedAt: record.updatedAt)
            let diaryPhotoURL = try? await supabaseManager.resolveDiaryImageURL(
                from: diaryPhotoPath,
                cacheKey: diaryPhotoCacheKey
            )

            if !diaryText.isEmpty || diaryPhotoPath?.isEmpty == false {
                events.append(
                    PlantCareTimelineEvent(
                        id: "\(record.id.uuidString)-diary",
                        recordDateRaw: record.recordDate.rawValue,
                        date: record.recordDate.date ?? record.recordedAt,
                        kind: .diary,
                        memoText: diaryText,
                        photoPath: diaryPhotoPath,
                        photoURL: diaryPhotoURL,
                        photoCacheKey: diaryPhotoCacheKey
                    )
                )
            }
            
            timelineEvents.append(contentsOf: events)
        }

        return timelineEvents
    }
    
    // 식물 정보 디테일
    static func makePlantInfoRows(from plant: MyPlant) -> [PlantCarePlantInfoRow] {
        [
            PlantCarePlantInfoRow(title: "데려온 날", value: displayDate(from: plant.createdAt)),
            PlantCarePlantInfoRow(title: "위치", value: plant.location?.rawValue ?? "미지정"),
            PlantCarePlantInfoRow(title: "마지막 급수일", value: displayDate(from: plant.lastWateredAt))
        ]
    }

    static func makePlantGuideItem(from detail: PlantDetail) -> PlantCarePlantGuideItem {
        PlantCarePlantGuideItem(
            watering: nonEmptyText(detail.springWaterCycle, fallback: "정보 없음"),
            temperature: nonEmptyText(detail.growTemperature, fallback: "정보 없음"),
            humidity: nonEmptyText(detail.humidity, fallback: "정보 없음"),
            pest: nonEmptyText(detail.pest, fallback: "정보 없음")
        )
    }

    static func nonEmptyText(_ text: String?, fallback: String) -> String {
        let trimmedText = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText?.isEmpty == false ? trimmedText ?? fallback : fallback
    }

    static func displayDate(from date: Date) -> String {
        plantInfoDateFormatter.string(from: date)
    }

    static let plantInfoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    static func emptyInput(plantID: UUID, date: Date) -> CareRecordUpsertInput {
        CareRecordUpsertInput(
            plantID: plantID,
            recordDate: localDate(from: date),
            recordedAt: nil,
            status: nil,
            watered: nil,
            repotted: nil,
            fertilized: nil,
            treated: nil,
            wateredNote: nil,
            repottedNote: nil,
            fertilizedNote: nil,
            treatedNote: nil,
            diaryText: nil,
            diaryPhotoPath: nil
        )
    }

    static func applyCompletion(
        type: PlantCareRecordType,
        isCompleted: Bool,
        to input: inout CareRecordUpsertInput
    ) {
        switch type {
        case .watering:
            input.watered = isCompleted
        case .repotting:
            input.repotted = isCompleted
        case .fertilizing:
            input.fertilized = isCompleted
        case .treating:
            input.treated = isCompleted
        }
    }

    static func applyMemo(
        type: PlantCareRecordType,
        memo: String,
        to input: inout CareRecordUpsertInput
    ) {
        switch type {
        case .watering:
            input.wateredNote = memo
        case .repotting:
            input.repottedNote = memo
        case .fertilizing:
            input.fertilizedNote = memo
        case .treating:
            input.treatedNote = memo
        }
    }

    static func makeImageCacheKey(from path: String?, updatedAt: Date?) -> String? {
        guard let path, !path.isEmpty else { return nil }
        guard let updatedAt else { return path }
        return "\(path)?updatedAt=\(updatedAt.timeIntervalSince1970)"
    }

// 마지막 물주기 기록이 있는지 확인   
    static func isLastRemainingWateringRecord(
        date: Date,
        timelineEvents: [PlantCareTimelineEvent]
    ) -> Bool {
        let targetDate = localDate(from: date)
        let wateringEvents = timelineEvents.filter { $0.kind == .care(.watering) }

        guard !wateringEvents.isEmpty else {
            return true
        }

        return wateringEvents.allSatisfy { $0.recordDateRaw == targetDate.rawValue }
    }
}


/// Supabase record_date는 yyyy-MM-dd 문자열이라, 사용자의 현재 캘린더 기준 날짜를 그대로 저장한다.
func localDate(from date: Date) -> LocalDate {
    LocalDate(rawValue: plantCareLocalDateFormatter.string(from: date))
}

private let plantCareLocalDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.current
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
