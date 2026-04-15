//
//  AppButtonStyle.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/15/26.
//
import UIKit
/*
 디자인 가이드 시스템을 기반으로 만들었습니다.
 UIButton+에서 구현을 확인 할 수 있습니다.
 
 사용 법입니다.
 
 생성시
 let smallButton = UIButton(config: .sSize, title: "추가")
 
 이름만 변경 원할 때
 actionButton.setTitle("선택 완료")
 
 isSelected의 상태를 기반으로 버튼의 색이 변경됩니다.

 */


enum AppButtonStyle {
    case sSize
    case mSize
    case LSize

    var normalTextColor: UIColor {
        switch self {
        case .sSize: return .grayScale700
        case .mSize: return .grayScale700
        case .LSize: return .grayScale600
        }
    }

    var normalBackgroundColor: UIColor {
        switch self {
        case .sSize: return .white
        case .mSize: return .grayScale50
        case .LSize: return .grayScale50
        }
    }

    var selectedTextColor: UIColor {
        switch self {
        case .sSize: return .grayScale400
        case .mSize: return .primary800
        case .LSize: return .primary800
        }
    }

    var selectedBackgroundColor: UIColor {
        switch self {
        case .sSize: return .grayScale100
        case .mSize: return .primary200
        case .LSize: return .primary200
        }
    }

    // padding도 고정
    var contentInsets: NSDirectionalEdgeInsets {
        switch self {
        case .sSize:
            return .init(top: 4, leading: 12, bottom: 4, trailing: 12)

        case .mSize:
            return .init(top: 6, leading: 12, bottom: 6, trailing: 12)
            
        case .LSize:
            return .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        }
    }
}
