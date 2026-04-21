//
//  CareRecordDBManager.swift
//  LeafLog
//
//  Created by 김주희 on 4/16/26.
//
import Foundation
import Supabase
import Dependencies

final class CareRecordDBManager {
    @Dependency(\.supabaseManager) private var supabaseManager
    
    private init() {}
    
    
    // MARK: - 특정 식물의 특정 날짜에 해당하는 관리 기록 DB에서 불러 옴 (없으면 nil)
    func fetchCareRecord(plantID: UUID, recordDate: LocalDate) async throws -> CareRecord? {
        do {
            let records: [CareRecord] = try await supabaseManager.client
                .from("care_records")
                .select()
                .eq("plant_id", value: plantID)
                .eq("record_date", value: recordDate.rawValue)
                .limit(1)
                .execute()
                .value

            return records.first
        } catch {
            throw AuthError.careFailed("식물 상태 기록을 불러오지 못했어요: \(error.localizedDescription)")
        }
    }

    // MARK: - 특정 식물의 전체 관리 기록 조회
    func fetchCareRecords(plantID: UUID) async throws -> [CareRecord] {
        do {
            return try await supabaseManager.client
                .from("care_records")
                .select()
                .eq("plant_id", value: plantID)
                .order("record_date", ascending: false)
                .execute()
                .value
        } catch {
            throw AuthError.careFailed("타임라인 기록을 불러오지 못했어요: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - 식물 관리 기록 upsert
    func upsertCareRecord(input: CareRecordUpsertInput) async throws -> CareRecord {
        do {
            let existing = try await fetchCareRecord(plantID: input.plantID, recordDate: input.recordDate)

            let payload = CareRecordPayload(
                plantID: input.plantID,
                recordDate: input.recordDate,
                recordedAt: input.recordedAt ?? existing?.recordedAt ?? Date(),
                status: input.status ?? existing?.status,
                watered: input.watered ?? existing?.watered ?? false,
                repotted: input.repotted ?? existing?.repotted ?? false,
                fertilized: input.fertilized ?? existing?.fertilized ?? false,
                treated: input.treated ?? existing?.treated ?? false,
                wateredNote: input.wateredNote ?? existing?.wateredNote,
                repottedNote: input.repottedNote ?? existing?.repottedNote,
                fertilizedNote: input.fertilizedNote ?? existing?.fertilizedNote,
                treatedNote: input.treatedNote ?? existing?.treatedNote,
                diaryText: input.diaryText ?? existing?.diaryText,
                diaryPhotoPath: input.diaryPhotoPath ?? existing?.diaryPhotoPath
            )

            return try await supabaseManager.client
                .from("care_records")
                .upsert(payload, onConflict: "plant_id,record_date") // 같은 날짜, 식물이면 
                .select()
                .single()
                .execute()
                .value
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.careFailed("식물 상태 기록을 저장하지 못했어요: \(error.localizedDescription)")
        }
    }
    
    //MARK: - 특정 기간에 해당하는 관리 기록을 DB에서 불러옴
    func fetchAllCareRecordWithin(start: Date, end: Date, plants: [UUID]) async throws -> [CareRecord] {
        do {
            let startDate = LocalDate(date: start)
            let endDate = LocalDate(date: end)
            
            guard !plants.isEmpty else { return [] }
            let plantIds = plants
                .map { "\"\($0.uuidString)\"" }
                        .joined(separator: ",")
            
            return try await supabaseManager.client
                .from("care_records")
                .select()
                .gte("record_date", value: startDate.rawValue)
                .lte("record_date", value: endDate.rawValue)
                .filter("plant_id", operator: "in", value: "(\(plantIds))")
                .execute()
                .value

        } catch {
            throw AuthError.careFailed("식물 상태 기록을 불러오지 못했어요: \(error.localizedDescription)")
        }
    }
    
    private struct CareRecordPayload: Encodable {
        let plantID: UUID
        let recordDate: LocalDate
        let recordedAt: Date?
        let status: String?
        let watered, repotted, fertilized, treated: Bool
        let wateredNote, repottedNote, fertilizedNote, treatedNote, diaryText, diaryPhotoPath: String?
        
        enum CodingKeys: String, CodingKey {
            case status, watered, repotted, fertilized, treated
            case plantID = "plant_id"
            case recordDate = "record_date"
            case recordedAt = "recorded_at"
            case wateredNote = "watered_note"
            case repottedNote = "repotted_note"
            case fertilizedNote = "fertilized_note"
            case treatedNote = "treated_note"
            case diaryText = "diary_text"
            case diaryPhotoPath = "diary_photo_path"
        }
    }
}


// MARK: - Dependencies
extension CareRecordDBManager: DependencyKey {
    static var liveValue: CareRecordDBManager { CareRecordDBManager() }
}

extension DependencyValues {
    var careRecordDBManager: CareRecordDBManager {
        get { self[CareRecordDBManager.self] }
        set { self[CareRecordDBManager.self] = newValue }
    }
}
