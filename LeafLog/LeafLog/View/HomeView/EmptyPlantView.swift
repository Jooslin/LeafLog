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
    let registerButton = CornerRadius8Button(title: "식물 등록하기", backgroundColor: .lightGreen).then {
        $0.setImage(.plus, for: .normal)
        $0.configuration?.background.cornerRadius = 12
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
    }
    
    private func generateStackView() -> UIStackView {
        let labelStack = UIStackView(arrangedSubviews: [label, subLabel]).then {
            $0.axis = .vertical
            $0.spacing = 8
            $0.alignment = .center
        }
        
        let stackView = UIStackView(arrangedSubviews: [imageView, labelStack, registerButton]).then {
            $0.axis = .vertical
            $0.spacing = 32
            $0.alignment = .center
        }
        
        subLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        subLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        return stackView
    }
}
