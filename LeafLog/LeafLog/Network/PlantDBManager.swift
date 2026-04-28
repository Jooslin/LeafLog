//
//  PlantDBManager.swift
//  LeafLog
//
//  Created by OpenAI Codex on 4/13/26.
//
import Foundation
import Supabase
import Dependencies
import OSLog

final class PlantDBManager {
    @Dependency(\.supabaseManager) private var supabaseManager
    private static let defaultSpeciesName = "익명의 식물"
    private let logger = Logger(subsystem: "LeafLog", category: "PlantDBManager")
    
    
    private init() {}
    
    // MARK: 현재 로그인한 사용자가 등록한 식물 목록 조회
    func fetchMyPlants() async throws -> [MyPlant] {
        let user = try await supabaseManager.client.auth.user()
        
        do {
            return try await supabaseManager.client
                .from("plants")
                .select()
                .eq("user_id", value: user.id)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            throw AuthError.plantFailed("등록한 식물 목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요.")
        }
    }
    
    // MARK: 현재 로그인한 사용자의 특정 식물 조회
    func fetchPlant(plantID: UUID) async throws -> MyPlant {
        let user = try await supabaseManager.client.auth.user()
        
        do {
            return try await supabaseManager.client
                .from("plants")
                .select()
                .eq("id", value: plantID)
                .eq("user_id", value: user.id)
                .single()
                .execute()
                .value
        } catch {
            logger.error("fetchPlant failed. plantID: \(plantID.uuidString, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            
            throw AuthError.plantFailed("식물 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.")
        }
    }
    
    // MARK: - DB의 plants 테이블에 새 레코드를 Insert
    func createPlant(plantID: UUID, userID: UUID, imagePath: String?, input: PlantCreateInput) async throws -> MyPlant {
        
        // 유효성 검사: DB 제약조건(>= 1 and <= 365)
        guard (1...365).contains(input.wateringIntervalDays) else {
            throw AuthError.plantFailed("급수 주기는 1일 이상 365일 이하로 입력해 주세요.")
        }
        
        // 공백, nil값 보정
        let trimmedSpeciesName = input.speciesName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let speciesName = (trimmedSpeciesName?.isEmpty ?? true)
        ? Self.defaultSpeciesName
        : trimmedSpeciesName ?? Self.defaultSpeciesName
        
        let payload = PlantPayload(
            id: plantID,
            userID: userID,
            category: input.category.rawValue,
            location: input.location?.rawValue,
            nickname: input.nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            speciesName: speciesName,
            contentNumber: input.contentNumber,
            imagePath: imagePath,
            wateringIntervalDays: input.wateringIntervalDays,
            lastWateredAt: input.lastWateredAt
        )
        
        // Supabase Insert 실행 후 생성된 데이터를 모델로 바로 디코딩
        let response = try await supabaseManager.client
            .from("plants")
            .insert(payload)
            .select() // 생성된 전체 로우 데이터를 반환받음
            .single()
            .execute()
        
        // 커스텀 디코더(날짜 처리 등)가 설정된 client.database.configuration.decoder 사용 권장
        do {
            return try supabaseManager.client.database.configuration.decoder.decode(MyPlant.self, from: response.data)
        } catch {
            throw AuthError.plantFailed("식물 정보 등록에는 성공했으나, 데이터를 불러오는 데 실패했습니다.")
        }
    }
    
    func updateLastWateredAt(plantID: UUID, date: Date) async throws {
        struct Payload: Encodable {
            let lastWateredAt: Date
            
            enum CodingKeys: String, CodingKey {
                case lastWateredAt = "last_watered_at"
            }
        }
        
        try await supabaseManager.client
            .from("plants")
            .update(Payload(lastWateredAt: date))
            .eq("id", value: plantID)
            .execute()
    }
    
    // MARK: - Payload Model
    /// Supabase Insert 전용 구조체 (요청용)
    private struct PlantPayload: Encodable {
        let id: UUID
        let userID: UUID
        let category: String
        let location: String?
        let nickname: String
        let speciesName: String
        let contentNumber: String?
        let imagePath: String?
        let wateringIntervalDays: Int
        let lastWateredAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case userID = "user_id"
            case category
            case location
            case nickname
            case speciesName = "species_name"
            case contentNumber
            case imagePath = "image_path"
            case wateringIntervalDays = "watering_interval_days"
            case lastWateredAt = "last_watered_at"
        }
    }
    
    
    // MARK: - DB의 plants 테이블에 기존 레코드를 Update
    func updatePlant(plantID: UUID, imagePath: String?, input: PlantUpdateInput) async throws -> MyPlant {
        
        // 유효성 검사
        guard (1...365).contains(input.wateringIntervalDays) else {
            throw AuthError.plantFailed("급수 주기는 1일 이상 365일 이하로 입력해 주세요.")
        }
        
        // 공백, nil값 보정
        let trimmedSpeciesName = input.speciesName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let speciesName = (trimmedSpeciesName?.isEmpty ?? true) ? Self.defaultSpeciesName : trimmedSpeciesName ?? Self.defaultSpeciesName
        
        // 업데이트용 페이로드 생성
        let payload = PlantUpdatePayload(
            category: input.category.rawValue,
            location: input.location?.rawValue,
            nickname: input.nickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            speciesName: speciesName,
            contentNumber: input.contentNumber,
            imagePath: imagePath,
            wateringIntervalDays: input.wateringIntervalDays,
            lastWateredAt: input.lastWateredAt
        )
        
        // Supabase Update 실행
        let response = try await supabaseManager.client
            .from("plants")
            .update(payload)
            .eq("id", value: plantID) // 수정할 식물의 ID
            .select()
            .single()
            .execute()
        
        do {
            return try supabaseManager.client.database.configuration.decoder.decode(MyPlant.self, from: response.data)
        } catch {
            throw AuthError.plantFailed("식물 정보 수정에는 성공했으나, 데이터를 불러오는 데 실패했습니다.")
        }
    }
    
