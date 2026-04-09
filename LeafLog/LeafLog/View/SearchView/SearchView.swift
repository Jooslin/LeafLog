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

final class SearchView: BaseViewController, View {
    private let searchTypeControl = UISegmentedControl(items: PlantSearchType.allCases.map(\.title)).then {
        $0.selectedSegmentIndex = 0
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
        configureLayout()
    }
    
    // 입출력 연결
    func bind(reactor: SearchReactor) {
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
    }

    private func configureLayout() {
        view.addSubview(searchTypeControl)
        view.addSubview(searchTextField)
        view.addSubview(loadingLabel)
        view.addSubview(resultLabel)

        searchTypeControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        searchTextField.snp.makeConstraints {
            $0.top.equalTo(searchTypeControl.snp.bottom).offset(16)
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
