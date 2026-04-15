//
//  CameraError.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/15/26.
//

enum CameraError: Error {
    case authorizationDenied
    case sessionSettingFailed
    
    var title: String { "Error" }
    var message: String {
        switch self {
        case .authorizationDenied:
            "카메라 권한이 거절되었습니다."
        case .sessionSettingFailed:
            "카메라 세팅에 실패했습니다."
        }
    }
}

