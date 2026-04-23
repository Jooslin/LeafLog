//
//  AppNotification.swift
//  LeafLog
//
//  Created by OpenAI Codex on 4/23/26.
//

import Foundation

enum AppNotificationCategory: String, Codable {
    case management
    case community
}

enum AppNotificationType: String, Codable {
    case general
    case wateringReminder = "watering_reminder"
    case unknown

    init(rawValue: String) {
        switch rawValue {
        case "general":
            self = .general
        case "watering_reminder":
            self = .wateringReminder
        default:
            self = .unknown
        }
    }
}

struct AppNotificationMetadata: Codable, Hashable {
    let plantIDs: [UUID]
    let plantNames: [String]
    let primaryPlantName: String?
    let plantCount: Int?
    let notificationDate: LocalDate?

    enum CodingKeys: String, CodingKey {
        case plantIDs = "plant_ids"
        case plantNames = "plant_names"
        case primaryPlantName = "primary_plant_name"
        case plantCount = "plant_count"
        case notificationDate = "notification_date"
    }
}

struct AppNotification: Codable, Hashable {
    let id: UUID
    let userID: UUID
    let title: String
    let body: String
    let category: AppNotificationCategory
    let type: AppNotificationType
    let metadata: AppNotificationMetadata
    let readAt: Date?
    let notificationDate: LocalDate?
    let sentAt: Date?
    let createdAt: Date

    var isRead: Bool {
        readAt != nil
    }

    // 알림센터 셀이나 상세 화면에서 바로 쓸 수 있도록 식물명을 쉼표 형태로 묶어 제공한다.
    var plantNamesText: String? {
        guard !metadata.plantNames.isEmpty else { return nil }
        return metadata.plantNames.joined(separator: ", ")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case title
        case body
        case category
        case type
        case metadata
        case readAt = "read_at"
        case notificationDate = "notification_date"
        case sentAt = "sent_at"
        case createdAt = "created_at"
    }

    init(
        id: UUID,
        userID: UUID,
        title: String,
        body: String,
        category: AppNotificationCategory,
        type: AppNotificationType,
        metadata: AppNotificationMetadata,
        readAt: Date?,
        notificationDate: LocalDate?,
        sentAt: Date?,
        createdAt: Date
    ) {
        self.id = id
        self.userID = userID
        self.title = title
        self.body = body
        self.category = category
        self.type = type
        self.metadata = metadata
        self.readAt = readAt
        self.notificationDate = notificationDate
        self.sentAt = sentAt
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        userID = try container.decode(UUID.self, forKey: .userID)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        category = try container.decode(AppNotificationCategory.self, forKey: .category)

        let typeRawValue = try container.decode(String.self, forKey: .type)
        type = AppNotificationType(rawValue: typeRawValue)

        metadata = try container.decodeIfPresent(AppNotificationMetadata.self, forKey: .metadata)
            ?? AppNotificationMetadata(
                plantIDs: [],
                plantNames: [],
                primaryPlantName: nil,
                plantCount: nil,
                notificationDate: nil
            )

        readAt = try container.decodeIfPresent(Date.self, forKey: .readAt)
        notificationDate = try container.decodeIfPresent(LocalDate.self, forKey: .notificationDate)
        sentAt = try container.decodeIfPresent(Date.self, forKey: .sentAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
