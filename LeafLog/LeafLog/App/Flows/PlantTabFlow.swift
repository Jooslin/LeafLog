//
//  PlantTabFlow.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/5/26.
//

import UIKit
import RxFlow
import Dependencies
import AVFoundation
import RxRelay
import PhotosUI

/*
 RxFlow 사용 예시입니다. - 추후 해당 탭 구현 시 변경 예정입니다.
 switch문으로 step에 따라 실행할 동작을 정의해주시면 됩니다.
 PlantTabFlow에서만 step에 따른 동작을 정의해놓았으므로 다른 탭(Calendar, MyInfo)에서는 push버튼을 눌러도 아무 동작이 실행되지 않습니다.
 */

final class PlantTabFlow: Flow {
    @Dependency(\.cameraService) private var cameraService
    @Dependency(\.uiApplication) private var uiApplication
    private let navigationController = UINavigationController()
    private let viewController = ViewController() //TODO: 등록 VC로 변경 필요
    private let photoSelectStepper = PhotoSelectStepper()
    
    var root: any RxFlow.Presentable { navigationController }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .plantTab: // 메인 컨트롤러 표시
//            let viewController = ViewController()//TODO: PlantVC로 변경 필요
            navigationController.pushViewController(viewController, animated: true)

            //TODO: PlantVC 내용으로 변경 필요
//            return .one(flowContributor: .contribute(
//                withNextPresentable: viewController,
//                withNextStepper: viewController
//            )
            
            //TODO: 등록VC 띄우는 step으로 이관 필요
            return .one(
                flowContributor: .contribute(
                    withNextPresentable: viewController,
                    withNextStepper: CompositeStepper(
                        steppers: [viewController, photoSelectStepper]
                    )))
            
        case .classificationResult(let result): // AI 검색 결과 표시
            let searchViewController = SearchViewController(classficationResult: result)
            
            navigationController.pushViewController(searchViewController, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: searchViewController, withNextStepper: searchViewController))
        
        case .applicatoinSettingRequired: // 휴대폰 앱 설정 화면 이동
            if let url = URL(string: UIApplication.openSettingsURLString) {
                uiApplication.open(url)
            }
            return .none
            
        case .photoSelect: // 사진 선택 분기
            return presentPhotoSelect()
            
        case .cameraRequired:
            let camera = CameraClassificationViewController()
            navigationController.pushViewController(camera, animated: true)
            
            return .one(flowContributor: .contribute(withNextPresentable: camera, withNextStepper: camera))
            
        case .galleryRequired:
            return presentGallery()
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}

extension PlantTabFlow {
    // 사진 선택 alert에서 사용할 stepper
    struct PhotoSelectStepper: Stepper {
        let steps = PublishRelay<Step>()
    }
    
    private func presentPhotoSelect() -> FlowContributors {
        let alert = UIAlertController()
        let cameraAction = UIAlertAction(title: "촬영하기", style: .default) { [weak self] _ in
            self?.photoSelectStepper.steps.accept(AppStep.cameraRequired)
        }
        
        let galleryAction = UIAlertAction(title: "이미지 불러오기", style: .default) { [weak self] _ in
            self?.photoSelectStepper.steps.accept(AppStep.galleryRequired)
        }
        
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        alert.addAction(cancel)
        
        navigationController.present(alert, animated: true)
        
        return .none
    }
    
    private func presentGallery() -> FlowContributors {
        var config = PHPickerConfiguration()
        config.filter = .images // 라이브러리에서 보여줄 asset의 종류 지정
        config.selectionLimit = 1 // 선택 개수 설정 (0은 무제한)
        
        let imagePicker = PHPickerViewController(configuration: config)
        imagePicker.delegate = viewController
        
        navigationController.present(imagePicker, animated: true)
        
        return .none
    }
}
