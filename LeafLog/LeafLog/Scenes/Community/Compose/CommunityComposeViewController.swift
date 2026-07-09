//
//  CommunityComposeViewController.swift
//  LeafLog
//
//  Created by 변예린 on 7/5/26.
//

import UIKit
import Dependencies
import ReactorKit
import RxCocoa

final class CommunityComposeViewController: BaseViewController, View {
    //MARK: properties
    let composeView = CommunityComposeView(mode: .create)
    
    //MARK: Lifecycle
    override func loadView() {
        view = composeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reactor = CameraClassificationReactor()
        hidesBottomBarWhenPushed = true
        navigationController?.navigationBar.isHidden = true
        
        
    }
    
    //MARK: Bind
    func bind(reactor: CameraClassificationReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: CameraClassificationReactor) {
        // 뒤로가기
        composeView.titleView.rx.backButtonTap
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.pageBack)
            })
            .disposed(by: disposeBag)
        
        // 안내문
        composeView.titleView.rx.rightButtonTap
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.composeNotice)
            })
            .disposed(by: disposeBag)
        
        
    }
    
    private func bindState(reactor: CameraClassificationReactor) {
        
    }
}

@available(iOS 17.0, *)
#Preview {
  CommunityComposeViewController()
}
