//
//  CameraClassificationViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/15/26.
//

import UIKit
import AVFoundation
import Dependencies

class CameraClassificationViewController: BaseViewController {
    @Dependency(\.cameraService) private var cameraService
    let cameraClassificationView = CameraClassificationView()
    
    override func loadView() {
        view = cameraClassificationView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try cameraService.checkCameraAuthorization()
        } catch {
            print(error)
        }
        cameraService.connectSession(preview: cameraClassificationView.cameraPreview)
        cameraService.startSession()
    }
}

//MARK: CameraClassificationViewController Preview
@available(iOS 17.0, *)
#Preview {
  CameraClassificationViewController()
}
