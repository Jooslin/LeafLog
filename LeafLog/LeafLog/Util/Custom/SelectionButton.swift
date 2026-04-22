//
//  SelectionButton.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/15/26.
//

import UIKit
/*
 생성 시
 let button = SelectionButton(title: "물주기")

 이름 변경시
 button.apply(title: "비료")

 isSelected가 true일 경우 연두색으로 표시됩니다.
 */

final class SelectionButton: UIButton {

    init(title: String) {
        super.init(frame: .zero)
        setup(title: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 32
        return size
    }

    func setup(title: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = .grayScale500
        configuration.background.backgroundColor = .white
        configuration.background.cornerRadius = 12
        configuration.background.strokeWidth = 1
        configuration.background.strokeColor = .grayScale100
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)

        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            let baseFont = UIFont.systemFont(ofSize: 14, weight: .medium)
            outgoing.font = UIFontMetrics(forTextStyle: .body)
                .scaledFont(for: baseFont)
            return outgoing
        }

        self.configuration = configuration
        self.titleLabel?.adjustsFontForContentSizeCategory = true

        //상태 자동 반영
        self.configurationUpdateHandler = { button in
            guard var config = button.configuration else { return }

            if button.isSelected {
                config.baseForegroundColor = .primary700
                config.background.backgroundColor = .primary100
                config.background.strokeColor = .primary400
            } else {
                config.baseForegroundColor = .grayScale500
                config.background.backgroundColor = .white
                config.background.strokeColor = .grayScale100
            }

            button.configuration = config
        }
    }
}
