//
//  PlantClassificationService.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/6/26.
//

import TensorFlowLite
import UIKit

class PlantClassificationService {
    // 이미지 크기
    private let inputWidth = 224
    private let inputHeight = 224
    
    func analyzeImage(image: UIImage) {
        guard let mediaPath = Bundle.main.path(forResource: "3", ofType: "tflite") else {
            print("모델 파일을 찾을 수 없습니다.")
            return
        }
    }
}
