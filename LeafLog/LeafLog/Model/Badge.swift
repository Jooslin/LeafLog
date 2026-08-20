//
//  Badge.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//
import UIKit

enum Badge: Int {
    case water = 0
    case grow
    case sprout
    case treat
    case sun, cloud, temperature, bug
    
    // 알람용
    case alarmFavorite
    case alarmComment
    
    var title: String {
        switch self {
        case .water: "물주기"
        case .grow: "분갈이"
        case .sprout: "비료"
        case .treat: "치료"
        default: ""
        }
    }
    
    var smallImage: String {
        switch self {
        case .water: "badgeWaterSmall"
        case .grow: "badgeGrowSmall"
        case .sprout: "badgeSproutSmall"
        case .treat: "badgeTreatSmall"
        case .sun: "badgeSunSmall"
        default: ""
        }
    }
    
    var bigImage: String {
        switch self {
        case .water: "badgeWaterBig"
        case .grow: "badgeGrowBig"
        case .sprout: "badgeSproutBig"
        case .treat: "badgeTreatBig"
        case .sun: "badgeSunBig"
        case .cloud: "badgeCloudBig"
        case .temperature: "badgeTemperatureBig"
        case .bug: "badgeBugBig"
            
        case .alarmFavorite: "alarmFavorite"
        case .alarmComment: "alarmComment"
        }
    }
    
    var color: UIColor {
        switch self {
        case .water: .subBlue
        case .grow: .subBrown
        case .sprout: .primary600
        case .treat: .subRed
        default: .black
        }
    }
}
