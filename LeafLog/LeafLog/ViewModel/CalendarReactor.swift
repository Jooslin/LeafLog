//
//  CalendarReactor.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/19/26.
//

import Foundation
import UIKit
import ReactorKit
import Dependencies

final class CalendarReactor: Reactor {
    enum Action {
        case viewWillAppear
        case previousMonth
        case nextMonth
        
        case updateFilter(Int)
        case dateSelected(Date)
    }
    
    enum Mutation {
        case updateBenchmarkDate(Date)
        case updateFilters(Set<Int>)
        
        case setCalendarHeader(Int, Int) // 년, 월
        case setCalendarItem([CalendarView.Item])
        case setFilterItem([CalendarView.Item])
        case setLabelItem([CalendarView.Item])
        
        case setDetailWaterItem([CalendarView.Item])
        case setDetailGrowItem([CalendarView.Item])
        case setDetailSproutItem([CalendarView.Item])
        case setDetailTreatItem([CalendarView.Item])
        
        case error(String)
    }
    
    struct State {
        var benchmarkDate: Date = Date()
        var filters: Set<Int> = []
        var data: [CalendarView.Section: [CalendarView.Item]] = [
            .title: [.title],
            .filter: [.filter([])]
        ]
        @Pulse var errorMessage: String? = nil
    }
    
    let initialState = State()
    
    //MARK: properties
    private let calendar = Calendar.current
    @Dependency(\.plantDBManager) private var plantDBManager
    @Dependency(\.careRecordDBManager) private var careRecordDBManager
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            let benchmark = currentState.benchmarkDate
            let filters = currentState.filters
            
            return Observable.concat([
                .just(.updateBenchmarkDate(benchmark)),
                calendarHeaderItem(of: benchmark),
                calendarItems(of: benchmark, filters: filters)
            ])
            
        case .previousMonth:
            let benchmark = benchmarkDate(of: currentState.benchmarkDate, moveTo: .previous)
            let filters = currentState.filters
            
            return Observable.concat([
                .just(.updateBenchmarkDate(benchmark)),
                calendarHeaderItem(of: benchmark),
                calendarItems(of: benchmark, filters: filters)
            ])
            
        case .nextMonth:
            let benchmark = benchmarkDate(of: currentState.benchmarkDate, moveTo: .next)
            let filters = currentState.filters
            
            return Observable.concat([
                .just(.updateBenchmarkDate(benchmark)),
                calendarHeaderItem(of: benchmark),
                calendarItems(of: benchmark, filters: filters)
            ])
            
        case .updateFilter(let tag):
            let benchmark = currentState.benchmarkDate
            let newFilter = newFilters(tag: tag)
            return Observable.concat([
                .just(.updateFilters(newFilter)),
                calendarItems(of: benchmark, filters: newFilter)
            ])
            
        case .dateSelected(let date):
            return detailItmes(of: date)
        }
    }
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .updateBenchmarkDate(let benchmark):
            newState.benchmarkDate = benchmark
            
        case .updateFilters(let filters):
            newState.filters = filters
            
        case .setCalendarHeader(let year, let month):
            newState.data[.header] = [CalendarView.Item.header(year, month)]
            
        case .setCalendarItem(let items):
            newState.data[.calendar] = items
            
        case .setLabelItem(let item):
            newState.data[.label] = item
            
        case .setFilterItem(let item):
            newState.data[.filter] = item
            
        case .setDetailWaterItem(let items):
            newState.data[.water] = items
            
        case .setDetailGrowItem(let items):
            newState.data[.grow] = items
            
        case .setDetailSproutItem(let items):
            newState.data[.sprout] = items
            
        case .setDetailTreatItem(let items):
            newState.data[.treat] = items
            
        case .error(let message):
            newState.errorMessage = message
        }
        return newState
    }
}

extension CalendarReactor {
    private func calendarHeaderItem(of date: Date) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            
            let dateComp = self.calendar.dateComponents([.year, .month], from: date)
            
            guard let year = dateComp.year,
                  let month = dateComp.month else { return Disposables.create() }
            
            observer.onNext(.setCalendarHeader(year, month))
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    private func calendarFilterItem(filters: Set<Int>) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            
            let item = CalendarView.Item.filter(filters)
            
