//
//  CommunityPostContentCell.swift
//  LeafLog
//
//  Created by Yeseul Jang on 9/14/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class CommunityPostContentCell: UICollectionViewCell {
    static let reuseIdentifier = "CommunityPostContentCell"
    var disposeBag = DisposeBag()
    
    fileprivate let postContentView = CommunityPostContentView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
    
    func configure(post: CommunityDetailReactor.Post) {
        postContentView.configure(post: post)
    }
    
    private func setLayout() {
        contentView.addSubview(postContentView)
        
        postContentView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(28)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(24)
        }
    }
}

extension Reactive where Base: CommunityPostContentCell {
    var postImageTap: ControlEvent<Int> {
        base.postContentView.rx.postImageTap
    }
    
    var profileImageTap: ControlEvent<Void> {
        base.postContentView.rx.profileImageTap
    }
    
    var heartButtonTap: ControlEvent<Void> {
        base.postContentView.rx.heartButtonTap
    }
    
    var commentButtonTap: ControlEvent<Void> {
        base.postContentView.rx.commentButtonTap
    }
}
