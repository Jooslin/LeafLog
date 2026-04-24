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
        Observable.just(())
            .map { SearchDetailReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        detailView.rx.closeButtonTap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)

        detailView.rx.selectButtonTap
            .map { SearchDetailReactor.Action.selectPlant }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state
            .map { ($0.detail, $0.displayName) }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] detail, displayName in
                self?.detailView.configureContent(detail: detail, displayName: displayName)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.displayImageURLs)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] imageURLs in
                self?.detailView.configureImages(imageURLs: imageURLs)
            })
            .disposed(by: disposeBag)

        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("에러", message))
            })
            .disposed(by: disposeBag)

        reactor.pulse(\.$selectedPlant)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] selectedPlant in
                self?.steps.accept(AppStep.plantRegister(selectedPlant))
            })
            .disposed(by: disposeBag)
    }
}
