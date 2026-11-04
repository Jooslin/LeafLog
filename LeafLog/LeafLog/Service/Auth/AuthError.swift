//
//  AuthError.swift
//  LeafLog
//
//  Created by 김주희 on 4/7/26.
//

import Foundation

enum AuthError: Error {
    /// 로그인 과정 자체에서 실패했을 때 (카카오/구글 SDK 에러 등)
    case loginFailed(String)

    /// 사용자가 로그인 취소하였을때
    case cancelled

    /// 로그인 후 앱으로 돌아오는 URL Scheme이 잘못되었을 때
    case invalidCallbackURL

    /// 로그인은 성공했지만 Supabase 서버에 세션을 만들거나 유저 정보를 가져오는데 실패했을 때
    case sessionFailed(String)

    /// 로그인은 성공했지만 사용자 프로필을 준비하지 못했을 때
    case profileFailed(String)

    /// 식물 관련 저장/조회 작업이 실패했을 때
    case plantFailed(String)

    /// 식물 관리 기록 저장/조회 작업이 실패했을 때
    case careFailed(String)

    /// 알림 목록 저장/조회 작업이 실패했을 때
    case notificationFailed(String)

    /// 커뮤니티 게시글 저장/조회 작업이 실패했을 때
    case communityFailed(String)

    /// 압축된 이미지가 업로드 용량 제한을 초과했을 때
    case imageSizeLimitExceeded

    /// 회원탈퇴 처리 중 실패했을 때
    case withdrawalFailed(String)
}

extension AuthError {
    var userMessage: String {
        switch self {
        case .loginFailed(let message),
             .sessionFailed(let message),
             .profileFailed(let message),
             .plantFailed(let message),
             .careFailed(let message),
             .notificationFailed(let message),
             .communityFailed(let message),
             .withdrawalFailed(let message):
            return message
        case .imageSizeLimitExceeded:
            return "대용량 이미지는 등록할 수 없습니다. 사진의 크기를 줄이거나 다른 사진을 업로드 해주세요."
        case .cancelled:
            return "작업이 취소되었습니다."
        case .invalidCallbackURL:
            return "잘못된 로그인 URL입니다."
        }
    }
}
