//
//  UIButton+.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/15/26.
//
import UIKit
/*
 디자인 가이드 시스템을 기반으로 만들었습니다.
 AppButtonStyle에서 색, 패딩 적용을 확인 할 수 있습니다.
 
 사용 법입니다.
 
 생성시
 let smallButton = UIButton(config: .Ssize, title: "추가")
 
 이름만 변경 원할 때
 actionButton.setTitle("선택 완료")
 
 isSelected의 상태를 기반으로 버튼의 색이 변경됩니다.

 */


extension UIButton {

    convenience init(
        config style: AppButtonStyle,
        title: String,
        textStyle: UIFont.TextStyle = .subheadline
    ) {
        self.init(type: .system)

        var configuration = UIButton.Configuration.plain()
        configuration.title = title

        // 스타일에서 padding 가져오기
        configuration.contentInsets = style.contentInsets

        configuration.baseForegroundColor = style.normalTextColor
        configuration.background.backgroundColor = style.normalBackgroundColor
        
        configuration.background.cornerRadius = 8

        // 다이나믹 폰트
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming

            let baseFont = UIFont.systemFont(ofSize: 14, weight: .medium)
            outgoing.font = UIFontMetrics(forTextStyle: textStyle)
                .scaledFont(for: baseFont)

            return outgoing
        }

        self.configuration = configuration
        self.titleLabel?.adjustsFontForContentSizeCategory = true

        // 상태 변화
        self.configurationUpdateHandler = { button in
            guard var config = button.configuration else { return }

            if button.isSelected {
                config.baseForegroundColor = style.selectedTextColor
                config.background.backgroundColor = style.selectedBackgroundColor
            } else {
                config.baseForegroundColor = style.normalTextColor
                config.background.backgroundColor = style.normalBackgroundColor
            }

            button.configuration = config
        }
    }
}

// 제목 변경만 원할시
extension UIButton {

    func setTitle(_ title: String) {
        guard var config = self.configuration else { return }
        config.title = title
        self.configuration = config
    }
}
