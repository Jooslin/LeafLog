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
    
    //MARK: Bind
    func bind(reactor: CameraClassificationReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: CameraClassificationReactor) {
        //TODO: viewWillAppear가 아닌 이니셜라이즈 분기 처리필요 - 중복 세션 생성 방지를 위함
        self.rx.viewWillAppear
            .withUnretained(self)
            .map { `self`, _ in
                return CameraClassificationReactor.Action.viewWillAppear(self.cameraClassificationView)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: CameraClassificationReactor) {
        let state = reactor.state.asDriver(onErrorJustReturn: CameraClassificationReactor.State())
        
        reactor.pulse(\.$isCameraAvailable)
            .map { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(
                with: self,
                onNext: { `self`, isAvailable in
                    if isAvailable {
                        self.cameraService.connectSession(preview: self.cameraClassificationView.cameraPreview)
                        self.cameraService.startSession()
                    }
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("Error", message))
            })
            .disposed(by: disposeBag)
    }
}

//MARK: CameraClassificationViewController Preview
@available(iOS 17.0, *)
#Preview {
  CameraClassificationViewController()
}
