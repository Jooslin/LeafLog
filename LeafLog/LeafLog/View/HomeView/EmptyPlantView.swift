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
    private let imageView = UIImageView(image: .plantCategoryShrub).then {
        $0.snp.makeConstraints {
            $0.width.height.equalTo(96)
        }
    }
    private let label = UILabel(text: "아직 키우는 식물이 없어요", config: .title18)
    private let subLabel = UILabel(text: "식물을 등록하고 키워보세요.", config: .body14, color: .grayScale600)
    
    let registerButton = UIButton(configuration: .filled()).then {
        $0.setTitle("첫 식물 등록")
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        
        $0.configuration?.image = .plus
        $0.configuration?.imagePadding = 8
        $0.configuration?.imagePlacement = .leading
        
        $0.configuration?.baseBackgroundColor = .primary200
        $0.configuration?.baseForegroundColor = .primary900
        $0.configuration?.background.cornerRadius = 12
        
        $0.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .grayScale50
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EmptyPlantView {
    private func setLayout() {
        let stackView = generateStackView()
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        registerButton.snp.makeConstraints {
            $0.height.equalTo(36)
        }
    }
    
    private func generateStackView() -> UIStackView {
        let labelStack = UIStackView(arrangedSubviews: [label, subLabel]).then {
            $0.axis = .vertical
            $0.spacing = 4
            $0.alignment = .center
        }
        
        let imageStack = UIStackView(arrangedSubviews: [imageView, labelStack]).then {
            $0.axis = .vertical
            $0.spacing = 12
            $0.alignment = .center
        }
        
        let stackView = UIStackView(arrangedSubviews: [imageStack, registerButton]).then {
            $0.axis = .vertical
            $0.spacing = 32
            $0.alignment = .center
        }
        
        subLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        subLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        return stackView
    }
}
