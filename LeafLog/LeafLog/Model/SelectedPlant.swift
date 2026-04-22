//
//  SelectedPlant.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/20/26.
//

import Foundation

struct SelectedPlant: Equatable {
    let name: String
    let contentNumber: String?
    let detail: PlantDetail?
    let category: PlantCategory?

    static let other = SelectedPlant(
        name: "기타",
        contentNumber: nil,
        detail: nil,
        category: .other
    )
}
