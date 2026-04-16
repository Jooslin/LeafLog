//
//  SearchDetailView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/16/26.
//
import SnapKit
import Then
import UIKit

final class SearchDetailView: UIView {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    
    private let nameLabel = UILabel(config: .headline24)

    private let buttonStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.distribution = .fillEqually
    }

    private let closeButton = UIButton().then {
        $0.setTitle("닫기", for: .normal)
        $0.backgroundColor = .grayScale50
        $0.setTitleColor(.grayScale400, for: .normal)
        $0.layer.cornerRadius = 12
    }

    private let selectButton = UIButton().then {
        $0.setTitle("선택하기", for: .normal)
        $0.backgroundColor = .primary600
        $0.layer.cornerRadius = 12
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupLayout()
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        imageView.image = UIImage(resource: .badgeBugBig)
        nameLabel.text = "테스트입니다."
    }

    private func setupLayout() {
        addSubview(scrollView)
        addSubview(buttonStack)

        scrollView.addSubview(contentView)

        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)

        buttonStack.addArrangedSubview(closeButton)
        buttonStack.addArrangedSubview(selectButton)

        // 버튼 고정으로
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(buttonStack.snp.top)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // 이미지
        imageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(350)
        }

        // 이름
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        // 버튼
        buttonStack.snp.makeConstraints {
            $0.leading.trailing.bottom.equalTo(safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(50)
        }
    }
}
