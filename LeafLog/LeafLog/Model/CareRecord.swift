//
//  CareRecord.swift
//  LeafLog
//
//  Created by 김주희 on 4/16/26.
//

import Foundation

// MARK: - LocalDate
struct LocalDate: RawRepresentable, Codable, Hashable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(date: Date) {
        self.rawValue = Self.formatter.string(from: date)
    }

    var date: Date? {
        Self.formatter.date(from: rawValue)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

// MARK: - Models
//  DB에서 가져온 데이터 저장
struct CareRecord: Codable {
    let id: UUID
    let plantID: UUID
    let recordedAt: Date
    let status: String?
    let watered, repotted, fertilized, treated: Bool
    let createdAt, updatedAt: Date
    let recordDate: LocalDate
    let wateredNote, repottedNote, fertilizedNote, treatedNote, diaryText, diaryPhotoPath: String?

    enum CodingKeys: String, CodingKey {
        case id, status, watered, repotted, fertilized, treated
        case plantID = "plant_id"
        case recordedAt = "recorded_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case recordDate = "record_date"
        case wateredNote = "watered_note"
        case repottedNote = "repotted_note"
        case fertilizedNote = "fertilized_note"
        case treatedNote = "treated_note"
        case diaryText = "diary_text"
        case diaryPhotoPath = "diary_photo_path"
    }
}

// 앱 -> DB에 보낼 데이터
struct CareRecordUpsertInput {
    let plantID: UUID
    let recordDate: LocalDate
    var recordedAt: Date?
    var status: String?
    var watered, repotted, fertilized, treated: Bool?
    var wateredNote, repottedNote, fertilizedNote, treatedNote: String?
    var diaryText, diaryPhotoPath: String?
    var clearsDiaryPhotoPath = false
}
