//
//  SearchBottomGuideCell.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/13/26.
//

import SnapKit
import Then
import UIKit

final class SearchBottomGuideCell: UICollectionViewCell {
    static let reuseIdentifier = "SearchBottomGuideCell"
    var onRegisterOtherTap: (() -> Void)?

    private let titleLabel = UILabel(text: "찾으시는 결과가 없으신가요?", config: .title16)

    let registerOtherButton = UIButton(config: .mSize, title: "기타로 등록하기")

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        onRegisterOtherTap = nil
    }

    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(registerOtherButton)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(42)
            $0.centerX.equalToSuperview()
        }

        registerOtherButton.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(36)
        }

        registerOtherButton.addAction(
            UIAction { [weak self] _ in
                self?.onRegisterOtherTap?()
            },
            for: .touchUpInside
        )
    }
}

final class SearchEmptyResultCell: UICollectionViewCell {
    static let reuseIdentifier = "SearchEmptyResultCell"
    
    private let messageLabel = UILabel().then {
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 15, weight: .medium)
        $0.textColor = .secondaryLabel
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.horizontalEdges.equalToSuperview().inset(32)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(message: String) {
        messageLabel.text = message
    }
}
