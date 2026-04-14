//
//  EmptyPlantView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then

final class EmptyPlantView: UIView {
    private let imageView = UIImageView()
    private let label = UILabel(text: "아직 키우는 식물이 없어요", config: .title18)
    private let subLabel = UILabel(text: "식물을 등록하고 키워보세요.", config: .body14, color: .grayScale600)
    let registerButton = UIButton(configuration: .plain())
}