            observer.onNext(.setFilterItem([item]))
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    private func calendarItems(of date: Date, filters: Set<Int>) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            let task = Task {
                do {
                    let dates = self.calculateDates(of: date) // 달력에 표시될 날짜들
                    let records = try await self.monthlyPlantRecords(of: date) // 달력 범위의 기록들
                    let items = self.datesConvertToItems(current: date, dates, records: records, filters: filters) // 컬렉션뷰에 표시될 아이템
                    
                    observer.onNext(.setCalendarItem(items))
                    observer.onCompleted()
                } catch {
                    if let authError = error as? AuthError {
                        observer.onNext(.error(authError.userMessage))
                        observer.onCompleted()
                    } else {
                        observer.onNext(.error("알 수 없는 에러입니다."))
                        observer.onCompleted()
                    }
                }
            }
            
            return Disposables.create() {
                task.cancel()
            }
        }
    }
    
    private func detailItmes(of date: Date) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            let task = Task {
                do {
                    let dateString = self.dateToString(date, forLabel: true)
                    let labelItem = [CalendarView.Item.label(dateString)]
                    
                    let records = try await self.dailyPlantRecords(of: date) // 특정 날짜의 기록들
                    
                    let water = self.dailyRecordConvertToItem(records, kind: .water)
                    let grow = self.dailyRecordConvertToItem(records, kind: .grow)
                    let sprout = self.dailyRecordConvertToItem(records, kind: .sprout)
                    let treat = self.dailyRecordConvertToItem(records, kind: .treat)
                    
                    observer.onNext(.setLabelItem(labelItem))
                    observer.onNext(.setDetailWaterItem(water))
                    observer.onNext(.setDetailGrowItem(grow))
                    observer.onNext(.setDetailSproutItem(sprout))
                    observer.onNext(.setDetailTreatItem(treat))
                    observer.onCompleted()
                }
                catch {
                    if let authError = error as? AuthError {
                        observer.onNext(.error(authError.userMessage))
                        observer.onCompleted()
                    } else {
                        observer.onNext(.error("알 수 없는 에러입니다."))
                        observer.onCompleted()
                    }
                }
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}

extension CalendarReactor {
    private func benchmarkDate(of date: Date, moveTo: MoveMonth) -> Date {
        switch moveTo {
        case .none:
            return date
        case .previous:
            guard let previous = calendar.date(byAdding: .month, value: -1, to: date) else { return date }
            return previous
        case .next:
            guard let next = calendar.date(byAdding: .month, value: 1, to: date) else { return date }
            return next
        }
    }
    
    private func calendarRange(of date: Date) -> (start: Date, end: Date)? {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let end = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              let startWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday,
              let endWeekday = calendar.dateComponents([.weekday], from: end).weekday else { return nil }
        
        let pastFromMonday = (startWeekday + 5) % 7 // 첫 주에서 월요일까지 필요한 날짜 수
        let addToSunday = 6 - ((endWeekday + 5) % 7) // 마지막 주에서 일요일까지 필요한 날짜 수
        
        guard let startDate = calendar.date(byAdding: .day, value: -pastFromMonday, to: monthInterval.start),
              let endDate = calendar.date(byAdding: .day, value: addToSunday, to: end) else { return nil }
        
        return (start: startDate, end: endDate)
    }
    
