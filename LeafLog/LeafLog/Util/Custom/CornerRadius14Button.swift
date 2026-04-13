//
//  CornerRadius14Button.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/13/26.
//

import UIKit

/*
 생성 시
 let button = CornerRadius14Button(title: "선택")
 
 이름 변경시
 button.apply(title: "완료")
 */

class CornerRadius14Button: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        apply(title: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(title: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        // TODO: 색 확정시 수정 요망
        configuration.baseForegroundColor = UIColor.darkGray
        configuration.background.backgroundColor = UIColor(red: 0.908, green: 0.955, blue: 0.745, alpha: 1)
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
        titleLabel?.adjustsFontForContentSizeCategory = true
    }
}

