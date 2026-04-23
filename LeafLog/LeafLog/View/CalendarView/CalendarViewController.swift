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
        
        calendarView.rx.alarmButtonTap
            .map { _ in AppStep.alarmCenter }
            .bind(to: steps)
            .disposed(by: disposeBag)

        calendarView.rx.filterButtonTap
            .map { CalendarReactor.Action.updateFilter($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        let itemSelected: Observable<CalendarView.Item> = calendarView.rx.itemSelected.share()
                
        itemSelected
            .compactMap { item -> CalendarReactor.Action? in
                switch item {
                case .calendar(let data):
                    return CalendarReactor.Action.dateSelected(data.date)
                default:
                    return nil
                }
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        itemSelected
            .compactMap { item -> AppStep? in
                switch item {
                case .water(let data), .grow(let data), .sprout(let data), .treat(let data):
                    return AppStep.record(plantID: data.id)
                default:
                    return nil
                }
            }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: CalendarReactor) {
        reactor.state
            .map { $0.data }
            .subscribe(onNext: { [weak self] data in
                self?.calendarView.setSnapshot(data)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("에러", message))
            })
            .disposed(by: disposeBag)
    }
}

//MARK: CameraClassificationViewController Preview
@available(iOS 17.0, *)
#Preview {
  CalendarViewController()
}
