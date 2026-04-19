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

class CalendarViewController: BaseViewController {
    private let calendarView = CalendarView()
    
    override func loadView() {
        self.view = calendarView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSample()
    }
}

extension CalendarViewController {
    private func setSample() {
        let monthlyData = CalendarView.ManageInfoByDate.generateMonthlySampleData()
        let calendarData = monthlyData.map {
            CalendarView.Item.calendar($0)
        }

        // 1. Water 아이템 예시 (물을 준 식물 정보)
        let treatItem: [CalendarView.Item] = [
            .water(CalendarView.DetailManageInfo(id: UUID(), name: "행운목", badge: .treat)),
            .water(CalendarView.DetailManageInfo(id: UUID(), name: "스투키", badge: .treat)),
        ]

        // 2. Grow 아이템 예시 (성장 기록이 있는 식물 정보)
        let growItem: [CalendarView.Item] = [
            .grow(CalendarView.DetailManageInfo(id: UUID(), name: "선인장", badge: .grow)),
            .grow(CalendarView.DetailManageInfo(id: UUID(), name: "다육이", badge: .grow))
        ]
        
        let data: [CalendarView.Section: [CalendarView.Item]] = [
            .title: [.title],
            .header: [.header("2026년 4월")],
            .filter: [.filter(["전체", "물주기", "분갈이", "비료", "치료"])],
            .calendar: calendarData,
            .grow: growItem,
            .treat: treatItem
        ]
        
        calendarView.setSnapshot(data)
    }
}

// MARK: - Sample Data Generation
extension CalendarView.ManageInfoByDate {
    static func generateMonthlySampleData() -> [CalendarView.ManageInfoByDate] {
        var samples: [CalendarView.ManageInfoByDate] = []
        let allBadges: [CalendarView.Badge] = [.grow, .sprout, .water, .treat]
        
        // 1. 이전 달 데이터 (말일 며칠)
        for d in 28...31 {
            samples.append(CalendarView.ManageInfoByDate(
                currentMonth: false,
                day: d,
                badge: [] // 빈 Set
            ))
        }
        
        // 2. 이번 달 데이터 (1일 ~ 30일)
        for d in 1...30 {
            // 0~4개 사이의 랜덤한 개수 선택
            let randomCount = Int.random(in: 0...4)
            // 배지를 무작위로 섞어서 필요한 개수만큼 추출하여 Set으로 생성
            let randomBadges = Set(allBadges.shuffled().prefix(randomCount))
            
            samples.append(CalendarView.ManageInfoByDate(
                currentMonth: true,
                day: d,
                badge: randomBadges
            ))
        }
        
        // 3. 다음 달 데이터 (초순 며칠)
        for d in 1...5 {
            samples.append(CalendarView.ManageInfoByDate(
                currentMonth: false,
                day: d,
                badge: [] // 빈 Set
            ))
        }
        
        return samples
    }
}


//MARK: CameraClassificationViewController Preview
@available(iOS 17.0, *)
#Preview {
  CalendarViewController()
}
