//
//  ViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import RxFlow
import RxSwift
import RxCocoa
import SnapKit

/*
 RxFlow 사용 예시입니다. 추후 삭제 예정입니다.
 하단에 SecondViewController가 선언되어있습니다.
 */

class ViewController: UIViewController, Stepper {
    let steps = PublishRelay<Step>()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let pushButton = UIButton(configuration: .plain())
        pushButton.setTitle("push", for: .normal)
        
        view.addSubview(pushButton)
        
        pushButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        pushButton.rx.tap
            .map { _ in AppStep.pushButtonTapped } // push Step으로 변환
            .bind(to: steps) // VC의 steps와 바인딩 -> 버튼을 누를 때마다 'push' 스텝이 방출
            .disposed(by: disposeBag)
    }
}

class SecondViewController: UIViewController, Stepper {
    let steps = PublishRelay<Step>()
    let disposeBag = DisposeBag()
    
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
            .bind(to: steps) // VC의 steps와 바인딩 -> 버튼을 누를 때마다 'alert' 스텝이 방출
            .disposed(by: disposeBag)
        
    }
}

