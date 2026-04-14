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
    //TODO: 병합 후 수정 필요
    //    private let cardView = BaseCardView(cornerRadius: 12).then {
//    $0.backgroundColor = .white
//}
    
    private let imageView = UIImageView()
    let label = UILabel(text: "", config: .label14)
    
    init(image: String, text: String) {
//        super.init(cornerRadius: 12)
        super.init(frame: .zero)
        
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
        addSubview(imageView)
        addSubview(label)
        
        imageView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(8)
            $0.leading.equalToSuperview().inset(12)
        }
        
        label.snp.makeConstraints {
            $0.leading.equalTo(imageView.snp.trailing).offset(8)
            $0.verticalEdges.equalToSuperview().inset(14)
        }
    }
}
