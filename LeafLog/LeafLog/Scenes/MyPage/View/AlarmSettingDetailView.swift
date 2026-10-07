//
//  AlarmSettingDetailView.swift
//  LeafLog
//
//  Created by 변예린 on 10/7/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then

final class AlarmSettingDetailView: UIView {
    
}

final class AlarmSettingCell: UICollectionViewCell {
    private let titleLabel = UILabel(text: "", config: .label16, color: .black)
    private let bar = UIView().then {
        $0.backgroundColor = .grayScale100
    }
    fileprivate let alarmSwitch = UISwitch().then {
        $0.onTintColor = .primary600
        $0.isOn = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, alarmSwitch]).then {
            $0.axis = .horizontal
            alarmSwitch.setContentHuggingPriority(.required, for: .horizontal)
            alarmSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        addSubview(stackView)
        addSubview(bar)
        
        stackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview()
        }
        
        bar.snp.makeConstraints {
            $0.height.equalTo(0.5)
            $0.bottom.horizontalEdges.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(item: AlarmSettingDetailView.Item) {
        titleLabel.text = item.title
        alarmSwitch.isOn = item.isOn
    }
}
