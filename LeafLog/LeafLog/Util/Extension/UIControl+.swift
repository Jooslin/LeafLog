//
//  UIControl+.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/21/26.
//

import RxCocoa
import RxSwift
import UIKit

extension Reactive where Base: UIControl {
    var tap: ControlEvent<Void> {
        controlEvent(.touchUpInside)
    }
}
