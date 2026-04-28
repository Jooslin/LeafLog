//
//  BaseViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/6/26.
//

import RxFlow
import RxRelay
import RxSwift
import UIKit
import RxCocoa

class BaseViewController: UIViewController, Stepper {
    let steps = PublishRelay<Step>()
    var disposeBag = DisposeBag()
    private let minimumContentSizeCategory: UIContentSizeCategory = .large
    private let maximumContentSizeCategory: UIContentSizeCategory = .accessibilityLarge
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //다이나믹 폰트 최대,최소크기 설정
        view.minimumContentSizeCategory = minimumContentSizeCategory
        view.maximumContentSizeCategory = maximumContentSizeCategory
        
        // 네비게이션 바가 숨겨져도 스와이프로 뒤로 가기가 가능하도록 설정
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 화면이 나타날 때마다 네비게이션 바를 숨김
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // 키보드 내리기
    func setKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        tapGesture.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
    }
}
