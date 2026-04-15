//
//  PlantRegistrationService.swift
//  LeafLog
//
//  Created by OpenAI Codex on 4/13/26.
//

import UIKit
import Dependencies
import Auth
import Supabase

// MARK: - PlantRegistrationService
 
/// 식물 등록 흐름을 조율하는 서비스
/// - 이미지 업로드(Storage) → DB 저장(PlantDBManager) 순서로 실행
/// - ViewController 사용 예시:
///   ```swift
///   @Dependency(\.plantRegistrationService) var registrationService
///
///   let plant = try await registrationService.registerPlant(input: input)
///   ```

final class PlantRegistrationService {

    @Dependency(\.supabaseManager) private var supabaseManager
    @Dependency(\.plantDBManager) private var plantDBManager

    private init() {}

    // 식물 등록하고 저장된 MyPlant 반환
    func registerPlant(input: PlantCreateInput) async throws -> MyPlant {
        let plantID = input.id
        let user = try await supabaseManager.client.auth.user()

        // 이미지 업로드 (있을 경우에만)
        var uploadedImagePath: String? = nil
        if let image = input.image {
            uploadedImagePath = try await supabaseManager.uploadPlantImage(image, userID: user.id, plantID: plantID)
        }
        
        
        return try await plantDBManager.createPlant(
                plantID: plantID,
                userID: user.id,
                imagePath: uploadedImagePath,
                input: input
            )
    }
}


// MARK: - Dependencies
extension PlantRegistrationService: DependencyKey {
    static var liveValue: PlantRegistrationService {
        PlantRegistrationService()
    }
}

extension DependencyValues {
    var plantRegistrationService: PlantRegistrationService {
        get { self[PlantRegistrationService.self] }
        set { self[PlantRegistrationService.self] = newValue }
    }
}
