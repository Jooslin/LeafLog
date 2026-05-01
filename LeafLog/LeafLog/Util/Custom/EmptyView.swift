//
//  EmptyView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 5/1/26.
//

import UIKit
import SnapKit
import Then

class EmptyView: UIView {
    let imageView = UIImageView().then {
        $0.setContentHuggingPriority(.defaultLow, for: .vertical)
        $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }
    let label = UILabel(text: "", config: .title18).then {
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
        $0.textAlignment = .center
    }
    let subLabel = UILabel(text: "", config: .body14, color: .grayScale600).then {
        $0.textAlignment = .center
    }
    
    let button = BottomSaveButton(title: "")
    
    init(frame: CGRect = .zero, image: String, title: String, subTitle: String, needButton: Bool, buttonTitle: String? = nil) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        imageView.image = UIImage(named: image)
        label.text = title
        subLabel.text = subTitle
        
        button.isHidden = !needButton
        if needButton {
            button.setTitle(buttonTitle ?? "")
//            button.configuration?.title = buttonTitle ?? ""
        }
        
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayout() {
        let labelStack = UIStackView(arrangedSubviews: [label, subLabel]).then {
            $0.axis = .vertical
            $0.spacing = 8
        }
        
        let stackView = UIStackView(arrangedSubviews: [imageView, labelStack]).then {
            $0.axis = .vertical
            $0.spacing = 24
            $0.alignment = .center
        }
        
        addSubview(stackView)
        addSubview(button)
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(96)
        }
        
        stackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(76)
        }
        
        button.snp.makeConstraints {
            $0.height.equalTo(48)
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
        }
    }
}
