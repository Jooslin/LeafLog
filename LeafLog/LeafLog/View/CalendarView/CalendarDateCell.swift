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
    
    //TODO: LabelConfiguration 적용 시 주석 해제
//    private let dateLabel = UILabel(text: "0", config: .label16)
    private let dateLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.text = "0"
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
}

extension CalendarDateCell {
    private func setLayout() {
        let badgeStack = generateBadgeStack()
        
        contentView.addSubview(dateLabel)
        contentView.addSubview(badgeStack)
        
        dateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(22)
        }
        
        badgeStack.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom)
            $0.horizontalEdges.equalToSuperview().inset(3)
//            $0.bottom.equalToSuperview().inset(8)
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
        data.badge.enumerated().forEach {
            badges[$0.offset].image = UIImage(named: $0.element.rawValue)
        }
    }
}
