//
//  PostCategory.swift
//  LeafLog
//
//  Created by 변예린 on 7/9/26.
//

enum PostCategory: Int {
    case plantLife = 0
    case plantHelp
    case greenTrip
    
    var title: String {
        switch self {
        case .plantLife: "식물 일상"
        case .plantHelp: "식물 고민"
        case .greenTrip: "초록별 여행"
        }
    }
}
