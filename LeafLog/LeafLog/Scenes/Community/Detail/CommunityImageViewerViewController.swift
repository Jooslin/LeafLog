//
//  CommunityImageViewerViewController.swift
//  LeafLog
//
//  Created by Yeseul Jang on 7/9/26.
//

import SnapKit
import Then
import UIKit

final class CommunityImageViewerViewController: UIViewController {
    private let imageAssetNames: [String]
    private let initialIndex: Int
    private var didScrollToInitialIndex = false
    
    private let imageCollectionViewFlowLayout = UICollectionViewFlowLayout().then {
        $0.scrollDirection = .horizontal
        $0.minimumLineSpacing = 0
        $0.minimumInteritemSpacing = 0
    }
    
    private lazy var imageCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: imageCollectionViewFlowLayout
    ).then {
        $0.backgroundColor = .black
        $0.isPagingEnabled = true
        $0.showsHorizontalScrollIndicator = false
        $0.dataSource = self
        $0.delegate = self
        $0.register(
            CommunityImageViewerCell.self,
            forCellWithReuseIdentifier: CommunityImageViewerCell.reuseIdentifier
        )
    }
    
    private let closeButton = UIButton(configuration: .plain()).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.configuration?.baseForegroundColor = .white
        $0.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    
    private let pageControl = UIPageControl().then {
        $0.currentPage = 0
        $0.hidesForSinglePage = true
        $0.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.4)
        $0.currentPageIndicatorTintColor = .white
    }
    
    init(imageAssetNames: [String], initialIndex: Int) {
        self.imageAssetNames = imageAssetNames
        self.initialIndex = max(0, min(initialIndex, imageAssetNames.count - 1))
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        pageControl.numberOfPages = imageAssetNames.count
        pageControl.currentPage = initialIndex
        setLayout()
        closeButton.addTarget(self, action: #selector(closeButtonDidTap), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let collectionViewSize = imageCollectionView.bounds.size
        guard collectionViewSize.width > 0, collectionViewSize.height > 0 else { return }
        
        if imageCollectionViewFlowLayout.itemSize != collectionViewSize {
            imageCollectionViewFlowLayout.itemSize = collectionViewSize
            imageCollectionViewFlowLayout.invalidateLayout()
        }
        
        guard !didScrollToInitialIndex, !imageAssetNames.isEmpty else { return }
        didScrollToInitialIndex = true
        imageCollectionView.scrollToItem(
            at: IndexPath(item: initialIndex, section: 0),
            at: .centeredHorizontally,
            animated: false
        )
    }
    
    private func setLayout() {
        view.addSubview(imageCollectionView)
        view.addSubview(closeButton)
        view.addSubview(pageControl)
        
        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(27)
            $0.trailing.equalToSuperview().inset(18)
            $0.width.height.equalTo(24)
        }
        
        imageCollectionView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-38)
            $0.height.equalTo(412)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(imageCollectionView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }
    }
    
    @objc private func closeButtonDidTap() {
        dismiss(animated: true)
    }
}

extension CommunityImageViewerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageAssetNames.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CommunityImageViewerCell.reuseIdentifier,
            for: indexPath
        ) as? CommunityImageViewerCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(imageAssetName: imageAssetNames[indexPath.item])
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === imageCollectionView, scrollView.bounds.width > 0 else { return }
        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        pageControl.currentPage = max(0, min(page, max(pageControl.numberOfPages - 1, 0)))
    }
}

private final class CommunityImageViewerCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: CommunityImageViewerCell.self)
    
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .black
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(imageAssetName: String) {
        imageView.image = UIImage(named: imageAssetName) ?? UIImage(resource: .placeholder)
    }
}
