//
//  SearchDetailViewController.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/16/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import UIKit
import Then

final class SearchDetailViewController: BaseViewController, View {
    let detailView = SearchDetailView()

    init(reactor: SearchDetailReactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    override func loadView() {
        view = detailView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }

    func bind(reactor: SearchDetailReactor) {

        // 화면 뜨면서
        Observable.just(())
            .map { SearchDetailReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 데이터 들어오는지 확인
        reactor.state
            .compactMap { $0.detail }
            .subscribe(onNext: { detail in
            })
            .disposed(by: disposeBag)
        
        // 이미지 들어오는 지 확인
        reactor.state
            .map { $0.images }
            .filter { !$0.isEmpty }
            .subscribe(onNext: { images in
            })
            .disposed(by: disposeBag)
    }
}
