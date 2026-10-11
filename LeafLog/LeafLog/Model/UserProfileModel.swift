//
//  UserProfileModel.swift
//  LeafLog
//
//  Created by 김주희 on 4/9/26.
//

import Foundation

struct UserProfileModel: Codable {
    let id: UUID
    let nickname: String
    let email: String?
    let provider: String
    let profileImageURL: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case email
        case provider
        case profileImageURL = "profile_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
