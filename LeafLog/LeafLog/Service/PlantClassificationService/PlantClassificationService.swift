//
//  PlantClassificationService.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/6/26.
//

import TensorFlowLite
import UIKit
import Dependencies

class PlantClassificationService {
    //MARK: Type Deifinition
    enum Model: String {
        case aiyPlantsV1 = "aiy_plants_V1"
        
        var modelPath: String? {
            switch self {
            case .aiyPlantsV1:
                Bundle.main.path(forResource: "3", ofType: "tflite")
            }
        }
        
        var labelPath: String? {
            switch self {
            case .aiyPlantsV1:
                Bundle.main.path(forResource: "aiy_plants_V1_labels", ofType: "txt")
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
    
    enum ClassificationError: Error {
        case preprocessingFailed
        case inferenceFailed
        
        var title: String { "Error" }
        var message: String {
            switch self {
            case .preprocessingFailed: "이미지 전처리 실패"
            case .inferenceFailed: "모델 실행 실패"
            }
        }
    }
    
    //MARK: Properties
    private lazy var interpreter: Interpreter = createInterpreter()
    private let model = Model.aiyPlantsV1
    private lazy var labels = loadLabels()
    
    // 분석 대상의 필요 이미지 크기
    private let inputWidth = 224
    private let inputHeight = 224
    
    //MARK: Initial Setting Functions
    // interpreter 생성 함수
    private func createInterpreter() -> Interpreter {
        guard let modelPath = model.modelPath else {
            fatalError("\(model.rawValue) 모델을 불러오는 데 실패하였습니다.")
        }
        do {
            let interpreter = try Interpreter(modelPath: modelPath)
            try interpreter.allocateTensors()
            return interpreter
        } catch {
            fatalError("Interpreter 생성에 실패하였습니다.\nError: \(error.localizedDescription)")
        }
    }
    
    // labels를 가져오는 함수
    private func loadLabels() -> [String] {
        guard let labelPath = model.labelPath else {
            return []
        }
        
        do {
            let content = try String(contentsOfFile: labelPath, encoding: .utf8)
            return content.components(separatedBy: .newlines)
        } catch {
            fatalError("\(model.rawValue) 모델의 레이블 파일을 읽을 수 없습니다.")
        }
    }
}

//MARK: Run Model
extension PlantClassificationService {
    // 이미지 분석 함수
    func analyzeImage(image: UIImage) throws -> (Confidence, String) {
        do {
            guard let rgbData = preprocessImage(image, width: inputWidth, height: inputHeight) else {
                throw ClassificationError.preprocessingFailed
            }
            
            try interpreter.copy(rgbData, toInputAt: 0) // 데이터를 interpreter에 전달(복사)
            try interpreter.invoke() // interpreter 실행
            
            let output = try interpreter.output(at: 0) // 추론 결과 가져오기
            let results = output.data.toArray(type: UInt8.self) // 추론 결과를 Int8 배열로 변환 - '해당 식물일 확률'의 배열
            
            if let max = results.max(),
               let maxIndex = results.firstIndex(of: max) {
                let grade = Confidence.from(value: max)
                
                guard maxIndex < labels.count else {
                    return (.low, "Unknown")
                }
                
                return (grade, labels[maxIndex])
            } else {
                return (.low, "Unknown")
            }
        } catch {
            throw ClassificationError.inferenceFailed
        }
    }
}

//MARK: Preprocess to run model
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
        
        // 3. 224x224 고정 크기의 이미지 생성
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let resized = renderer.image { context in
            image.draw(in: renderRect) // 중앙에 맞춰서 이미지를 다시 그림 (224x224 크기에서 넘치는 부분은 자동으로 잘림)
        }
        
        guard let cgImage = resized.cgImage else {
            return nil
        }
        
        // 4. 리사이징된 이미지에서 다시 한번 비트맵 데이터 추출 (CGContext 사용)
        // UIImage는 많은 정보를 담고 있어서 RGB 데이터만 가져올 수 없음 - CGContext를 활용하여 RGB값만을 추출
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4, // 1 픽셀을 나타낼 때 4바이트를 사용
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let imageData = context.data else { return nil }
        
        let pointer = imageData.bindMemory(to: UInt8.self, capacity: width * height * 4) // imageData를 1바이트 단위로 나누기
        
        // R, G, B, R, G, B ... 순서의 데이터 배열 만들기
        let inputData = (0..<(width * height)).reduce(into: Data()) { data, i in
            let offset = i * 4 // CGContext 는 1픽셀을 나타낼 때 4바이트를 사용 - RGBA 순서
            
            // RGB 값을 차례로 추가 - Alpha값은 없으므로 offset + 3은 사용하지 않음
            data.append(pointer[offset + 0]) // R
            data.append(pointer[offset + 1]) // G
            data.append(pointer[offset + 2]) // B
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

//MARK: Dependencies
extension PlantClassificationService: DependencyKey {
    static var liveValue: PlantClassificationService {
        PlantClassificationService()
    }
}

extension DependencyValues {
    var plantClassificationService: PlantClassificationService {
        get { self[PlantClassificationService.self] }
        set { self[PlantClassificationService.self] = newValue }
    }
}
