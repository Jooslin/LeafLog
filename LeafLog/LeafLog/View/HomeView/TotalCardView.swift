//
//  TotalCardView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then

final class TotalCardView: BaseCardView {    
    private let imageView = UIImageView().then {
        $0.snp.makeConstraints {
            $0.width.height.equalTo(32)
        }
    }
    let label = UILabel(text: "", config: .label14)
    
    init(image: String, text: String) {
        super.init(cornerRadius: 12)
        
        backgroundColor = .white
        
        imageView.image = UIImage(named: image)
        label.text = text
        
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TotalCardView {
    private func setLayout() {
        let stackView = UIStackView(arrangedSubviews: [imageView, label]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            imageView.setContentHuggingPriority(.required, for: .horizontal)
            imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(8)
            $0.centerX.equalToSuperview()
        }
    }
}
