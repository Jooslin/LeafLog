//
//  SearchInfoView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/15/26.
//

import SnapKit
import Then
import UIKit

// TODO: 생육형태 첫째줄 레이아웃 깨지는 문제, 스트롤 뷰 컨텐츠 만큼 차지하도록 리팩토링
final class SearchInfoView: UIView {
    let closeButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(resource: .x)
        configuration.baseForegroundColor = .grayScale500
        $0.configuration = configuration
    }

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 24
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .grayScale50
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(closeButton)
        addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        closeButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(12)
            $0.trailing.equalToSuperview().inset(12)
            $0.size.equalTo(24)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(8)
            $0.horizontalEdges.bottom.equalToSuperview()
        }

        contentStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16))
            $0.width.equalTo(scrollView.frameLayoutGuide).offset(-32)
        }
        
        configureSections()
    }
    
    private func configureSections() {
        let growthSection = SearchInfoSectionView(
            title: "생육 형태",
            description: "식물이 자라는 형태를 나타냅니다.",
            contentView: SearchInfoCardView(
                arrangedSubviews: [
                    SearchInfoImageRowView(image: "plantCategoryUpright", title: "직립형", description: "위로 쭉 자라요"),
                    SearchInfoImageRowView(image: "plantCategoryShrub", title: "관목형", description: "풍성하게 퍼져요"),
                    SearchInfoImageRowView(image: "plantCategoryVine", title: "덩굴성", description: "길게 늘어져요"),
                    SearchInfoImageRowView(image: "plantCategoryGrass", title: "풀모양", description: "가늘게 자라요"),
                    SearchInfoImageRowView(image: "plantCategoryRossette", title: "로제트형", description: "납작하고 동그랗게 퍼져요"),
                    SearchInfoImageRowView(image: "plantCategorySucculent", title: "다육형", description: "통통하게 자라요")
                ]
            )
        )

        let lightSection = SearchInfoSectionView(
            title: "광도 요구",
            description: "해당 식물이 빛이 얼마나 필요한지 나타냅니다.",
            contentView: SearchInfoCardView(
                arrangedSubviews: [
                    SearchInfoTextBlockView(
                        title: "낮은 광도 (300~800 Lux)",
                        description: "형광등이 있는 어두운 실내"
                    ),
                    SearchInfoTextBlockView(
                        title: "중간 광도 (800~1,500 Lux)",
                        description: "밝은 실내, 창문 근처 (직사광선X)"
                    ),
                    SearchInfoTextBlockView(
                        title: "높은 광도 (1,500~10,000 Lux)",
                        description: "창가의 직광, 베란다"
                    ),
                    SearchInfoTextBlockView(
                        title: "* 참고",
                        description: "평균적으로 집 안의 대부분은 500~1000 Lux의 환경입니다."
                    )
                ]
            )
        )
        
        contentStackView.addArrangedSubview(growthSection)
        contentStackView.addArrangedSubview(lightSection)
    }
}

// 한 정보 섹션
private final class SearchInfoSectionView: UIView {
    private let titleLabel = UILabel().then {
        $0.apply(.title14, color: .label)
    }

    private let descriptionLabel = UILabel().then {
        $0.apply(.body12, color: .grayScale700)
    }

    init(title: String, description: String, contentView: UIView) {
        super.init(frame: .zero)
        titleLabel.text = title
        descriptionLabel.text = description // 설명
        setupUI(contentView: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(contentView: UIView) {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, contentView]).then {
            $0.axis = .vertical
            $0.spacing = 4
            $0.alignment = .fill
        }

        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

// 설명쓰인 카드 뷰
private final class SearchInfoCardView: UIView {
    init(arrangedSubviews: [UIView]) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 12

        let stackView = UIStackView(arrangedSubviews: arrangedSubviews).then {
            $0.axis = .vertical
            $0.spacing = 14
            $0.alignment = .fill
        }

        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 화분 이미지가 있는 뷰 설명 한 줄
private final class SearchInfoImageRowView: UIView {
    let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .clear
        $0.clipsToBounds = true
    }

    private let titleLabel = UILabel().then {
        $0.apply(.label12, color: .black, lines: 1)
    }

    private let descriptionLabel = UILabel().then {
        $0.apply(.body12, color: .grayScale700, lines: 1)
    }

    init(image: String, title: String, description: String) {
        super.init(frame: .zero)
        iconImageView.image = UIImage(named: image)
        titleLabel.text = title
        descriptionLabel.text = description
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)

        iconImageView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(4)
            $0.centerY.equalTo(iconImageView)
        }

        descriptionLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(18)
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(titleLabel)
        }
        
        // 크기 확실하게 해주기
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        descriptionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        descriptionLabel.lineBreakMode = .byTruncatingTail
    }
}

//이미지 없고 텍스트만 있는 뷰 설명 한 줄
private final class SearchInfoTextBlockView: UIView {
    private let titleLabel = UILabel().then {
        $0.apply(.label12, color: .black)
    }

    private let descriptionLabel = UILabel().then {
        $0.apply(.body12, color: .grayScale700)
    }

    init(title: String, description: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        descriptionLabel.text = description
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel]).then {
            $0.axis = .vertical
            $0.spacing = 4
            $0.alignment = .fill
        }

        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
