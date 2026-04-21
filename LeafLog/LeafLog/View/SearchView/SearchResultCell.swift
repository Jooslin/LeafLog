//
//  SearchResultCell.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/13/26.
//

import Kingfisher
import SnapKit
import Then
import UIKit

final class SearchResultCell: UICollectionViewCell {
    static let reuseIdentifier = "SearchResultCell"
    private static let lineWidth = 1 / UIScreen.main.scale

    private let cardView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.masksToBounds = true
    }
    
    // 이미지가 없을 경우, 로딩 시 사용
    private let thumbnailContainerView = UIView().then {
        $0.backgroundColor = .grayScale100
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
    }

    private let thumbnailImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.tintColor = .systemGray3
    }

    private let infoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = 4
    }

    private let statusLabel = MatchStatusBadgeLabel().then {
        $0.apply(style: .high)
    }
    
    private let plantNameLabel = UILabel(text: "식물 이름", config: .title16)

    private let selectButton = UIButton(config: .mSize, title: "선택")
    var onSelectButtonTap: (() -> Void)?

    private let dividerView = UIView().then {
        $0.backgroundColor = UIColor.separator.withAlphaComponent(0.1)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    } 

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.kf.cancelDownloadTask()
        thumbnailImageView.image = nil
        statusLabel.isHidden = false
        statusLabel.apply(style: .high)
        plantNameLabel.text = nil
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(thumbnailContainerView)
        thumbnailContainerView.addSubview(thumbnailImageView)
        cardView.addSubview(infoStackView)
        cardView.addSubview(selectButton)
        contentView.addSubview(dividerView)

        infoStackView.addArrangedSubview(statusLabel)
        infoStackView.addArrangedSubview(plantNameLabel)

        cardView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(dividerView.snp.top)
        }

        thumbnailContainerView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(72)
        }

        thumbnailImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        infoStackView.snp.makeConstraints {
            $0.leading.equalTo(thumbnailContainerView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(selectButton.snp.leading).offset(-12)
        }

        selectButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(36)
        }

        dividerView.snp.makeConstraints {
            $0.leading.equalTo(thumbnailContainerView)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(Self.lineWidth)
        }

        selectButton.addAction(
            UIAction { [weak self] _ in
                self?.onSelectButtonTap?()
            },
            for: .touchUpInside
        )
    }
}

extension SearchResultCell {
    func configure(
        plantName: String,
        confidence: PlantClassificationService.Confidence,
        thumbnailURLString: String? = nil
    ) {
        plantNameLabel.text = plantName
        statusLabel.isHidden = confidence == .unknown ? true : false

        let statusStyle: MatchStatusBadgeLabel.Style =
        switch confidence {
        case .high: .high
        case .normal: .medium
        case .low: .low
        case .unknown: .unknown
        }
        
        let statusPrefix = statusStyle == .unknown ? "검색결과": "일치율"
        
        statusLabel.apply(style: statusStyle, prefix: statusPrefix)

        let placeholderImage = UIImage(systemName: "photo")
        guard let thumbnailURLString,
              let url = URL(string: thumbnailURLString) else {
            thumbnailImageView.image = placeholderImage
            return
        }

        thumbnailImageView.kf.setImage(
            with: url,
            placeholder: placeholderImage
        )
    }
}
