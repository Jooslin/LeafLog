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
    }
    
    enum Mutation {
        case calendarDates([CalendarView.Item])
    }
    
    struct State {
        var data: [CalendarView.Section: [CalendarView.Item]] = [
                        .title: [.title],
                        .header: [.header("2026년 4월")],
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
        }
    }
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .calendarDates(let calendarItems):
            newState.data[.calendar] = calendarItems
        }
        return newState
    }
}

extension CalendarReactor {
    private func calendarDates(of date: Date) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            
            let dateComp = self.calendar.dateComponents([.month], from: date)
            guard let month = dateComp.month else { return Disposables.create() }
            
            let dates = self.calculateDates(of: date)
            let items = datesConvertToItems(currentMonth: month, dates)
            
            observer.onNext(.calendarDates(items))
            observer.onCompleted()
            
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
