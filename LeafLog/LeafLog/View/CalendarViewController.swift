//
//  CalendarViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/12/26.
//

import UIKit
import SnapKit
import ReactorKit
import Then
import RxCocoa

class CalendarViewController: BaseViewController, View {
    private let calendarView = CalendarView()
    
    override func loadView() {
        self.view = calendarView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Bind
    func bind(reactor: CalendarReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: CalendarReactor) {
        self.rx.viewWillAppear
            .map { _ in CalendarReactor.Action.viewWillAppear}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        calendarView.rx.headerPreviousButtonTap
            .map { _ in CalendarReactor.Action.previousMonth }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        calendarView.rx.headerNextButtonTap
            .map { _ in CalendarReactor.Action.nextMonth }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        calendarView.rx.itemSelected
            .compactMap { item in
                switch item {
                case .calendar(let data):
                    return CalendarReactor.Action.dateSelected(data.date)
                default:
                    return nil
                }
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: CalendarReactor) {
        reactor.state
            .map { $0.data }
            .subscribe(onNext: { [weak self] data in
                self?.calendarView.setSnapshot(data)
            })
            .disposed(by: disposeBag)
    }
}

extension CalendarViewController {
//    private func setSample() {
//        let monthlyData = CalendarView.ManageInfoByDate.generateMonthlySampleData()
//        let calendarData = monthlyData.map {
//            CalendarView.Item.calendar($0)
//        }
//
//        // 1. Water 아이템 예시 (물을 준 식물 정보)
//        let treatItem: [CalendarView.Item] = [
//            .water(CalendarView.DetailManageInfo(id: UUID(), name: "행운목", badge: .treat)),
//            .water(CalendarView.DetailManageInfo(id: UUID(), name: "스투키", badge: .treat)),
//        ]
//
//        // 2. Grow 아이템 예시 (성장 기록이 있는 식물 정보)
//        let growItem: [CalendarView.Item] = [
//            .grow(CalendarView.DetailManageInfo(id: UUID(), name: "선인장", badge: .grow)),
//            .grow(CalendarView.DetailManageInfo(id: UUID(), name: "다육이", badge: .grow))
//        ]
//        
//        let data: [CalendarView.Section: [CalendarView.Item]] = [
//            .title: [.title],
//            .header: [.header("2026년 4월")],
//            .filter: [.filter(["전체", "물주기", "분갈이", "비료", "치료"])],
//            .calendar: calendarData,
//            .grow: growItem,
//            .treat: treatItem
//        ]
//        
//        calendarView.setSnapshot(data)
//    }
}

//MARK: CameraClassificationViewController Preview
@available(iOS 17.0, *)
#Preview {
  CalendarViewController()
}
