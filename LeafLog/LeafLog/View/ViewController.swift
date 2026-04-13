//
//  ViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import Dependencies
import RxFlow
import RxSwift
import RxCocoa
import SnapKit

/*
 RxFlow 사용 예시입니다. 추후 삭제 예정입니다.
 하단에 SecondViewController가 선언되어있습니다.
 ViewController와 SecondViewController는 BaseViewController를 상속합니다.
 */

final class ViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        let pushButton = UIButton(configuration: .plain())
//        pushButton.setTitle("push", for: .normal)
//        
//        view.addSubview(pushButton)
//        
//        pushButton.snp.makeConstraints {
//            $0.center.equalToSuperview()
//        }
//        
//        pushButton.rx.tap
//            .map { _ in AppStep.pushButtonTapped } // push Step으로 변환
//            .bind(to: steps) // VC의 steps와 바인딩 -> 버튼을 누를 때마다 'push' 스텝이 방출
//            .disposed(by: disposeBag)
        
        let title1 = TitleHeaderView(text: "", hasBackButton: true) // 백버튼만
        let title2 = TitleHeaderView(text: "", hasBackButton: false, rightButtonImage: "bell") // 오른쪽 버튼만
        let title3 = TitleHeaderView(text: "타이틀", hasBackButton: false) // 타이틀만
        let title4 = TitleHeaderView(text: "타이틀", hasBackButton: true) // 타이틀, 백버튼
        let title5 = TitleHeaderView(text: "타이틀", hasBackButton: true, rightButtonImage: "bell") // 다
        
        title4.invertColors()
        
        [title1, title2, title3, title4, title5].forEach {
            view.addSubview($0)
        }
        
        title1.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        title2.snp.makeConstraints {
            $0.top.equalTo(title1.snp.bottom).offset(5)
            $0.horizontalEdges.equalToSuperview()
        }
        title3.snp.makeConstraints {
            $0.top.equalTo(title2.snp.bottom).offset(5)
            $0.horizontalEdges.equalToSuperview()
        }
        title4.snp.makeConstraints {
            $0.top.equalTo(title3.snp.bottom).offset(5)
            $0.horizontalEdges.equalToSuperview()
        }
        title5.snp.makeConstraints {
            $0.top.equalTo(title4.snp.bottom).offset(5)
            $0.horizontalEdges.equalToSuperview()
        }
    }
}

final class SecondViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let alertButton = UIButton(configuration: .plain())
        alertButton.setTitle("Alert", for: .normal)
        
        view.addSubview(alertButton)
        
        alertButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        alertButton.rx.tap
            .map { _ in AppStep.alert("Alert", "테스트용 Alert입니다.") } // alert Step으로 변환
            .bind(to: steps) // SecondVC의 steps와 바인딩 -> 버튼을 누를 때마다 'alert' 스텝이 방출
            .disposed(by: disposeBag)
    }
}

