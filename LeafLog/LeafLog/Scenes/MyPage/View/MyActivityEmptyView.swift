//
//  MyActivityEmptyView.swift
//  LeafLog
//
//  Created by 김주희 on 8/19/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class MyActivityEmptyView: UIView {
    private let titleLabel = UILabel(config: .title18).then {
        $0.textAlignment = .center
    }

    private let descriptionLabel = UILabel(config: .body14, color: .grayScale600).then {
        $0.textAlignment = .center
    }

    private let actionButton = UIButton(type: .system)

    var actionButtonTap: ControlEvent<Void> {
        actionButton.rx.tap
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(for tab: MyActivityTab) {
        titleLabel.text = tab.emptyTitle
        descriptionLabel.text = tab.emptyDescription
        actionButton.isUserInteractionEnabled = true

        var configuration = UIButton.Configuration.filled()
        configuration.title = tab.emptyButtonTitle
        configuration.baseForegroundColor = .primary800
        configuration.background.backgroundColor = .primary200
        configuration.background.cornerRadius = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 12,
            bottom: 8,
            trailing: 12
        )
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            return attributes
        }
        actionButton.configuration = configuration
    }

    private func setupUI() {
        let textStackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel]).then {
            $0.axis = .vertical
            $0.alignment = .center
            $0.spacing = 8
        }

        let contentStackView = UIStackView(arrangedSubviews: [textStackView, actionButton]).then {
            $0.axis = .vertical
            $0.alignment = .center
            $0.spacing = 24
        }

        addSubview(contentStackView)

        contentStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(76)
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.greaterThanOrEqualToSuperview().inset(40)
        }

        actionButton.snp.makeConstraints {
            $0.height.equalTo(38)
        }
    }
}
