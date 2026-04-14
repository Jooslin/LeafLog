//
//  CornerRadius8Button.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/13/26.
//

import UIKit

/*
 생성 시 (색 설정 안하면 자동으로 회색 적용됩니다.)
 let button = CornerRadius8Button(title: "선택")
 let button = CornerRadius8Button(title: "선택", backgroundColor: .lightGreen)
 
 이름 변경시
 button.apply(title: "완료")
 */

class CornerRadius8Button: UIButton {
    enum BackgroundColor {
        case gray
        case lightGreen
        case lightBlue

        fileprivate var color: UIColor {
            switch self {
            case .gray:
                return .grayScale50
            case .lightGreen:
                return .primary200
            case .lightBlue:
                return .subBlue.withAlphaComponent(0.1)
            }
        }
    }

    init(title: String, backgroundColor: BackgroundColor = .gray) {
        super.init(frame: .zero)
        apply(title: title, backgroundColor: backgroundColor)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(title: String, backgroundColor: BackgroundColor = .gray) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = UIColor.darkGray
        configuration.background.backgroundColor = backgroundColor.color
        configuration.background.cornerRadius = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        
        // 다이나믹 폰트 설정
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            let baseFont = UIFont.systemFont(ofSize: 14, weight: .medium)
            outgoing.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: baseFont)
            return outgoing
        }
        self.configuration = configuration
    }
}
