//
//  PlantClassificationService.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/6/26.
//

import TensorFlowLiteSwift
import UIKit
import Dependencies

class PlantClassificationService {
    //MARK: Type Deifinition
    enum Model: String {
        case aiyPlantsV1 = "aiy_plants_V1"
        
        var modelData: Data? {
            switch self {
            case .aiyPlantsV1:
                NSDataAsset(name: "model")?.data
            }
        }
        
        var labelData: Data? {
            switch self {
            case .aiyPlantsV1:
                NSDataAsset(name: "labels")?.data
            }
        }
    }
    
    enum Confidence: Int {
        case high = 0
        case normal
        case low
        case unknown
        
        static func from(value: UInt8) -> Confidence {
            switch value {
            case 120...255: .high // 47% 이상 - 명확히 구분됨 (몬스테라 120 해당)
            case 75..<120: .normal // 29~46% - 비슷한 종이 여럿 있음
            case 35..<75: .low // 14~28% - 불확실, 재촬영 권장
            default: .unknown // 알수없음
            }
        }
        
        var description: String {
            switch self {
            case .high: "높음"
            case .normal: "보통"
            case .low: "낮음"
            case .unknown: "알 수 없음"
            }
        }
    }
    
    enum ClassificationError: Error {
        case preprocessingFailed
        case inferenceFailed
        
        var title: String { "Error" }
        var message: String {
            switch self {
            case .preprocessingFailed: "이미지 전처리 작업에 실패하였습니다."
            case .inferenceFailed: "이미지 추론에 실패하였습니다."
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
        guard let modelData = model.modelData else {
            fatalError("\(model.rawValue) 모델을 불러오는 데 실패하였습니다.")
        }
        
        do {
            let interpreter = try Interpreter(modelData: modelData)
            try interpreter.allocateTensors()
            return interpreter
        } catch {
            fatalError("Interpreter 생성에 실패하였습니다.\nError: \(error.localizedDescription)")
        }
    }
    
    // labels를 가져오는 함수
    private func loadLabels() -> [String] {
        guard let labelData = model.labelData else {
            return []
        }
        
        guard let content = String(data: labelData, encoding: .utf8) else {
            fatalError("\(model.rawValue) 모델의 레이블 파일을 읽을 수 없습니다.")
        }
        
        return content.components(separatedBy: .newlines)
    }
}

//MARK: Run Model
extension PlantClassificationService {
    // 이미지 분석 함수
    func analyzeImage(image: UIImage) throws -> [String: Confidence] {
        do {
            guard let rgbData = preprocessImage(image, width: inputWidth, height: inputHeight) else {
                throw ClassificationError.preprocessingFailed
            }
            
            try interpreter.copy(rgbData, toInputAt: 0) // 데이터를 interpreter에 전달(복사)
            try interpreter.invoke() // interpreter 실행
            
            let output = try interpreter.output(at: 0) // 추론 결과 가져오기
            let inferenceResults = output.data.toArray(type: UInt8.self) // 추론 결과를 UInt8 배열로 변환 - '해당 식물일 확률'을 UInt8 타입으로 나타낸 배열

            // 추론 결과값이 가장 높은 3개
            let targets = inferenceResults.enumerated().sorted(by: {
                $0.element > $1.element
            }).prefix(3)
            
            var result: [String: Confidence] = [:]
            
            for target in targets {
                guard target.offset < labels.count else { continue
                }
                
                let name = labels[target.offset]
                let confidence = Confidence.from(value: target.element)
                
                guard confidence != .unknown else { continue }
                result[name] = confidence
            }
            
            return result
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
        
        var rgbValues: [UInt8] = []
        rgbValues.reserveCapacity(width * height * 3) // 메모리 공간 예약
        
        // R, G, B, R, G, B ... 순서의 데이터 배열 만들기
        for i in 0..<(width * height) {
            let offset = i * 4 // CGContext 는 1픽셀을 나타낼 때 4바이트를 사용 - RGBA 순서
            
            // RGB 값을 차례로 추가 - Alpha값은 없으므로 offset + 3은 사용하지 않음
            rgbValues.append(pointer[offset + 0]) // R
            rgbValues.append(pointer[offset + 1]) // G
            rgbValues.append(pointer[offset + 2]) // B
        }
        
        return Data(rgbValues)
    }
}

// MARK: Added - Capture Image Crop & Preprocess
extension PlantClassificationService {
    // 모델 입력용 데이터로 전처리
    func preprocessCapturedImageData(
        _ imageData: Data,
        normalizedRect: CGRect
    ) -> Data? {
        guard let croppedImage = cropCapturedImage(imageData, normalizedRect: normalizedRect) else {
            return nil
        }

        return preprocessImage(croppedImage, width: inputWidth, height: inputHeight)
    }
    
    // normalized rect 기준으로 캡처 데이터에서 guideFrame 영역만 잘라낸 이미지를 반환
    func cropCapturedImage(
        _ imageData: Data,
        normalizedRect: CGRect
    ) -> UIImage? {
        guard let image = UIImage(data: imageData) else { return nil }
        guard !normalizedRect.isEmpty else { return image }

        // capturePhoto로 얻은 UIImage는 데이터가 나타내느 방향(orientation)과 실제 cgImage 픽셀 방향이 다를 수 있음
        // 캡처 이미지의 사이즈만큼 세로 캔버스에 다시 그려서 crop 좌표 계산을 "사용자가 보는 방향"으로 맞춤
        let orientedSize = image.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        let orientedImage = UIGraphicsImageRenderer(size: orientedSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: orientedSize))
        }

        guard let cgImage = orientedImage.cgImage else {
            return image
        }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

        // normalized rect는 프리뷰 좌표계를 기준으로 축이 바뀐 형태
        // -> 세로 이미지 기준 crop에서는 x/y와 width/height를 서로 바꿔 적용해야 guideFrame에 보였던 정사각형 영역과 같은 크기로 잘림
        let cropRect = CGRect(
            x: normalizedRect.minY * imageSize.width,
            y: normalizedRect.minX * imageSize.height,
            width: normalizedRect.height * imageSize.width,
            height: normalizedRect.width * imageSize.height
        ).intersection(CGRect(origin: .zero, size: imageSize))


        guard !cropRect.isEmpty,
              let croppedCGImage = cgImage.cropping(to: cropRect.integral) else {
            return orientedImage
        }

        return UIImage(cgImage: croppedCGImage)
    }

    // UIImage의 방향을 실제 픽셀에 반영하여 crop 좌표 계산이 어긋나지 않도록 정방향 이미지로 다시 그림
    private func normalizedImage(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return image }

        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: pixelSize, format: format).image { _ in
            UIImage(cgImage: cgImage, scale: 1, orientation: image.imageOrientation)
                .draw(in: CGRect(origin: .zero, size: pixelSize))
        }
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
