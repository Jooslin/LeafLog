//
//  TitleHeaderView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/13/26.
//

import UIKit
import SnapKit
import Then

class TitleHeaderView: UIView {
    //TODO: LabelConfiguration 적용 시 주석 해제
//    private let titleLabel = UILabel(text: "", config: .title18)
    
    private let titleLabel = UILabel().then {
        $0.text = ""
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textAlignment = .center
    }
    
    let backButton = UIButton(configuration: .plain()).then {
        $0.setImage(.arrowLeft, for: .normal)
    }
    
    let rightButton = UIButton(configuration: .plain())
    
    init(text: String, hasBackButton: Bool, rightButtonImage: String? = nil) {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TitleHeaderView {
    private func configure(text: String, hasBackButton: Bool, rightButtonImage: String? = nil) {
        titleLabel.text = text
        backButton.isHidden = !hasBackButton
        
        guard let imageName = rightButtonImage else {
            rightButton.isHidden = true
            return
        }
        
        rightButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    private func setLayout() {
        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(rightButton)
        
        backButton.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.leading.equalToSuperview().inset(16)
        }
        
        titleLabel.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(11)
            $0.horizontalEdges.equalToSuperview().inset(40)
        }
        
        rightButton.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.trailing.equalToSuperview().inset(16)
        }
    }
}
