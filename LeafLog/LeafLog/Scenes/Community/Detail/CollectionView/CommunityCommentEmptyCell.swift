//
//  CommunityCommentEmptyCell.swift
//  LeafLog
//
//  Created by Yeseul Jang on 9/14/26.
//

import SnapKit
import Then
import UIKit

final class CommunityCommentEmptyCell: UICollectionViewCell {
    static let reuseIdentifier = "CommunityCommentEmptyCell"
    
    private let messageLabel = UILabel(
        text: "작성된 댓글이 없습니다.\n첫번째 댓글을 달아보세요!",
        config: .body14,
        color: .grayScale500,
        lines: 0
    ).then {
        $0.textAlignment = .center
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayout() {
        contentView.addSubview(messageLabel)
        
        messageLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(48)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(48)
        }
    }
}
