//
//  SearchListItem.swift
//  LeafLog
//
//  Created by Yeseul Jang on 9/1/26.
//

import Foundation

nonisolated enum SearchListItem: Hashable, Sendable {
    case plant(String)
    case empty(String)
    case bottomGuide
}
