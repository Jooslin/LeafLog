//
//  PlantLabelCardView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then

final class PlantLabelCardView: BaseCardView {
    let nameLabel = UILabel(text: "", config: .label14)
    
    private let recentLabel = UILabel(text: "최근 급수", config: .body12, color: .grayScale600)
    let recentDayLabel = UILabel(text: "N일 전", config: .body12, color: .subBlue)
    private let nextLabel = UILabel(text: "다음 급수까지", config: .label12, color: .grayScale800)
    let nextDayLabel = UILabel(text: "N일", config: .label12, color: .primary700)
    
    let waterButton = CornerRadius8Button(title: "물 줬어요", backgroundColor: .lightBlue)
    
    init(image: String, text: String) {
//        super.init(cornerRadius: 12)
        super.init(frame: .zero)
        
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlantLabelCardView {

}
