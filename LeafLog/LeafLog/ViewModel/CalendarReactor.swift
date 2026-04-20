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
                calendarDates(of: benchmark),
                calendarCareRecords(of: benchmark)
                ])
            
        case .previousMonth:
            return moveMonthTo(.previous)
            
        case .nextMonth:
            return moveMonthTo(.next)
        }
    }
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .calendarDates(let benchmark, let year, let month, let calendarItems):
            newState.benchmarkDate = benchmark
            newState.data[.header] = [CalendarView.Item.header(year, month)]
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
    private func calendarDates(of date: Date) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            
            let dateComp = self.calendar.dateComponents([.year, .month], from: date)
            guard let year = dateComp.year,
                  let month = dateComp.month else { return Disposables.create() }
            
            let dates = self.calculateDates(of: date)
            let items = datesConvertToItems(currentMonth: month, dates)
            
            observer.onNext(.calendarDates(date, year, month, items))
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    private func moveMonthTo(_ move: MoveMonth) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            
            let benchmark = switch move {
            case .previous:
                benchmarkDate(of: currentState.benchmarkDate, moveTo: .previous)
            case .next:
                benchmarkDate(of: currentState.benchmarkDate, moveTo: .next)
            case .none:
                currentState.benchmarkDate
            }
            
            let dateComp = calendar.dateComponents([.year, .month], from: benchmark)
            guard let year = dateComp.year,
                  let month = dateComp.month else { return Disposables.create() }
            
            let dates = self.calculateDates(of: benchmark)
            let items = self.datesConvertToItems(currentMonth: month, dates)
            
            observer.onNext(.calendarDates(benchmark, year, month, items))
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    private func calendarCareRecords(of date: Date) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self,
                  let calendarRange = calendarRange(of: date) else {
                return Disposables.create()
            }

            Task {
                do {
                    let records = try await self.plantRecords(within: calendarRange.start, calendarRange.end)
                    
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
    
    private func datesConvertToItems(currentMonth: Int, _ dates: [Date]) -> [CalendarView.Item] {
        return dates.reduce([CalendarView.Item]()) {
            let dateComp = calendar.dateComponents([.month, .day], from: $1)
            
            guard let month = dateComp.month,
                  let day = dateComp.day else { return $0 }
            
            let currentMonth = month == currentMonth ? true : false
            
            let manageInfoByDate = CalendarView.ManageInfoByDate(
                currentMonth: currentMonth,
                day: day,
                date: $1,
                badge: []
            )
            
            let item = CalendarView.Item.calendar(manageInfoByDate)
            
            return $0 + [item]
        }
    }
    
    private func plantRecords(within start: Date, _ end: Date) async throws -> [CareRecord] {
        do {
            let plants = try await plantDBManager.fetchMyPlants()
            
            let records = try await careRecordDBManager.fetchAllCareRecordWithin(start: start, end: end, plants: plants.map { $0.id })
            
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
