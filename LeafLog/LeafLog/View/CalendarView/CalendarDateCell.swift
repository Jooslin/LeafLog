//
//  CalendarDateCell.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/12/26.
//

import UIKit
import SnapKit
import Then

final class CalendarDateCell: UICollectionViewCell {
    private let selectedView = BaseCardView(cornerRadius: 12).then {
        $0.backgroundColor = .white
        $0.layer.borderWidth = 0.5
        $0.layer.borderColor = UIColor.primary500.cgColor
        $0.isHidden = true
    }
    
    private let dateLabel = UILabel(text: "0", config: .label16).then {
        $0.textAlignment = .center
    }
    
    private let badges = [
        UIImageView(image: nil),
        UIImageView(image: nil),
        UIImageView(image: nil),
        UIImageView(image: nil)
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 이미지 초기화
        badges.forEach {
            $0.image = nil
        }
        
        dateLabel.textColor = .label
    }
    
    override var isSelected: Bool {
        didSet {
            selectedView.isHidden = !isSelected
        }
    }
}

extension CalendarDateCell {
    private func setLayout() {
        let badgeStack = generateBadgeStack()
        
        contentView.addSubview(selectedView)
        contentView.addSubview(dateLabel)
        contentView.addSubview(badgeStack)
        
        selectedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(22)
        }
        
        badgeStack.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom)
            $0.horizontalEdges.equalToSuperview().inset(3)
        }
        
        // badge 크기 비율 1:1
        badges.forEach { badge in
            badge.snp.makeConstraints {
                $0.height.equalTo(badge.snp.width)
            }
        }
    }
    
    private func generateBadgeStack() -> UIStackView {
        let horizontal1 = UIStackView(arrangedSubviews: [badges[0], badges[1]]).then {
            $0.axis = .horizontal
            $0.spacing = 4
            $0.distribution = .fillEqually
        }
        let horizontal2 = UIStackView(arrangedSubviews: [badges[2], badges[3]]).then {
            $0.axis = .horizontal
            $0.spacing = 4
            $0.distribution = .fillEqually
        }

        let stackView = UIStackView(arrangedSubviews: [horizontal1, horizontal2]).then {
            $0.axis = .vertical
            $0.spacing = 4
            $0.distribution = .fillEqually
        }
        
        return stackView
    }
}

extension CalendarDateCell {
    func configure(_ data: CalendarView.ManageInfoByDate) {
        dateLabel.text = "\(data.day)"
        dateLabel.textColor =
        data.isCurrentMonth ? dateLabel.textColor
        : UIColor(red: 0.76, green: 0.78, blue: 0.73, alpha: 1.00) // HEX #C3C8BB
        
        data.badge.prefix(badges.count).enumerated().forEach {
            badges[$0.offset].image = UIImage(named: $0.element.smallImage)
        }
    }
}
