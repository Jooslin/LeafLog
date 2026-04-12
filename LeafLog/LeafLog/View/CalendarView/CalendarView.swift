//
//  CalendarView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/12/26.
//

import UIKit
import SnapKit
import Then

final class CalendarView: UIView {
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
    
    //MARK: properties
    let collectionView = CalendarCollectionView()
    
    init() {
        super.init(frame: .zero)
        self.setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarView {
    private func setLayout() {
        self.addSubview(collectionView)
        
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
