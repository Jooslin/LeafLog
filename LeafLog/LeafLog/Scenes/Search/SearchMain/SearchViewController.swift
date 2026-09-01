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

nonisolated enum SearchListItem: Hashable, Sendable {
    case plant(String)
    case empty(String)
    case bottomGuide
}

// TODO: APPFlow 적용하기
final class SearchViewController: BaseViewController, View {
    private let rootView = SearchRootView()
    private var itemsByIdentifier: [String: PlantSummaryItem] = [:]
    // 식물 번호로 저장
    private var dataSource: UICollectionViewDiffableDataSource<String, SearchListItem>?

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
        maximumDynamicTypeCategory = .accessibilityLarge
        super.viewDidLoad()
        configureFilters()
        configureCollectionView()
        bindUI()
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
            SearchEmptyResultCell.self,
            forCellWithReuseIdentifier: SearchEmptyResultCell.reuseIdentifier
        )
        rootView.collectionView.register(
            SearchBottomGuideCell.self,
            forCellWithReuseIdentifier: SearchBottomGuideCell.reuseIdentifier
        )
        rootView.collectionView.delegate = self
        configureDataSource()
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<String, SearchListItem>(
            collectionView: rootView.collectionView
        ) { [weak self] collectionView, indexPath, item in
            switch item {
            case .plant(let identifier):
                guard let self,
                      let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SearchResultCell.reuseIdentifier,
                    for: indexPath
                      ) as? SearchResultCell,
                      let plant = self.itemsByIdentifier[identifier]
                else {
                    return UICollectionViewCell()
                }
                
                cell.configure(
                    plantName: plant.name,
                    confidence: plant.confidence,
                    thumbnailURLString: plant.displayThumbnailURL
                )
                cell.onSelectButtonTap = { [weak self] in
                    self?.reactor?.action.onNext(.selectPlant(plant))
                }
                return cell
                
            case .empty(let message):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SearchEmptyResultCell.reuseIdentifier,
                    for: indexPath
                ) as? SearchEmptyResultCell else {
                    return UICollectionViewCell()
                }
                
                cell.configure(message: message)
                return cell
                
            case .bottomGuide:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SearchBottomGuideCell.reuseIdentifier,
                    for: indexPath
                ) as? SearchBottomGuideCell else {
                    return UICollectionViewCell()
                }
                
                cell.onRegisterOtherTap = { [weak self] in
                    self?.steps.accept(AppStep.plantRegisterSelectedPlant(.other))
                }
                return cell
            }
        }
    }
    
    private func bindUI() {
        rootView.titleHeaderView.backButton.addAction(
            UIAction { [weak self] _ in
                self?.steps.accept(AppStep.pageBack)
            },
            for: .touchUpInside
        )

        rootView.searchBarView.cameraButton.addAction(
            UIAction { [weak self] _ in
                self?.steps.accept(AppStep.cameraRequired)
            },
            for: .touchUpInside
        )
        
        rootView.titleHeaderView.rightButton.addAction(
            UIAction { [weak self] _ in
                let infoViewController = SearchInfoViewController()
                infoViewController.modalPresentationStyle = .overFullScreen
                self?.present(infoViewController, animated: false)
            },
            for: .touchUpInside
        )
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
            .map { ($0.listItems, $0.plants) }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] listItems, plants in
                self?.applySnapshot(listItems: listItems, plants: plants)
            })
            .disposed(by: disposeBag)

        reactor.state // 검색 결과 상태 메세지
            .map(\.resultText)
            .distinctUntilChanged()
            .bind(to: rootView.emptyLabel.rx.text)
            .disposed(by: disposeBag)

        reactor.state // 검색 결과 보여줄지 말지
            .map(\.hasSearched)
            .distinctUntilChanged()
            .bind(to: rootView.emptyLabel.rx.isHidden)
            .disposed(by: disposeBag)

        reactor.state // 필터 버튼 제목/메뉴를 갱신
            .distinctUntilChanged { $0.filterState == $1.filterState && $0.filterOptions == $1.filterOptions }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.updateFilterMenus(state: state, reactor: reactor)
            })
            .disposed(by: disposeBag)

        reactor.pulse(\.$selectedPlant)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] selectedPlant in
                self?.steps.accept(AppStep.plantRegisterSelectedPlant(selectedPlant))
            })
            .disposed(by: disposeBag)

        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("에러", message))
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.titleText }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] titleText in
                self?.rootView.titleHeaderView.titleLabel.text = titleText
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
    private func applySnapshot(
        listItems: [SearchListItem],
        plants: [PlantSummaryItem],
        animated: Bool = true
    ) {
        itemsByIdentifier = Dictionary(
            uniqueKeysWithValues: plants.map { ($0.contentNumber, $0) }
        )

        var snapshot = NSDiffableDataSourceSnapshot<String, SearchListItem>()
        snapshot.appendSections(["main"])
        snapshot.appendItems(listItems, toSection: "main")
        dataSource?.apply(snapshot, animatingDifferences: animated)
    }
}

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

extension SearchViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard case .plant(let identifier) = dataSource?.itemIdentifier(for: indexPath),
            let item = itemsByIdentifier[identifier]
        else { return }
        steps.accept(AppStep.plantSearchDetail(item.contentNumber))
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        switch dataSource?.itemIdentifier(for: indexPath) {
        case .plant:
            return CGSize(width: collectionView.bounds.width, height: 104)
            
        case .empty:
            return CGSize(width: collectionView.bounds.width, height: 104)
            
        case .bottomGuide:
            return CGSize(width: collectionView.bounds.width, height: 188)
            
        case .none:
            return CGSize(width: collectionView.bounds.width, height: 104)
        }
    }
}
