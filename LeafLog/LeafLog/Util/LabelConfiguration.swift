//
//  LabelConfiguration.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/10/26.
//
import UIKit

struct LabelConfiguration {
    let font: UIFont
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
        color: UIColor = .label,
        lines: Int = 1
    ) -> LabelConfiguration {
        LabelConfiguration(
            font: .systemFont(ofSize: size, weight: weight),
            color: color,
            lines: lines
        )
    }

    static let headline24 = make(size: 24, weight: .bold)
    static let headline20 = make(size: 20, weight: .bold)
    static let headline18 = make(size: 18, weight: .bold)
    static let headline16 = make(size: 16, weight: .bold)

    static let body18 = make(size: 18, weight: .regular)
    static let body16 = make(size: 16, weight: .regular)
    static let body14 = make(size: 14, weight: .regular)
    static let body12 = make(size: 12, weight: .regular)

    static let title20 = make(size: 20, weight: .semibold)
    static let title18 = make(size: 18, weight: .semibold)
    static let title16 = make(size: 16, weight: .semibold)
    static let title14 = make(size: 14, weight: .semibold)

    static let label16 = make(size: 16, weight: .medium)
    static let label14 = make(size: 14, weight: .medium)
    static let label12 = make(size: 12, weight: .medium)
}
