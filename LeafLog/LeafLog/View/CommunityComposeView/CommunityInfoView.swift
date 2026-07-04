//
//  CommunityInfoView.swift
//  LeafLog
//
//  Created by 변예린 on 7/4/26.
//

import SnapKit
import Then
import UIKit

final class CommunityInfoView: UIView {
    let closeButton = UIButton(configuration: .plain()).then {
        $0.configuration?.baseForegroundColor = .grayScale600
        $0.setImage(.x, for: .normal)
    }
    
    private let titleLabel = UILabel(
        text: "🌿 잎로그 커뮤니티 이용 가이드",
        config: .label14,
        color: .black,
        lines: 1
    )
    
    private let subTitleLabel = UILabel(
        text: "모두가 즐거운 식물 생활을 위해 아래 수칙을 지켜주세요!",
        config: .label12,
        color: .grayScale700,
        lines: 1
    )
    
    private let backgroundView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }
    
    private lazy var firstRule = makeRuleStack(of: .first)
    private lazy var secondRule = makeRuleStack(of: .second)
    private lazy var thirdRule = makeRuleStack(of: .third)
    
    private let noticeTitleLabel = UILabel(
        text: "💡 신고 안내",
        config: .label12,
        lines: 1
    )
    
    private let noticeBodyLabel = UILabel(
        text: "가이드라인에 어긋나는 게시글을 발견하시면 [신고] 버튼을 눌러주세요. 운영진이 신속히 확인하겠습니다.",
        config: .label12,
        color: .grayScale600,
        lines: 0
    )
}

extension CommunityInfoView {
    private func makeRuleStack(of rule: Rule) -> UIStackView {
        let title = UILabel(text: rule.title, config: .label12, lines: 1)
        let description = UILabel(text: rule.description, config: .body12, lines: 0).then {
            $0.lineBreakMode = .byWordWrapping
        }
        
        let stackView = UIStackView(arrangedSubviews: [title, description]).then {
            $0.axis = .vertical
            $0.spacing = 0
            $0.alignment = .leading
        }
        
        return stackView
    }
}

extension CommunityInfoView {
    enum Rule {
        case first, second, third
        
        var title: String {
            switch self {
            case .first:
                "1. 서로를 존중해주세요"
            case .second:
                "2. 식물과 관련된 정보만 공유해요"
            case .third:
                "3. 소중한 정보를 보호하세요"
            }
        }
        
        var description: String {
            switch self {
            case .first:
                "비방, 욕설, 차별적 발언은 예고없이 삭제되며 이용이 제한될 수 있습니다. 식물 초보의 질문에도 따뜻하게 답해주세요."
            case .second:
                "주제와 무관한 정치, 종교, 홍보성 게시글은 지양해 주세요. 깨끗한 피드는 우리 모두가 만듭니다."
            case .third:
                "타인의 사진을 무단 도용하거나, 개인정보(연락처, 주소 등)가 노출되지 않도록 주의해 주세요."
            }
        }
    }
}
