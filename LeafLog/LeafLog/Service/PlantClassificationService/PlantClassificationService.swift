//
//  PlantClassificationService.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/6/26.
//

import TensorFlowLite
import UIKit

class PlantClassificationService {
    enum Model {
        case aiyPlantsV1
        
        var modelPath: String? {
            switch self {
            case .aiyPlantsV1:
                return Bundle.main.path(forResource: "3", ofType: "tflite")
            }
        }
    }
    
    enum Confidence: String {
        case extremeHigh = "매우 높음"
        case high = "높음"
        case normal = "보통"
        case low = "낮음"
        
        static func from(value: UInt8) -> Confidence {
            switch value {
            case 150...255: .extremeHigh // 59% 이상 - 모델이 강하게 확신
            case 80..<150: .high // 31~58% - 명확히 구분됨 (몬스테라 120 해당)
            case 40..<80: .normal // 16~31% - 비슷한 종이 여럿 있음
            default: .low // 15% 이하 - 불확실, 재촬영 권장
            }
        }
    }
    
    let model = Model.aiyPlantsV1
    
    // 이미지 크기
    private let inputWidth = 224
    private let inputHeight = 224
    
    func analyzeImage(image: UIImage) -> String {
        guard let modelPath = model.modelPath else {
            return "모델 파일을 찾을 수 없습니다."
        }
        
        do {
            let interpreter = try Interpreter(modelPath: modelPath)
            try interpreter.allocateTensors()
            
            guard let rgbData = preprocessImage(image, width: inputWidth, height: inputHeight) else {
                return "이미지 전처리 실패"
            }
            
            try interpreter.copy(rgbData, toInputAt: 0) // 데이터를 interpreter에 전달(복사)
            try interpreter.invoke() // interpreter 실행
            
            let output = try interpreter.output(at: 0) // 추론 결과 가져오기
            let results = output.data.toArray(type: UInt8.self) // 추론 결과를 Int8 배열로 변환 - '해당 식물일 확률'의 배열
            
            if let max = results.max(),
               let maxIndex = results.firstIndex(of: max) {
                let confidence = Int((Float(max) / 255.0) * 100)
                let grade = Confidence.from(value: max)
                let plantName = "\(maxIndex)"
                
                return "\(grade.rawValue): \(confidence)% 확률로 \(plantName)입니다."
            }
        } catch {
            print("TFLite Error: \(error.localizedDescription)")
            print("Interpreter 생성 실패")
        }
        
        return ""
    }
}

extension PlantClassificationService {
    // 이미지 전처리 함수
    private func preprocessImage(_ image: UIImage, width: Int, height: Int) -> Data? {
        // 1. 비율에 맞춰 리사이징 할 크기 계산 (Aspect Fill 방식)
        let size = image.size
        let widthRatio  = CGFloat(width) / size.width
        let heightRatio = CGFloat(height) / size.height
        
        // 더 큰 비율을 선택하여 빈 공간이 생기지 않도록 함
        let scale = max(widthRatio, heightRatio)
        let newWidth  = size.width * scale
        let newHeight = size.height * scale
        
        // 2. 중앙 배치를 위한 좌표(Offset) 계산
        let x = (CGFloat(width) - newWidth) / 2.0
        let y = (CGFloat(height) - newHeight) / 2.0
        let renderRect = CGRect(x: x, y: y, width: newWidth, height: newHeight)
        
        // 3. 224x224 고정 크기의 컨텍스트 생성
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, 1.0)
        // 중앙에 맞춰서 이미지를 다시 그림 (넘치는 부분은 자동으로 잘림)
        image.draw(in: renderRect)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let resized = renderer.image { context in
            image.draw(in: renderRect)
        }
        
        guard let cgImage = resized.cgImage else {
            return nil
        }
        
        // 4. 리사이징된 이미지에서 다시 한번 비트맵 데이터 추출 (CGContext 사용)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let imageData = context.data else { return nil }
        
        var inputData = Data()
        let pointer = imageData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        for i in 0..<(width * height) {
            let offset = i * 4
            // RGB 값을 차례로 추가
            inputData.append(pointer[offset + 0]) // R
            inputData.append(pointer[offset + 1]) // G
            inputData.append(pointer[offset + 2]) // B
        }
        return inputData
    }
}

//MARK: Data 변환 익스텐션
extension Data {
    func toArray<T>(type: T.Type) -> [T] {
        return self.withUnsafeBytes { pointer in
            Array(pointer.bindMemory(to: T.self))
        }
    }
}
