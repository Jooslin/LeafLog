//
//  SearchBottomGuideView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/13/26.
//

import SnapKit
import Then
import UIKit

final class SearchBottomGuideView: UICollectionReusableView {
    static let reuseIdentifier = "SearchBottomGuideView"

    private let titleLabel = UILabel(text: "찾으시는 결과가 없으신가요?", config: .title16)

    let actionButton = CornerRadius14Button(title: "기타로 등록하기", backgroundColor: .gray)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(actionButton)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.centerX.equalToSuperview()
        }

        actionButton.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(36)
        }
    }
}
