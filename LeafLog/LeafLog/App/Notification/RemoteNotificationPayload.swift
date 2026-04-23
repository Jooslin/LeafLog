//
//  RemoteNotificationPayload.swift
//  LeafLog
//
//  Created by OpenAI Codex on 4/23/26.
//

import Foundation

enum RemoteNotificationCategory: String, Codable {
    case management
    case community
}

struct WateringReminderNotificationMetadata: Codable, Equatable {
    let plantIDs: [String]
    let plantNames: [String]
    let primaryPlantName: String
    let plantCount: Int
    let notificationDate: String

    enum CodingKeys: String, CodingKey {
        case plantIDs = "plant_ids"
        case plantNames = "plant_names"
        case primaryPlantName = "primary_plant_name"
        case plantCount = "plant_count"
        case notificationDate = "notification_date"
    }
}

struct RemoteNotificationPayload: Equatable {
    let notificationID: String
    let title: String
    let body: String
    let category: RemoteNotificationCategory
    let type: String
    let rawMetadata: String?
    let wateringReminder: WateringReminderNotificationMetadata?

    static func from(
        userInfo: [AnyHashable: Any],
        fallbackTitle: String? = nil,
        fallbackBody: String? = nil
    ) -> RemoteNotificationPayload? {
        // 서버가 내려준 식별자와 타입을 기준으로 알림 payload를 복원한다.
        guard
            let notificationID = userInfo["notification_id"] as? String,
            let type = userInfo["type"] as? String
        else {
            return nil
        }

        let category = RemoteNotificationCategory(rawValue: (userInfo["category"] as? String) ?? "") ?? .management
        let rawMetadata = userInfo["metadata"] as? String
        let wateringReminder = decodeWateringReminderMetadata(rawMetadata, type: type)

        return RemoteNotificationPayload(
            notificationID: notificationID,
            title: fallbackTitle ?? apsAlertValue(in: userInfo, key: "title") ?? "LeafLog",
            body: fallbackBody ?? apsAlertValue(in: userInfo, key: "body") ?? "",
            category: category,
            type: type,
            rawMetadata: rawMetadata,
            wateringReminder: wateringReminder
        )
    }

    private static func decodeWateringReminderMetadata(
        _ rawMetadata: String?,
        type: String
    ) -> WateringReminderNotificationMetadata? {
        // 물주기 알림만 구조화된 식물 목록 metadata를 가진다.
        guard type == "watering_reminder", let rawMetadata else { return nil }
        guard let data = rawMetadata.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WateringReminderNotificationMetadata.self, from: data)
    }

    private static func apsAlertValue(in userInfo: [AnyHashable: Any], key: String) -> String? {
        guard let aps = userInfo["aps"] as? [String: Any] else { return nil }
        guard let alert = aps["alert"] as? [String: Any] else { return nil }
        return alert[key] as? String
    }
}

extension Notification.Name {
    static let leafLogDidOpenRemoteNotification = Notification.Name("leafLogDidOpenRemoteNotification")
}
