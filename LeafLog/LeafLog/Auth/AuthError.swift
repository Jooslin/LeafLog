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

    /// 회원탈퇴 처리 중 실패했을 때
    case withdrawalFailed(String)
}
