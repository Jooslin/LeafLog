//
//  CommunityReportReason.swift
//  LeafLog
//
//  Created by Yeseul Jang on 9/6/26.
//

import Foundation

enum CommunityReportReason: String, CaseIterable, Equatable, Sendable {
    case inappropriateContent = "inappropriate_content"
    case advertising
    case unrelatedToPlants = "unrelated_to_plants"
    case privacyOrImpersonation = "privacy_or_impersonation"
    case spam
    
    var title: String {
        switch self {
        case .inappropriateContent:
            return "부적절한 콘텐츠"
        case .advertising:
            return "광고/홍보"
        case .unrelatedToPlants:
            return "식물과 관련 없는 내용"
        case .privacyOrImpersonation:
            return "개인정보/도용"
        case .spam:
            return "반복 게시/도배"
        }
    }
}
