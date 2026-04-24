//
//  NotificationEmptyView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/23/26.
//

import UIKit
import SnapKit
import Then

final class NotificationEmptyView: UIView {
    private let label = UILabel(text: "받은 알림이 없어요.", config: .title18)
  
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NotificationEmptyView {
    private func setLayout() {
        addSubview(label)
        
        label.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
