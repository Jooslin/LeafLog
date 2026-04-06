//
//  ViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import RxFlow
import RxRelay

class ViewController: UIViewController, Stepper {
    let steps = PublishRelay<Step>()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