    private func calculateDates(of date: Date) -> [Date] {
        guard let range = calendarRange(of: date) else { return [] }
        
        var dates: [Date] = []
        var current = range.start
        
        while current <= range.end {
            dates.append(current)
            
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        
        return dates
    }
    
    private func datesConvertToItems(current: Date, _ dates: [Date], records: [CareRecord], filters: Set<Int>) -> [CalendarView.Item] {
        guard let currentMonth = calendar.dateComponents([.month], from: current).month else { return [] }
        
        // 날짜별로 기록 데이터 분류
        var recordDates = [String: [CareRecord]]()
        for record in records {
            recordDates[record.recordDate.rawValue, default: []] += [record]
        }
        
        return dates.reduce([CalendarView.Item]()) { arr, targetDate in
            let dateComp = calendar.dateComponents([.year, .month, .day], from: targetDate)
            
            guard let year = dateComp.year,
                  let month = dateComp.month,
                  let day = dateComp.day else { return arr }
            
            let isCurrentMonth = month == currentMonth ? true : false // 달력에 표시될 달(month)과 같은지 비교
            let targetLocalDate = String(format: "%04d-%02d-%02d", year, month, day) // CareRecord.recordDate.rawValue와의 비교용 문자열
            
            var badges: Set<Badge> = []
            
            if let targetRecords = recordDates[targetLocalDate] {
                for record in targetRecords {
                    // 모든 뱃지가 존재할 경우
                    if badges.count == 4 { break }
                    
                    if record.watered && (filters.contains(Badge.water.rawValue) || filters.isEmpty) {
                        badges.insert(Badge.water)
                    }
                    
                    if record.repotted && (filters.contains(Badge.grow.rawValue) || filters.isEmpty) {
                        badges.insert(Badge.grow)
                    }
                    
                    if record.fertilized && (filters.contains(Badge.sprout.rawValue) || filters.isEmpty) {
                        badges.insert(Badge.sprout)
                    }
                    
                    if record.treated && (filters.contains(Badge.treat.rawValue) || filters.isEmpty) {
                        badges.insert(Badge.treat)
                    }
                }
            }
            
            let manageInfoByDate = CalendarView.ManageInfoByDate(
                isCurrentMonth: isCurrentMonth,
                day: day,
                date: targetDate,
                badge: badges
            )
            
            let item = CalendarView.Item.calendar(manageInfoByDate)
            
            return arr + [item]
        }
    }
    
    private func monthlyPlantRecords(of date: Date) async throws -> [CareRecord] {
        do {
            guard let range = calendarRange(of: date) else { return [] }
            
            let plants = try await plantDBManager.fetchMyPlants() // 유저가 등록한 모든 식물
            let records = try await careRecordDBManager.fetchAllCareRecordWithin(start: range.start, end: range.end, plants: plants.map { $0.id })
            
            return records
        } catch {
            throw error
        }
    }
    
    private func dailyPlantRecords(of date: Date) async throws -> [MyPlant: CareRecord] {
        let dateRawValue = dateToString(date, forLabel: false)
        
        guard !dateRawValue.isEmpty else { return [:] }
        let targetDate = LocalDate(rawValue: dateRawValue)
        
        let plants = try await plantDBManager.fetchMyPlants() // 유저가 등록한 모든 식물
        
        var records: [MyPlant: CareRecord] = [:]
        
        for plant in plants {
            guard let record = try await careRecordDBManager.fetchCareRecord(plantID: plant.id, recordDate: targetDate) else { continue }
            records[plant] = record
        }
        
        return records
    }
    
    private func dailyRecordConvertToItem(_ record: [MyPlant: CareRecord], kind: Badge) -> [CalendarView.Item] {
        switch kind {
        case .water:
            let watered = record.filter { $0.value.watered }
            return watered.map {
                let data = CalendarView.DetailManageInfo(id: $0.key.id, name: $0.key.speciesName, badge: .water)
                return CalendarView.Item.water(data)
            }
        case .grow:
            let repotted = record.filter { $0.value.repotted }
            return repotted.map {
                let data = CalendarView.DetailManageInfo(id: $0.key.id, name: $0.key.speciesName, badge: .grow)
                return CalendarView.Item.grow(data)
            }
        case .sprout:
            let fertilized = record.filter { $0.value.fertilized }
            return fertilized.map {
                let data = CalendarView.DetailManageInfo(id: $0.key.id, name: $0.key.speciesName, badge: .sprout)
                return CalendarView.Item.sprout(data)
            }
        case .treat:
            let treated = record.filter { $0.value.treated }
            return treated.map {
                let data = CalendarView.DetailManageInfo(id: $0.key.id, name: $0.key.speciesName, badge: .treat)
                return CalendarView.Item.treat(data)
            }
        default:
            return []
        }
    }
    
    private func newFilters(tag: Int) -> Set<Int> {
        var new = currentState.filters
        new.insert(tag)
        return new.count == 4 ? [] : new
    }
}

extension CalendarReactor {
    private func dateToString(_ date: Date, forLabel: Bool) -> String {
        let dateComp = calendar.dateComponents([.year, .month, .day], from: date)
        
        guard let year = dateComp.year,
              let month = dateComp.month,
              let day = dateComp.day else { return "" }
        
        let dateRawValue = String(format: "%04d-%02d-%02d", year, month, day) // LocaleDate를 만들기 위한 date 문자열
        let labelString = "\(year)년 \(month)월 \(day)일"
        
        return forLabel ? labelString : dateRawValue
    }
}

extension CalendarReactor {
    enum MoveMonth {
        case previous
        case next
        case none
    }
}
