//
//  CommunityInfoViewController.swift
//  LeafLog
//
//  Created by 변예린 on 7/5/26.
//

import SnapKit
import Then
import UIKit

final class CommunityInfoViewController: UIViewController {
    private let infoView = CommunityInfoView()
    private let dimmedView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        // layout
        view.addSubview(dimmedView)
        view.addSubview(infoView)
        
        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        infoView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        
        // action
        dimmedView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dismissInfoView))
        )
        
        infoView.closeButton.addTarget(self, action: #selector(dismissInfoView), for: .touchUpInside)
    }
    
    @objc private func dismissInfoView() {
        dismiss(animated: false)
    }
}

@available(iOS 17.0, *)
#Preview {
  CommunityInfoViewController()
}
