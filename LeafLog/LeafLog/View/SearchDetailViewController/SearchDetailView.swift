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
    private let familyNameLabel = UILabel(config: .body14, color: .grayScale600 )
    private let originLabel = UILabel(config: .body14, color: .grayScale600 )

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
    
    let sectionStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 24
    }

    let environmentSection = DetailInfoSectionView(
        title: "생육 환경",
        rows: [
            DetailInfoRowView(title: "광도 요구", value: "낮은 광도 (300~800 LUX)"),
            DetailInfoRowView(title: "겨울 최저온도", value: "7°C")
        ]
    )
    
    let appearanceSection = DetailInfoSectionView(
        title: "외형 특징",
        rows: [
            DetailInfoRowView(title: "생육 형태", value: "직립형"),
            DetailInfoRowView(title: "잎색", value: "녹색 연두색"),
            DetailInfoRowView(title: "잎무늬", value: "무늬 없음")
            
        ]
    )
    
    let wateringSection = DetailInfoSectionView(
        title: "물주기",
        rows: [
            DetailInfoRowView(title: "봄", value: "4~6일"),
            DetailInfoRowView(title: "여름", value: "4~6일"),
            DetailInfoRowView(title: "가을", value: "4~6일"),
            DetailInfoRowView(title: "겨울", value: "4~6일")
            
        ]
    )
    
    let flowerAndFruitSection = DetailInfoSectionView(
        title: "물주기",
        rows: [
            DetailInfoRowView(title: "꽃색", value: "분홍색"),
            DetailInfoRowView(title: "꽃피는 계절", value: "여름"),
            DetailInfoRowView(title: "열매색", value: "빨간색"),
            DetailInfoRowView(title: "열매 계절", value: "여름")
            
        ]
    )
    
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
        familyNameLabel.text = "과명입니다."
        originLabel.text = "원산지 정보"
    }

    private func setupLayout() {
        addSubview(scrollView)
        addSubview(buttonStack)

        scrollView.addSubview(contentView)

        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(familyNameLabel)
        contentView.addSubview(originLabel)
        contentView.addSubview(sectionStackView)
        
        sectionStackView.addArrangedSubview(environmentSection)
        sectionStackView.addArrangedSubview(appearanceSection)
        sectionStackView.addArrangedSubview(wateringSection)
        sectionStackView.addArrangedSubview(flowerAndFruitSection)

        buttonStack.addArrangedSubview(closeButton)
        buttonStack.addArrangedSubview(selectButton)

        // 버튼 고정으로
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            $0.bottom.equalTo(buttonStack.snp.top)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
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
        
        familyNameLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        originLabel.snp.makeConstraints {
            $0.top.equalTo(familyNameLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        sectionStackView.snp.makeConstraints {
            $0.top.equalTo(originLabel.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(24)
        }
        
        // 버튼
        buttonStack.snp.makeConstraints {
            $0.leading.trailing.bottom.equalTo(safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(50)
        }
    }
}

// 한줄 세부사항
final class DetailInfoRowView: UIView {

    private let titleLabel = UILabel(config: .label14, color: .black)

    private let valueLabel = UILabel(config: .label14, color: .grayScale600)

    init(title: String, value: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        valueLabel.text = value
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(titleLabel)
        addSubview(valueLabel)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(5)
        }

        valueLabel.snp.makeConstraints {
                $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(5)
                $0.trailing.equalToSuperview()
                $0.centerY.equalTo(titleLabel)
            }
    }
}

// 섹션
final class DetailInfoSectionView: UIView {

    private let titleLabel = UILabel(config: .title14, color: .black)

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.backgroundColor = .primary50
        
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }

    init(title: String, rows: [DetailInfoRowView]) {
        super.init(frame: .zero)
        titleLabel.text = title

        setupLayout()

        rows.forEach {
            stackView.addArrangedSubview($0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(titleLabel)
        addSubview(stackView)

        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        stackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}
