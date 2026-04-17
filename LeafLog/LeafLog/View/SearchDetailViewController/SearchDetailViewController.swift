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

        detailView.closeButtonTap
            .bind(with: self) { owner, _ in
                if owner.presentingViewController != nil {
                    owner.dismiss(animated: true)
                } else {
                    owner.navigationController?.popViewController(animated: true)
                }
            }
            .disposed(by: disposeBag)

        reactor.state
            .map { ($0.detail, $0.displayName, $0.displayImageURLs) }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] detail, displayName, imageURLs in
                self?.detailView.configure(detail: detail, displayName: displayName, imageURLs: imageURLs)
            })
            .disposed(by: disposeBag)
    }
}
