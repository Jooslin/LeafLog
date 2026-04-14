//
//  DropdownFilterButton.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/13/26.
//

import UIKit

/*
 생성 시
 let button = DropdownFilterButton(title: "꽃색")

 이름 변경시
 button.apply(title: "잎색")
 */

final class DropdownFilterButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        apply(title: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(title: String, isSelected: Bool = false) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: "chevron.down")
        configuration.preferredSymbolConfigurationForImage =
            UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 4
        configuration.baseForegroundColor = isSelected ? .primary700 : .grayScale500
        configuration.background.backgroundColor = isSelected ? .primary200 : .white
        configuration.background.cornerRadius = 12
        configuration.background.strokeWidth = 1
        configuration.background.strokeColor = isSelected ? .primary700 : .grayScale100
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)

        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            let baseFont = UIFont.systemFont(ofSize: 14, weight: .medium)
            outgoing.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: baseFont)
            return outgoing
        }

        self.configuration = configuration
    }
}
