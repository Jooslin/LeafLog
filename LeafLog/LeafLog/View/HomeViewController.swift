//
//  HomeViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import ReactorKit

final class HomeViewController: BaseViewController {
    private let homeView = HomeView()
    
    override func loadView() {
        view = homeView
    }
}
