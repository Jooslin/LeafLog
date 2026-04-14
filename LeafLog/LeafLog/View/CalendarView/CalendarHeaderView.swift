//
//  CalendarHeaderView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then

final class CalendarHeaderView: UIView {
    let previousButton = UIButton(configuration: .plain())
    let nextButton = UIButton(configuration: .plain())
    let dateLabel = UILabel(text: "2026년 4월", config: .label16)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setButtonAttributes()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarHeaderView {
    private func setButtonAttributes() {
        previousButton.setImage(.arrowLeft, for: .normal)
        nextButton.setImage(.arrowRight, for: .normal)
        
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .black
        
        previousButton.configuration = config
        nextButton.configuration = config
    }
    
    private func setLayout() {
        let stackView = generateStackView()
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.centerX.equalToSuperview()
        }
    }
    
    private func generateStackView() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [previousButton, dateLabel, nextButton]).then {
            $0.axis = .horizontal
            $0.spacing = 32
        }
        
        previousButton.setContentHuggingPriority(.required, for: .horizontal)
        previousButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        nextButton.setContentHuggingPriority(.required, for: .horizontal)
        nextButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return stackView
    }
}
