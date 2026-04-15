//
//  SelectionButton.swift
//  LeafLog
//
//  Created by Codex on 4/15/26.
//

import UIKit

/*
 생성 시
 let button = SelectionButton(title: "물주기")

 이름 변경시
 button.apply(title: "비료")

 선택 상태 색상 변경 시
 applySelectionStyle(isSelected:)
 isSelected가 true일 경우 연두색으로 표시됩니다.
 */

final class SelectionButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        apply(title: title)
        applySelectionStyle(isSelected: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(title: String) {
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
            outgoing.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: baseFont)
            return outgoing
        }

        self.configuration = configuration
    }

    func applySelectionStyle(isSelected: Bool) {
        guard var configuration = self.configuration else { return }

        configuration.baseForegroundColor = isSelected ? .primary700 : .grayScale500
        configuration.background.backgroundColor = isSelected ? .primary200 : .white
        configuration.background.strokeColor = isSelected ? .primary700 : .grayScale100

        self.configuration = configuration
    }
}
