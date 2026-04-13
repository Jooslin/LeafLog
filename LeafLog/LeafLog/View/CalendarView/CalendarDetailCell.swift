//
//  CalendarDetailCell.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/13/26.
//

import UIKit
import SnapKit
import Then

final class CalendarDetailCell: UICollectionViewCell {

    private let nameLabel = UILabel(text: "몬스테라", config: .body14)
    
    private let colorChip = UIView().then {
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
        $0.snp.makeConstraints {
            $0.width.height.equalTo(8)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarDetailCell {
    private func setLayout() {
        let stackView = generateStackView()
        contentView.addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }
    
    private func generateStackView() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [colorChip, nameLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }
        
        colorChip.setContentHuggingPriority(.required, for: .horizontal)
        colorChip.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return stackView
    }
}

extension CalendarDetailCell {
    func configure(_ data: CalendarView.DetailManageInfo) {
        colorChip.backgroundColor = data.badge.color
        nameLabel.text = data.name
    }
}
