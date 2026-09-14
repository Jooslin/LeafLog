//
//  CommunityCommentHeaderCell.swift
//  LeafLog
//
//  Created by Yeseul Jang on 9/14/26.
//

import SnapKit
import Then
import UIKit

final class CommunityCommentHeaderCell: UICollectionViewCell {
    static let reuseIdentifier = "CommunityCommentHeaderCell"
    
    private let dividerView = UIView().then {
        $0.backgroundColor = .grayScale100
    }
    
    private let titleLabel = UILabel(text: "댓글", config: .title14, color: .black, lines: 1)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayout() {
        contentView.addSubview(dividerView)
        contentView.addSubview(titleLabel)
        
        dividerView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(1)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(dividerView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
        }
    }
}
