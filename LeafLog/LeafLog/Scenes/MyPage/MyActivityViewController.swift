//
//  MyActivityViewController.swift
//  LeafLog
//

import RxCocoa
import RxSwift
import UIKit

final class MyActivityViewController: BaseViewController {
    private let myActivityView = MyActivityView()

    override func loadView() {
        view = myActivityView
    }

    override func viewDidLoad() {
        maximumDynamicTypeCategory = .accessibilityLarge
        super.viewDidLoad()

        myActivityView.headerView.rx.backButtonTap
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
}
