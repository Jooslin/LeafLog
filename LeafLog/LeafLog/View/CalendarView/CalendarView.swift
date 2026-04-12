//
//  CalendarView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/12/26.
//

import UIKit
import SnapKit
import Then

final class CalendarView {
    enum Badge: String {
        case grow = "badgeGrow"
        case sprout = "badgeSprout"
        case water = "badgeWater"
        case treat = "badgeTreat"
    }
    
    struct manageInfoByDate: Hashable {
        let currentMonth: Bool // 표시되는 달 여부
        let day: Int
        let badge: [Badge]
    }
}
