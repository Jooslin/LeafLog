//
//  CommunityInfoViewController.swift
//  LeafLog
//
//  Created by 변예린 on 7/5/26.
//

import SnapKit
import Then
import UIKit

final class CommunityInfoViewController: BaseViewController {
    private let infoView = CommunityInfoView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        view.addSubview(infoView)
        
        infoView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }
}

@available(iOS 17.0, *)
#Preview {
  CommunityInfoViewController()
}
