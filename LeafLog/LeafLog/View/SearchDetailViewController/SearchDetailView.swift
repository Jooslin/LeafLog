//
//  SearchDetailView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/16/26.
//
import Kingfisher
import RxCocoa
import SnapKit
import Then
import UIKit
import RxSwift

final class SearchDetailView: UIView {
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // 이미지 레이아웃
    private let imageCollectionViewFlowLayout = UICollectionViewFlowLayout().then {
        $0.scrollDirection = .horizontal
        $0.minimumLineSpacing = 0
        $0.minimumInteritemSpacing = 0
    }
    
    // 이미지 컬렉션 뷰
    private lazy var imageCollectionView = UICollectionView(frame: .zero, collectionViewLayout: imageCollectionViewFlowLayout).then {
        $0.backgroundColor = .clear
        $0.isPagingEnabled = true
        $0.showsHorizontalScrollIndicator = false
        $0.dataSource = self
        $0.delegate = self
        $0.register(SearchDetailImageCell.self, forCellWithReuseIdentifier: SearchDetailImageCell.reuseIdentifier)
    }
    
    //페이지 컨트롤(이미지가 1개이면 숨김)
    private let pageControl = UIPageControl().then {
        $0.currentPage = 0
        $0.hidesForSinglePage = true
        $0.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        $0.currentPageIndicatorTintColor = .white
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

    // 섹션 정보들
    let environmentSection = DetailInfoSectionView(
        imageResource: .badgeSunBig,
        title: "생육 환경",
        rows: []
    )
    
    let appearanceSection = DetailInfoSectionView(
        imageResource: .badgeGrowSmall,
        title: "외형 특징",
        rows: []
    )
    
    let wateringSection = DetailInfoSectionView(
        imageResource: .badgeWaterSmall,
        title: "물주기",
        rows: []
    )
    
    let flowerAndFruitSection = DetailInfoSectionView(
        imageResource: .badgeSproutSmall,
        title: "개화/열매",
        rows: []
    )

    private var imageURLs: [String] = []

    // 버튼탭 이벤트
    var closeButtonTap: ControlEvent<Void> {
        closeButton.rx.tap
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupLayout()
        configureInitialState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageCollectionViewFlowLayout.itemSize = CGSize(width: imageCollectionView.bounds.width, height: imageCollectionView.bounds.height)
    }
}


// MARK: 데이터 변경
extension SearchDetailView {
    func configureContent(detail: PlantDetail?, displayName: String) {
        configureHeader(detail: detail, displayName: displayName)
        configureSections(detail: detail)
    }

    func configureImages(imageURLs: [String]) {
        updateImages(with: imageURLs)
    }
}

// MARK: UI 구현 부
private extension SearchDetailView {
    private func configureInitialState() {
        imageURLs = []
        pageControl.numberOfPages = 0
        nameLabel.text = "식물 정보를 불러오는 중"
        familyNameLabel.text = nil
        originLabel.text = nil
        configureSections(detail: nil)
        imageCollectionView.reloadData()
    }

    private func updateImages(with imageURLs: [String]) {
        self.imageURLs = imageURLs
        pageControl.numberOfPages = imageURLs.count
        pageControl.currentPage = 0
        imageCollectionView.reloadData()

        guard !imageURLs.isEmpty else { return }
        imageCollectionView.setContentOffset(.zero, animated: false)
    }

    private func configureHeader(detail: PlantDetail?, displayName: String) {
        nameLabel.text = displayName

        if let familyName = nonEmptyValue(detail?.familyName) {
            familyNameLabel.text = "과명: \(familyName)"
            familyNameLabel.isHidden = false
        } else {
            familyNameLabel.text = nil
            familyNameLabel.isHidden = true
        }

        if let origin = nonEmptyValue(detail?.origin) {
            originLabel.text = "원산지: \(origin)"
            originLabel.isHidden = false
        } else {
            originLabel.text = nil
            originLabel.isHidden = true
        }
    }

    private func configureSections(detail: PlantDetail?) {
        environmentSection.setRows([
            ("광도요구", detail?.lightDemand),
            ("겨울 최저온도", detail?.winterMinimumTemperature)
        ])

        appearanceSection.setRows([
            ("생육 형태", detail?.growStyle),
            ("잎색", detail?.leafColor),
            ("잎무늬", detail?.leafMark)
        ])

        wateringSection.setRows([
            ("봄", detail?.springWaterCycle),
            ("여름", detail?.summerWaterCycle),
            ("가을", detail?.autumnWaterCycle),
            ("겨울", detail?.winterWaterCycle),
        ])

        flowerAndFruitSection.setRows([
            ("꽃색", detail?.flowerColor),
            ("꽃피는 계절", detail?.flowerSeason),
            ("열매색", detail?.fruitColor),
            ("열매 계절", detail?.fruitSeason)
        ])
    }

    private func nonEmptyValue(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }

        return trimmed
    }
    
    private func setupLayout() {
        addSubview(scrollView)
        addSubview(buttonStack)

        scrollView.addSubview(contentView)

        contentView.addSubview(imageCollectionView)
        contentView.addSubview(pageControl)
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

        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            $0.bottom.equalTo(buttonStack.snp.top)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        imageCollectionView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(350)
        }

        pageControl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(imageCollectionView.snp.bottom).inset(12)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imageCollectionView.snp.bottom).offset(16)
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
        
        buttonStack.snp.makeConstraints {
            $0.leading.trailing.bottom.equalTo(safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(50)
        }
    }
}

// MARK: 콜렉션 뷰(식물 이미지) 구현 부
extension SearchDetailView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        max(imageURLs.count, 1)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SearchDetailImageCell.reuseIdentifier,
            for: indexPath
        ) as? SearchDetailImageCell else {
            return UICollectionViewCell()
        }

        let imageURLString = imageURLs.indices.contains(indexPath.item)
            ? imageURLs[indexPath.item]
            : nil
        cell.configure(imageURLString: imageURLString)
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === imageCollectionView, scrollView.bounds.width > 0 else { return }
        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        pageControl.currentPage = max(0, min(page, max(pageControl.numberOfPages - 1, 0)))
    }
}
