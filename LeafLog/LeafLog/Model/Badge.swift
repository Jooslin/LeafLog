//
//  Badge.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//
import UIKit

enum Badge: String {
    case water = "물주기"
    case grow = "분갈이"
    case sprout = "비료"
    case treat = "치료"
    
    var smallImage: String {
        switch self {
        case .water: "badgeWaterSmall"
        case .grow: "badgeGrowSmall"
        case .sprout: "badgeSproutSmall"
        case .treat: "badgeTreatSmall"
        }
    }
    
    var bigImage: String {
        switch self {
        case .water: "badgeWaterBig"
        case .grow: "badgeGrowBig"
        case .sprout: "badgeSproutBig"
        case .treat: "badgeTreatBig"
        }
    }
    
    var color: UIColor {
        switch self {
        case .water: .subBlue
        case .grow: .subBrown
        case .sprout: .primary600
        case .treat: .subRed
        }
    }
}
