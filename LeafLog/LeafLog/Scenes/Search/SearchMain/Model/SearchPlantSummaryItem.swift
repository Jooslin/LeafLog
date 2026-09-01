//
//  SearchPlantSummaryItem.swift
//  LeafLog
//
//  Created by Yeseul Jang on 9/1/26.
//

import Foundation

struct SearchPlantSummaryItem {
    let contentNumber: String
    let name: String
    let imageURL: String?
    let thumbnailURL: String?
    let confidence: PlantClassificationService.Confidence
    let primaryThumbnailURL: String?
    let primaryImageURL: String?
    let displayThumbnailURL: String?
}
