//
//  MemberProfileEmptyCell.swift
//  LeafLog
//
//  Created by Yeseul Jang on 8/5/26.
//

import SnapKit
import Then
import UIKit

final class MemberProfileEmptyCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: MemberProfileEmptyCell.self)
    
    private let emptyLabel = UILabel(
        text: "활동 내역이 없어요",
        config: .body14,
        color: .grayScale500,
        lines: 1
    ).then {
        $0.textAlignment = .center
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(46)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
