//
//  SearchViewController.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/13/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import UIKit
import Then

final class SearchViewController: BaseViewController, View {
    private let rootView = SearchRootView()
    private var itemsByIdentifier: [String: PlantSummaryItem] = [:]
    // 식물 번호로 저장
    private var dataSource: UICollectionViewDiffableDataSource<String, String>?

    private var classificationResult: [String: PlantClassificationService.Confidence]? // AI 검색 에서 진입 시 존재
    
    init(reactor: SearchReactor = SearchReactor()) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }

    init(reactor: SearchReactor = SearchReactor(), classficationResult: [String: PlantClassificationService.Confidence]) {
        super.init(nibName: nil, bundle: nil)
        self.classificationResult = classficationResult
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureFilters()
        configureCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // 상단 필터 버튼 구현
    private func configureFilters() {
        rootView.configureFilterButtons(
            kinds: PlantFilterKind.allCases.filter { $0 != .searchType }
        )
    }

    private func configureCollectionView() {
        rootView.collectionView.register(
            SearchResultCell.self,
            forCellWithReuseIdentifier: SearchResultCell.reuseIdentifier
        )
        rootView.collectionView.register(
            SearchBottomGuideView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: SearchBottomGuideView.reuseIdentifier
        )
        rootView.collectionView.delegate = self
        configureDataSource()
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<String, String>(
            collectionView: rootView.collectionView
        ) { [weak self] collectionView, indexPath, identifier in
            guard let self,
                  let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SearchResultCell.reuseIdentifier,
                    for: indexPath
                  ) as? SearchResultCell,
                  let item = self.itemsByIdentifier[identifier]
            else {
                return UICollectionViewCell()
            }
            
            cell.configure(
                plantName: item.name,
                confidence: item.confidence,
                thumbnailURLString: item.displayThumbnailURL
            )
            return cell
        }

        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionFooter,
                  let view = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: SearchBottomGuideView.reuseIdentifier,
                    for: indexPath
                  ) as? SearchBottomGuideView
            else {
                return UICollectionReusableView()
            }

            return view
        }
    }

    func bind(reactor: SearchReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: SearchReactor) {
        Observable.just(SearchReactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        rootView.searchBarView.textField.rx.text.orEmpty
            .skip(1)
            .debounce(.milliseconds(400), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .map(SearchReactor.Action.updateQuery) // 입력문자 Reactor 액션으로 변환
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.rx.viewWillAppear
            .take(1)
            .compactMap { [classificationResult] _ in
                guard let classificationResult else { return nil }
                return SearchReactor.Action.classificationQuery(classificationResult)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }

    private func bindState(reactor: SearchReactor) {
        reactor.state // 식물 목록
            .map(\.plants)
            .distinctUntilChanged { previousPlants, currentPlants in
                previousPlants.map(\.contentNumber) == currentPlants.map(\.contentNumber)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] plants in
                self?.applySnapshot(plants: plants)
            })
            .disposed(by: disposeBag)

        reactor.state // 검색 결과 상태 메세지
            .map(\.resultText)
            .distinctUntilChanged()
            .bind(to: rootView.emptyLabel.rx.text)
            .disposed(by: disposeBag)

        reactor.state // 검색 결과 보여줄지 말지
            .map { $0.plants.isEmpty }
            .distinctUntilChanged()
            .map { !$0 }
            .bind(to: rootView.emptyLabel.rx.isHidden)
            .disposed(by: disposeBag)

        reactor.state // 필터 버튼 제목/메뉴를 갱신
            .distinctUntilChanged { $0.filterState == $1.filterState && $0.filterOptions == $1.filterOptions }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.updateFilterMenus(state: state, reactor: reactor)
            })
            .disposed(by: disposeBag)
    }

    // 필터링 버튼 구현 함수
    private func updateFilterMenus(state: SearchReactor.State, reactor: SearchReactor) {
        for kind in PlantFilterKind.allCases where kind != .searchType {
            guard let button = rootView.filterButtons[kind] else { continue }

            let options = state.filterOptions[kind] ?? []
            let selectedOption = state.filterState.option(for: kind)

            button.apply(title: selectedOption?.name ?? kind.title)
            button.applySelectionStyle(isSelected: selectedOption != nil)
            
            // 각 옵션을 메뉴 액션으로
            let actions = options.map { option in
                UIAction(title: option.name) { _ in
                    reactor.action.onNext(.updateFilter(kind, option))
                }
            }
            
            // 필터 해제용
            let clearAction = UIAction(title: "전체") { _ in
                reactor.action.onNext(.updateFilter(kind, nil))
            }
            
            // 버튼 메뉴 설정
            button.menu = UIMenu(children: [clearAction] + actions)
        }
    }
    
    // 파라미터 타입 변경
    private func applySnapshot(plants: [PlantSummaryItem], animated: Bool = true) {
        itemsByIdentifier = Dictionary(
            uniqueKeysWithValues: plants.map { ($0.contentNumber, $0) }
        )

        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        snapshot.appendSections(["main"])
        snapshot.appendItems(plants.map(\.contentNumber), toSection: "main")
        dataSource?.apply(snapshot, animatingDifferences: animated)
    }
}

extension SearchViewController: UICollectionViewDelegate {}

extension SearchViewController {
    // 컬렉션뷰 configure용 struct
    struct PlantSummaryItem {
        let contentNumber: String
        let name: String
        let imageURL: String?
        let thumbnailURL: String?
        let confidence: PlantClassificationService.Confidence // ai 검색 일치율

        let primaryThumbnailURL: String?
        let primaryImageURL: String?
        let displayThumbnailURL: String?
    }
}
