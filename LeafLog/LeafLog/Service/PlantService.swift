//
//  PlantService.swift
//  LeafLog
//
//  Created by OpenAI Codex on 4/13/26.
//

import UIKit
import Dependencies
import Auth
import Supabase
import OSLog

// MARK: - PlantService

/// 식물 등록, 수정 및 삭제 흐름을 조율하는 서비스
/// - 이미지 업로드(Storage) → DB 저장(PlantDBManager) 순서로 실행
/// - ViewController 사용 예시:
///   ```swift
///   @Dependency(\.plantService) var plantService
///
///   let plant = try await plantService.registerPlant(input: input)
///   ```

final class PlantService {
    
    @Dependency(\.supabaseManager) private var supabaseManager
    @Dependency(\.plantDBManager) private var plantDBManager
    @Dependency(\.careRecordDBManager) private var careRecordDBManager
    
    private let logger = Logger(subsystem: "LeafLog", category: "PlantService")
    
    private init() {}
    
    // MARK: - 식물 등록하고 저장된 MyPlant 반환
    func registerPlant(input: PlantCreateInput) async throws -> MyPlant {
        let plantID = input.id
        let user = try await supabaseManager.client.auth.user()
        
        // 이미지 업로드 (있을 경우에만)
        var uploadedImagePath: String? = nil
        if let image = input.image {
            uploadedImagePath = try await supabaseManager.uploadPlantImage(image, userID: user.id, plantID: plantID)
        }
        
        
        let plant = try await plantDBManager.createPlant(
            plantID: plantID,
            userID: user.id,
            imagePath: uploadedImagePath,
            input: input
        )

        _ = try await careRecordDBManager.upsertCareRecord(
            input: CareRecordUpsertInput(
                plantID: plant.id,
                recordDate: Self.localDate(from: input.lastWateredAt),
                recordedAt: input.lastWateredAt,
                status: nil,
                watered: true,
                repotted: nil,
                fertilized: nil,
                treated: nil,
                wateredNote: nil,
                repottedNote: nil,
                fertilizedNote: nil,
                treatedNote: nil,
                diaryText: nil,
                diaryPhotoPath: nil
            )
        )

        return plant
    }
    
    
    // MARK: - 식물 정보 수정하고 업데이트된 MyPlant 반환
    func updatePlant(input: PlantUpdateInput) async throws -> MyPlant {
        let plantID = input.id
        let user = try await supabaseManager.client.auth.user()
        
        // 최종적으로 DB에 저장될 이미지 경로 (기본값은 기존 이미지 경로)
        var finalImagePath: String? = input.existingImagePath
        
        // 사용자가 새로운 이미지를 선택한 경우에만 Storage에 새 이미지 업로드
        if let newImage = input.image {
            // 새 이미지를 업로드하고 반환된 경로로 덮어씌움
            finalImagePath = try await supabaseManager.uploadPlantImage(newImage, userID: user.id, plantID: plantID)
        }
        
        // DB 업데이트
        return try await plantDBManager.updatePlant(
            plantID: plantID,
            imagePath: finalImagePath,
            input: input
        )
    }
    
    // MARK: - 등록된 식물 삭제
    func deletePlant(plantID: UUID, imagePath: String?) async throws {
        
        // DB에서 이미지 삭제
        if let imagePath = imagePath, !imagePath.isEmpty {
            do {
                try await supabaseManager.deletePlantImage(path: imagePath)
            } catch {
                logger.error("식물 이미지 삭제 실패 - plantID: \(plantID.uuidString, privacy: .public), path: \(imagePath, privacy: .public)")
            }
        }
        // DB에서 식물 데이터 삭제
        try await plantDBManager.deletePlant(plantID: plantID)
    }
}


// MARK: - Dependencies
extension PlantService: DependencyKey {
    static var liveValue: PlantService {
        PlantService()
    }
}

extension DependencyValues {
    var plantService: PlantService {
        get { self[PlantService.self] }
        set { self[PlantService.self] = newValue }
    }
}
