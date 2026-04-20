//
//  BigSaveButton.swift
//  LeafLog
//
//  Created by 김주희 on 4/15/26.
//

import UIKit

final class BottomSaveButton: UIButton {
    
    // isEnabled 상태가 변경될 때마다 배경색 업데이트
    override var isEnabled: Bool {
        didSet {
            updateBackgroundColor()
        }
    }
    
    // 타이틀 주입 초기화
    init(title: String) {
        super.init(frame: .zero)
        setupUI(title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(title: String) {
        // 공통 UI 설정
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        layer.cornerRadius = 12
        
        // 상태별 텍스트 색상 지정
        setTitleColor(.white, for: .normal)
        setTitleColor(.grayScale400, for: .disabled)
        
        // 초기 배경색 셋팅
        updateBackgroundColor()
    }
    
    // 상태에 따른 배경색 변경 로직
    private func updateBackgroundColor() {
        backgroundColor = isEnabled ? .primary600 : .grayScale200
    }
}
