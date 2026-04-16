//
//  CameraClassificationViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/15/26.
//

import UIKit
import AVFoundation
import Dependencies
import ReactorKit
import RxCocoa

class CameraClassificationViewController: BaseViewController, View {
    //MARK: properties
    @Dependency(\.cameraService) private var cameraService
    let cameraClassificationView = CameraClassificationView()
    
    //MARK: Lifecycle
    override func loadView() {
        view = cameraClassificationView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reactor = CameraClassificationReactor()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Task { [weak self] in
            await self?.cameraService.stopRunningSession()
        }
    }
    
    //MARK: Bind
    func bind(reactor: CameraClassificationReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: CameraClassificationReactor) {
        self.rx.viewWillAppear
            .withUnretained(self)
            .map { `self`, _ in
                return CameraClassificationReactor.Action.viewWillAppear(self.cameraClassificationView)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        cameraClassificationView.rx.backButtonTap
            .subscribe(onNext: { [weak self] _ in
                    self?.steps.accept(AppStep.pop)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: CameraClassificationReactor) {
        let state = reactor.state
            .asDriver(onErrorJustReturn: CameraClassificationReactor.State())
        
        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self, onNext: { `self`, message in
//                self.cameraClassificationView.cameraAuthDenied()
                print(message)
                
            })
            .disposed(by: disposeBag)
    }

}

//MARK: CameraClassificationViewController Preview
@available(iOS 17.0, *)
#Preview {
  CameraClassificationViewController()
}
