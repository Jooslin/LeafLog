//
//  MyActivityViewController.swift
//  LeafLog
//

import RxCocoa
import RxSwift
import UIKit

final class MyActivityViewController: BaseViewController {
    private let myActivityView = MyActivityView()
    private let writtenPosts = MyActivityPost.mockPosts()
    private let commentedPosts = MyActivityPost.mockPosts()

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

        myActivityView.segmentedControl.rx.selectedSegmentIndex
            .compactMap(MyActivityTab.init(rawValue:))
            .subscribe(onNext: { [weak self] tab in
                self?.render(tab: tab)
            })
            .disposed(by: disposeBag)
    }

    private func render(tab: MyActivityTab) {
        let posts = switch tab {
        case .written:
            writtenPosts
        case .commented:
            commentedPosts
        }

        myActivityView.render(posts: posts, tab: tab)
    }
}
