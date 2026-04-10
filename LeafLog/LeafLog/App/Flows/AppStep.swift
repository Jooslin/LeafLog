//
//  AppStep.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/5/26.
//

import RxFlow

/*
 - Step: 각 Step은 '앱의 네비게이션 상태(state)'를 의미합니다.
    -> "이 화면으로 가고싶어"라는 뜻이라기 보다는, "누군가 혹은 어떤 것이 이 동작을 했다"라는 의미로 보는 것이 적절합니다.
    -> "누군가 혹은 어떤 것이 이 동작을 했다"라는 state가 전달되면, RxFlow는 현재의 네비게이션 Flow에 알맞은 화면을 선택합니다.
    -> (저는 화면 전환의 트리거라고 이해했습니다.)
 
 필요하신 Step 아래에 추가하셔서 사용 부탁드립니다.
 */

enum AppStep: Step {
    // Main
    case root
    case splash
    case loginRequired
    case main
    
    // Tab
    case plantTab
    case calendarTab
    case myInfoTab
    
    // Global
    case alert(String, String) // (타이틀, 메세지)
    
    // 예시용
    case pushButtonTapped
}
