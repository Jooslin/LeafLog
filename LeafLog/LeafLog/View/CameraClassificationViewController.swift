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
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        
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
        // viewWillAppear
        self.rx.viewWillAppear
            .withUnretained(self)
            .map { `self`, _ in
                return CameraClassificationReactor.Action.viewWillAppear(self.cameraClassificationView)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // 뒤로가기
        cameraClassificationView.rx.backButtonTap
            .subscribe(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.pop)
            })
            .disposed(by: disposeBag)
        
        // 촬영하기
        cameraClassificationView.shootButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .map { `self`, _ in
                CameraClassificationReactor.Action.capture(
                    self.normalizedGuideFrame()
                )
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: CameraClassificationReactor) {
        reactor.state
            .map { AppStep.classificationResult($0.classificationResult)
            }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        let isAuthorized = reactor.pulse(\.$isAuthorized)
            .asDriver(onErrorDriveWith: .empty())
        
        let isCameraReady = reactor.pulse(\.$isCameraReady)
            .asDriver(onErrorDriveWith: .empty())
        
        Driver
            .combineLatest(isAuthorized, isCameraReady)
            .drive(onNext: { [weak self] isAuthorized, isCameraReady in
                self?.cameraClassificationView.configure(isAuthorized: isAuthorized, isCameraReady: isCameraReady)
                
                if isAuthorized && isCameraReady {
                    self?.view.backgroundColor = .clear
                } else {
                    self?.view.backgroundColor = .white
                }
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] message in
                self?.steps.accept(AppStep.alert("에러", message))
            })
            .disposed(by: disposeBag)
    }

}

// MARK: Added - Normalized Guide Frame
extension CameraClassificationViewController {
    // CameraPreview의 resizeAspectFill 표시 방식을 previewLayer가 직접 반영하여
    // 화면의 guideFrame을 원본 비디오/사진 좌표계 기준 normalized rect(0~1)로 변환
    private func normalizedGuideFrame() -> CGRect {
        let previewLayer = cameraClassificationView.cameraPreview.videoPreviewLayer
        let guideFrame = cameraClassificationView.guideFrameSize

        return previewLayer.metadataOutputRectConverted(fromLayerRect: guideFrame)
    }
}

//MARK: CameraClassificationViewController Preview
@available(iOS 17.0, *)
#Preview {
  CameraClassificationViewController()
}
