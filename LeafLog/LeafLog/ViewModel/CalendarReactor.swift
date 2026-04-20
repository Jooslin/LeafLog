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
    }
    
    enum Mutation {
        case setCalendarHeader(Int, Int) // 년, 월
        case setCalendarItem([CalendarView.Item])
        case calendarDates(Date, Int, Int, [CalendarView.Item]) // (기준 일자, 년, 월, [일])
        case calendarRecords([CareRecord])
        case error(String)
    }
    
    struct State {
        var benchmarkDate: Date = Date()
        var data: [CalendarView.Section: [CalendarView.Item]] = [
            .title: [.title],
            .filter: [.filter(["전체", "물주기", "분갈이", "비료", "치료"])]
        ]
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
            return Observable.concat([
                calendarHeaderItem(of: benchmark),
                calendarItems(of: benchmark)
            ])
            
        case .previousMonth:
            let benchmark = benchmarkDate(of: currentState.benchmarkDate, moveTo: .previous)
            return Observable.concat([
                calendarHeaderItem(of: benchmark),
                calendarItems(of: benchmark)
            ])
            
        case .nextMonth:
            let benchmark = benchmarkDate(of: currentState.benchmarkDate, moveTo: .next)
            return Observable.concat([
                calendarHeaderItem(of: benchmark),
                calendarItems(of: benchmark)
            ])
        }
    }
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setCalendarHeader(let year, let month):
            newState.data[.header] = [CalendarView.Item.header(year, month)]
            
        case .setCalendarItem(let items):
            newState.data[.calendar] = items
            
        case .calendarDates(let benchmark, let year, let month, let calendarItems):
            newState.benchmarkDate = benchmark
            newState.data[.calendar] = calendarItems
            
        case .calendarRecords(let records):
            print("calendarRecord Count: ", records.count)
            print("calendarRecordMutation: ", records)
        case .error(let message):
            print("errorMutation: ", message)
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
    
    private func calendarItems(of date: Date) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            let task = Task {
                let dates = self.calculateDates(of: date) // 달력에 표시될 날짜들
                let records = try await self.plantRecords(of: date) // 달력 범위의 기록들
                let items = self.datesConvertToItems(current: date, dates, records: records) // 컬렉션뷰에 표시될 아이템
                
                observer.onNext(.setCalendarItem(items))
                observer.onCompleted()
            }
            
            return Disposables.create() {
                task.cancel()
            }
        }
    }
    
    private func calendarDates(of date: Date) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            
            let dateComp = calendar.dateComponents([.year, .month], from: date)
            guard let year = dateComp.year,
                  let month = dateComp.month else { return Disposables.create() }
            
            Task {
                let records = try await self.plantRecords(of: date)
                let dates = self.calculateDates(of: date)
                let items = self.datesConvertToItems(current: date, dates, records: records)
                
                observer.onNext(.calendarDates(date, year, month, items))
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
//    private func calendarDates(of date: Date) -> Observable<Mutation> {
//        Observable.create { [weak self] observer in
//            guard let self else { return Disposables.create() }
//            
//            let dateComp = self.calendar.dateComponents([.year, .month], from: date)
//            guard let year = dateComp.year,
//                  let month = dateComp.month else { return Disposables.create() }
//            
//            let dates = self.calculateDates(of: date)
//            let items = datesConvertToItems(currentMonth: month, dates)
//            
//            observer.onNext(.calendarDates(date, year, month, items))
//            observer.onCompleted()
//            
//            return Disposables.create()
//        }
//    }
    
//    private func moveMonthTo(_ move: MoveMonth) -> Observable<Mutation> {
//        Observable.create { [weak self] observer in
//            guard let self else { return Disposables.create() }
//            
//            let benchmark = switch move {
//            case .previous:
//                benchmarkDate(of: currentState.benchmarkDate, moveTo: .previous)
//            case .next:
//                benchmarkDate(of: currentState.benchmarkDate, moveTo: .next)
//            case .none:
//                currentState.benchmarkDate
//            }
//            
//            let dateComp = calendar.dateComponents([.year, .month], from: benchmark)
//            guard let year = dateComp.year,
//                  let month = dateComp.month else { return Disposables.create() }
//            
//            Task {
//                let records = try await self.plantRecords(of: benchmark)
//                let dates = self.calculateDates(of: benchmark)
//                let items = self.datesConvertToItems(current: benchmark, dates, records: records)
//                
//                observer.onNext(.calendarDates(benchmark, year, month, items))
//                observer.onCompleted()
//            }
//            
//            return Disposables.create()
//        }
//    }
    
    private func calendarCareRecords(of date: Date) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self,
                  let calendarRange = calendarRange(of: date) else {
                return Disposables.create()
            }
            
            Task {
                do {
                    let records = try await self.plantRecords(of: date)
                    
                    observer.onNext(.calendarRecords(records))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.error("식물 기록을 가져올 수 없습니다."))
                    observer.onCompleted()
                }
            }
            return Disposables.create()
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
    
    private func datesConvertToItems(current: Date, _ dates: [Date], records: [CareRecord]) -> [CalendarView.Item] {
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
            
            let currentMonth = month == currentMonth ? true : false // 달력에 표시될 달(month)과 같은지 비교
            let targetLocalDate = String(format: "%04d-%02d-%02d", year, month, day) // CardRecord.recordDate.rawValue와의 비교용 문자열
  
            var badges: Set<Badge> = []
            
            if let targetRecords = recordDates[targetLocalDate] {
                for record in targetRecords {
                    // 모든 뱃지가 존재할 경우
                    if badges.count == 4 { break }
                    
                    if record.watered { badges.insert(Badge.water) }
                    
                    if record.repotted { badges.insert(Badge.grow) }
                    
                    if record.fertilized { badges.insert(Badge.sprout) }
                    
                    if record.treated { badges.insert(Badge.treat) }
                }
            }
            
            let manageInfoByDate = CalendarView.ManageInfoByDate(
                currentMonth: currentMonth,
                day: day,
                date: targetDate,
                badge: badges
            )
            
            let item = CalendarView.Item.calendar(manageInfoByDate)
            
            return arr + [item]
        }
    }
    
    private func plantRecords(of date: Date) async throws -> [CareRecord] {
        do {
            guard let range = calendarRange(of: date) else { return [] }
            
            let plants = try await plantDBManager.fetchMyPlants()
            
            let records = try await careRecordDBManager.fetchAllCareRecordWithin(start: range.start, end: range.end, plants: plants.map { $0.id })
            
            return records
        } catch {
            throw error
        }
    }
}

extension CalendarReactor {
    enum MoveMonth {
        case previous
        case next
        case none
    }
}
