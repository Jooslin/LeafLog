//
//  MatchStatusBadgeLabel.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/13/26.
//
import UIKit

/*
 검색 결과의 일치율/상태 값을 배지 형태로 보여줄 때 사용하는 라벨입니다.

 생성 시
 let badgeLabel = MatchStatusBadgeLabel()

 다른 스타일 적용 시 - 아무것도 안적으면 "일치율" 자동 적용
 badgeLabel.apply(style: .high)
 badgeLabel.apply(style: .medium, prefix: "온도") // 온도: 보통
 */

final class MatchStatusBadgeLabel: UILabel {
    enum Style {
        case high
        case medium
        case low

        fileprivate var textColor: UIColor {
            switch self {
            case .high:
                return UIColor(red: 0.169, green: 0.498, blue: 1, alpha: 1)
            case .medium:
                return UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 1)
            case .low:
                return UIColor(red: 0.942, green: 0.417, blue: 0.417, alpha: 1)
            }
        }

        fileprivate var backgroundColor: UIColor {
            switch self {
            case .high:
                return UIColor(red: 0.169, green: 0.498, blue: 1, alpha: 0.1)
            case .medium:
                return .grayScale50
            case .low:
                return UIColor(red: 0.941, green: 0.416, blue: 0.416, alpha: 0.1)
            }
        }

        fileprivate var descriptionText: String {
            switch self {
            case .high:
                return "높음"
            case .medium:
                return "보통"
            case .low:
                return "낮음"
            }
        }
    }

    private let horizontalPadding: CGFloat = 4
    private let verticalPadding: CGFloat = 2

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .systemFont(ofSize: 12, weight: .medium)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        numberOfLines = 1
        apply(style: .high)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func apply(style: Style, prefix: String = "일치율") {
        text = "\(prefix) : \(style.descriptionText)"
        textColor = style.textColor
        backgroundColor = style.backgroundColor
    }
    
    // 내부 패딩을 위한 override 메서드 - 안쪽으로 인셋을 확보하고 가운데에 글자가 들어갈 수 있도록 해줌
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
        super.drawText(in: rect.inset(by: insets))
    }
    
    // 패딩까지 포함한 레이아웃으로 컨텐트 크기를 잡도록 해주는 override 메서드
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + horizontalPadding * 2,
            height: size.height + verticalPadding * 2
        )
    }
}
