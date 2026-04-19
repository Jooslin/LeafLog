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
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return calendarDates(of: Date())
            
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
            
            let current = currentState.benchmarkDate
            guard let currentBenchmark = calendar.dateInterval(of: .month, for: current)?.start else { return Disposables.create() }
            
            switch move {
            case .previous:
                guard let previous = calendar.date(byAdding: .month, value: -1, to: currentBenchmark),
                      let year = calendar.dateComponents([.year, .month], from: previous).year,
                      let month = calendar.dateComponents([.year, .month], from: previous).month else { return Disposables.create() }
                
                let dates = self.calculateDates(of: previous)
                let items = datesConvertToItems(currentMonth: month, dates)
                
                observer.onNext(.calendarDates(previous, year, month, items))
                observer.onCompleted()
            case .next:
                guard let next = calendar.date(byAdding: .month, value: +1, to: currentBenchmark),
                      let year = calendar.dateComponents([.year, .month], from: next).year,
                      let month = calendar.dateComponents([.year, .month], from: next).month else { return Disposables.create() }
                
                let dates = self.calculateDates(of: next)
                let items = datesConvertToItems(currentMonth: month, dates)
                
                observer.onNext(.calendarDates(next, year, month, items))
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}

extension CalendarReactor {
    private func calculateDates(of date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let end = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              let startWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday,
              let endWeekday = calendar.dateComponents([.weekday], from: end).weekday else { return [] }
        
        let pastFromMonday = (startWeekday + 5) % 7 // 첫 주에서 월요일까지 필요한 날짜 수
        let addToSunday = 6 - ((endWeekday + 5) % 7) // 마지막 주에서 일요일까지 필요한 날짜 수
        
        guard let startDate = calendar.date(byAdding: .day, value: -pastFromMonday, to: monthInterval.start),
              let endDate = calendar.date(byAdding: .day, value: addToSunday, to: end) else { return [] }
        
        var dates: [Date] = []
        var current = startDate
        
        while current <= endDate {
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
}

extension CalendarReactor {
    enum MoveMonth {
        case previous
        case next
    }
}
