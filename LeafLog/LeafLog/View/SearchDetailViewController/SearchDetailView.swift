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

final class SearchDetailView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
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

    private var imageItems: [PlantFileItem] = []

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
    
    func configure(detail: PlantDetail?, images: [PlantFileItem]) {
        configureImages(with: images)
        configureHeader(detail: detail, images: images)
        configureSections(detail: detail)
    }
    
    // 초기 세팅
    private func configureInitialState() {
        imageItems = []
        pageControl.numberOfPages = 0
        nameLabel.text = "식물 정보를 불러오는 중"
        familyNameLabel.text = nil
        originLabel.text = nil
        configureSections(detail: nil)
        imageCollectionView.reloadData()
    }
    
    private func configureImages(with images: [PlantFileItem]) {
        imageItems = images.filter { $0.fileCodeName == "이미지" || $0.isImage }
        pageControl.numberOfPages = imageItems.count
        pageControl.currentPage = 0
        imageCollectionView.reloadData()

        guard !imageItems.isEmpty else { return }
        imageCollectionView.setContentOffset(.zero, animated: false)
    }
    
    private func configureHeader(detail: PlantDetail?, images: [PlantFileItem]) {
        nameLabel.text = displayName(detail: detail, images: images)

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

    private func displayName(detail: PlantDetail?, images: [PlantFileItem]) -> String {
        nonEmptyValue(images.first?.name)
        ?? "이름 정보 없음"
    }
    
    // 공백 제거 및 값 확인
    private func nonEmptyValue(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }

        return trimmed
    }
    
    private static func firstURL(from rawValue: String) -> String {
        rawValue.components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? rawValue
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

        // 버튼 고정으로
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
        
        // 버튼
        buttonStack.snp.makeConstraints {
            $0.leading.trailing.bottom.equalTo(safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(50)
        }
    }
    
    // 셀과 컬렉션 뷰 크기 맞추기
    override func layoutSubviews() {
        super.layoutSubviews()
        imageCollectionViewFlowLayout.itemSize = CGSize(width: imageCollectionView.bounds.width, height: imageCollectionView.bounds.height)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        max(imageItems.count, 1)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SearchDetailImageCell.reuseIdentifier,
            for: indexPath
        ) as? SearchDetailImageCell else {
            return UICollectionViewCell()
        }

        let imageURLString = imageItems.indices.contains(indexPath.item)
            ? Self.firstURL(from: imageItems[indexPath.item].fileURL ?? imageItems[indexPath.item].thumbnailURL ?? "")
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

// 한줄 세부사항
final class DetailInfoRowView: UIView {

    private let titleLabel = UILabel(config: .label14, color: .black)

    private let valueLabel = UILabel(config: .label14, color: .grayScale600).then {
        $0.numberOfLines = 0
        $0.textAlignment = .right
    }

    init(title: String, value: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
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
            $0.top.bottom.equalToSuperview().inset(5)
        }
    }
}

// 이미지 셀
final class SearchDetailImageCell: UICollectionViewCell {
    static let reuseIdentifier = "SearchDetailImageCell"

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .grayScale100
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = UIImage(systemName: "photo")
    }

    func configure(imageURLString: String?) {
        let placeholderImage = UIImage(systemName: "photo")

        guard let imageURLString, !imageURLString.isEmpty,
              let url = URL(string: imageURLString) else {
            imageView.image = placeholderImage
            return
        }

        imageView.kf.setImage(with: url, placeholder: placeholderImage)
    }
}

// 섹션
final class DetailInfoSectionView: UIView {
    
    private let sectionImage = UIImageView()
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

    init(imageResource: ImageResource, title: String, rows: [DetailInfoRowView]) {
        super.init(frame: .zero)
        sectionImage.image = UIImage(resource: imageResource)
        titleLabel.text = title

        setupLayout()

        setRows(rows)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(sectionImage)
        addSubview(titleLabel)
        addSubview(stackView)
        
        sectionImage.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(2)
            $0.size.equalTo(14)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.trailing.equalToSuperview()
            $0.leading.equalTo(sectionImage.snp.trailing).offset(4)
        }

        stackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    // 기존의 줄들을 다 지우고 셋팅
    func setRows(_ rows: [DetailInfoRowView]) {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        rows.forEach {
            stackView.addArrangedSubview($0)
        }

        isHidden = rows.isEmpty
    }
    
    // (String, String?) 배열을 받아서 값이 비어있지 않은 것만 DetailInfoRowView로 변환
    func setRows(_ rows: [(String, String?)]) {
        let rowViews = rows.compactMap { title, value -> DetailInfoRowView? in
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else {
                return nil
            }

            return DetailInfoRowView(title: title, value: value)
        }

        setRows(rowViews)
    }
}
