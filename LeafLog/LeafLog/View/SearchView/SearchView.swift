//
//  SearchView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/8/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import UIKit
import Then


// TODO: 오류 처리
final class SearchView: BaseViewController, View {
    private let searchTypeControl = UISegmentedControl(items: PlantSearchType.allCases.map(\.title)).then {
        $0.selectedSegmentIndex = 0
    }

    private let filterScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
    }

    private let filterStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .fill
        $0.distribution = .fillProportionally
    }

    private let searchTextField = UITextField().then {
        $0.borderStyle = .roundedRect
        $0.placeholder = "검색어를 입력해 주세요"
        $0.clearButtonMode = .whileEditing
        $0.autocapitalizationType = .none
    }

    private let resultLabel = UILabel().then {
        $0.numberOfLines = 0
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .label
        $0.text = "검색어입력"
    }

    private let loadingLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .secondaryLabel
        $0.text = "검색 중"
        $0.isHidden = true
    }

    private var filterButtons: [PlantFilterKind: UIButton] = [:]
    
    // 테스트 용으로 생성될 떄 SearchReactor()해서 그냥 생성 가능하게
    // self.reactor = reactor 하는 순간 bind 메서드 호출
    init(reactor: SearchReactor = SearchReactor()) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureFilterButtons()
        configureLayout()
    }
    
    // 입출력 연결
    func bind(reactor: SearchReactor) {
        Observable.just(SearchReactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchTypeControl.rx.selectedSegmentIndex
            .compactMap { PlantSearchType.allCases[safe: $0] }
            .map(SearchReactor.Action.updateSearchType)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 텍스트 필드에서 흐르는거 계속 받음
        searchTextField.rx.text.orEmpty
            .debounce(.milliseconds(400), scheduler: MainScheduler.instance)
        // 이전값이랑 같으면 무시
            .distinctUntilChanged()
        // 입력 문자열을 Reactor의 액션으로 변환
            .map(SearchReactor.Action.updateQuery)
        // Reactor로 전달
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // 상태를 보고 결과 라벨을 바인딩
        reactor.state
            .map(\.resultText)
            .distinctUntilChanged()
            .bind(to: resultLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 로딩중도 바꿔줌
        reactor.state
            .map(\.isLoading)
            .distinctUntilChanged()
            .map { !$0 }
            .bind(to: loadingLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        // 필터 메뉴 선택 바꿔줌
        reactor.state
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.updateFilterMenus(state: state, reactor: reactor)
            })
            .disposed(by: disposeBag)
    }

    private func configureLayout() {
        view.addSubview(searchTypeControl)
        view.addSubview(filterScrollView)
        filterScrollView.addSubview(filterStackView)
        view.addSubview(searchTextField)
        view.addSubview(loadingLabel)
        view.addSubview(resultLabel)

        searchTypeControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        filterScrollView.snp.makeConstraints {
            $0.top.equalTo(searchTypeControl.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(40)
        }

        filterStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
            $0.height.equalToSuperview()
        }

        searchTextField.snp.makeConstraints {
            $0.top.equalTo(filterScrollView.snp.bottom).offset(16)
            $0.horizontalEdges.equalTo(searchTypeControl)
            $0.height.equalTo(50)
        }

        loadingLabel.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom).offset(12)
            $0.horizontalEdges.equalTo(searchTextField)
        }

        resultLabel.snp.makeConstraints {
            $0.top.equalTo(loadingLabel.snp.bottom).offset(16)
            $0.horizontalEdges.equalTo(searchTextField)
        }
    }

    private func configureFilterButtons() {
        PlantFilterKind.allCases.forEach { kind in
            var configuration = UIButton.Configuration.filled()
            configuration.cornerStyle = .capsule
            configuration.baseBackgroundColor = .secondarySystemBackground
            configuration.baseForegroundColor = .label
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            configuration.title = kind.title

            let button = UIButton(configuration: configuration)
            button.showsMenuAsPrimaryAction = true
            filterButtons[kind] = button
            filterStackView.addArrangedSubview(button)
        }
    }
    
    // 버튼 상태 업데이트
    private func updateFilterMenus(state: SearchReactor.State, reactor: SearchReactor) {
        for kind in PlantFilterKind.allCases {
            guard let button = filterButtons[kind] else { continue }

            let options = state.filterOptions[kind] ?? []
            let selectedOption = state.filterState.option(for: kind)

            var configuration = button.configuration ?? .filled()
            configuration.title = selectedOption?.name ?? kind.title
            configuration.baseBackgroundColor = selectedOption == nil ? .secondarySystemBackground : .systemGreen
            configuration.baseForegroundColor = selectedOption == nil ? .label : .white
            button.configuration = configuration
            
            // 옵션 하나 선택시 액션을 보냄(선택됨을 알림)
            let actions = options.map { option in
                UIAction(title: option.name) { _ in
                    reactor.action.onNext(.updateFilter(kind, option))
                }
            }
            
            // 전체를 누르면 다 nil
            let clearAction = UIAction(title: "전체") { _ in
                reactor.action.onNext(.updateFilter(kind, nil))
            }

            button.menu = UIMenu(children: [clearAction] + actions)
        }
    }
}

// 안전하게 배열 접근할 수 있도록 확장(인덱스 벗어나서 접근해도 크래시 나지 않도록)
private extension Array {
    subscript(safe index: Int) -> Element? {
        // 범위 벗어나면 nil
        guard indices.contains(index) else { return nil }
        // 해당인덱스가 있을떄만 접근
        return self[index]
    }
}
