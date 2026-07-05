//
//  LabelConfiguration.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/10/26.
//
import UIKit

struct LabelConfiguration {
    let font: UIFont
    let textStyle: UIFont.TextStyle
    let color: UIColor
    let lines: Int
}

/*
 현재는 정해진 폰트 굵기와 크기 외에 변경은 막아두지 않았습니다.
 
 생성으로 사용시
 let titleLabel = UILabel(text: "제목", config: .headline24)
 let bodyLabel = UILabel(text: "본문", config: .body16)

 이미 있는 label 적용
 label.apply(.body16)
 label.apply(.body16, color: .secondaryLabel)
 label.apply(.body16, lines: 0)
 label.apply(.body16, color: .systemRed, lines: 2)
 */

extension LabelConfiguration {
    private static func make(
        size: CGFloat,
        weight: UIFont.Weight,
        textStyle: UIFont.TextStyle,
        color: UIColor = .label,
        lines: Int = 0
    ) -> LabelConfiguration {
        LabelConfiguration(
            font: .systemFont(ofSize: size, weight: weight),
            textStyle: textStyle,
            color: color,
            lines: lines
        )
    }

    static let headline24 = make(size: 24, weight: .bold, textStyle: .largeTitle)
    static let headline20 = make(size: 20, weight: .bold, textStyle: .title1)
    static let headline18 = make(size: 18, weight: .bold, textStyle: .title2)
    static let headline16 = make(size: 16, weight: .bold, textStyle: .title3)

    static let body18 = make(size: 18, weight: .regular, textStyle: .body)
    static let body16 = make(size: 16, weight: .regular, textStyle: .body)
    static let body14 = make(size: 14, weight: .regular, textStyle: .body)
    static let body12 = make(size: 12, weight: .regular, textStyle: .footnote)

    static let title20 = make(size: 20, weight: .semibold, textStyle: .title2)
    static let title18 = make(size: 18, weight: .semibold, textStyle: .title3)
    static let title16 = make(size: 16, weight: .semibold, textStyle: .headline)
    static let title14 = make(size: 14, weight: .semibold, textStyle: .subheadline)

    static let label16 = make(size: 16, weight: .medium, textStyle: .headline)
    static let label14 = make(size: 14, weight: .medium, textStyle: .subheadline)
    static let label12 = make(size: 12, weight: .medium, textStyle: .footnote)
}