    // MARK: - 가이드 표시 여부 업데이트
    func updateGuideEnabled(plantID: UUID, isEnabled: Bool) async throws -> MyPlant {
        let user = try await supabaseManager.client.auth.user()
        let payload = GuideEnabledUpdatePayload(guideEnabled: isEnabled)
        
        let response = try await supabaseManager.client
            .from("plants")
            .update(payload)
            .eq("id", value: plantID)
            .eq("user_id", value: user.id)
            .select()
            .single()
            .execute()
        
        do {
            return try supabaseManager.client.database.configuration.decoder.decode(MyPlant.self, from: response.data)
        } catch {
            throw AuthError.plantFailed("가이드 설정은 변경했으나, 식물 정보를 불러오는 데 실패했습니다.")
        }
    }

    // MARK: - 식물 건강 상태 업데이트
    func updateHealthStatus(plantID: UUID, healthStatus: String) async throws -> MyPlant {
        let user = try await supabaseManager.client.auth.user()
        let payload = HealthStatusUpdatePayload(healthStatus: healthStatus)

        let response = try await supabaseManager.client
            .from("plants")
            .update(payload)
            .eq("id", value: plantID)
            .eq("user_id", value: user.id)
            .select()
            .single()
            .execute()

        do {
            return try supabaseManager.client.database.configuration.decoder.decode(MyPlant.self, from: response.data)
        } catch {
            throw AuthError.plantFailed("식물 상태는 변경했으나, 식물 정보를 불러오는 데 실패했습니다.")
        }
    }
    
    
    // MARK: - Update Payload Model
    /// Supabase Update 전용 구조체 (id, user_id 제외)
    private struct PlantUpdatePayload: Encodable {
        let category: String
        let location: String?
        let nickname: String
        let speciesName: String
        let contentNumber: String?
        let imagePath: String?
        let wateringIntervalDays: Int
        let lastWateredAt: Date
        
        enum CodingKeys: String, CodingKey {
            case category
            case location
            case nickname
            case speciesName = "species_name"
            case contentNumber
            case imagePath = "image_path"
            case wateringIntervalDays = "watering_interval_days"
            case lastWateredAt = "last_watered_at"
        }
    }
    
    private struct GuideEnabledUpdatePayload: Encodable {
        let guideEnabled: Bool
        
        enum CodingKeys: String, CodingKey {
            case guideEnabled = "guide_enabled"
        }
    }

    private struct HealthStatusUpdatePayload: Encodable {
        let healthStatus: String

        enum CodingKeys: String, CodingKey {
            case healthStatus = "health_status"
        }
    }
    
    // MARK: - DB의 plants 테이블에서 특정 식물 레코드를 삭제
    func deletePlant(plantID: UUID) async throws {
        try await supabaseManager.client
            .from("plants")
            .delete() // 삭제 명령어
            .eq("id", value: plantID) // 삭제할 식물의 ID
            .execute()
    }
}



// MARK: - Dependencies
extension PlantDBManager: DependencyKey {
    static var liveValue: PlantDBManager { PlantDBManager() }
}

extension DependencyValues {
    var plantDBManager: PlantDBManager {
        get { self[PlantDBManager.self] }
        set { self[PlantDBManager.self] = newValue }
    }
}
