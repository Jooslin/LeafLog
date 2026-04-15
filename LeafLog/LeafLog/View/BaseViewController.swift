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

class BaseViewController: UIViewController, Stepper {
    let steps = PublishRelay<Step>()
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
    }
}
