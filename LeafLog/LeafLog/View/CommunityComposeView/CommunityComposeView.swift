//
//  CommunityComposeView.swift
//  LeafLog
//
//  Created by 변예린 on 7/1/26.
//

import UIKit
import Kingfisher
import SnapKit
import Then

final class CommunityComposeView: UIView {
    // MARK: - UI Components
    let titleView = TitleHeaderView(text: "", hasBackButton: true, rightButtonImage: "helpCircle")
    
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
    }
    
    //MARK: init
    init(mode: Mode) {
        super.init(frame: .zero)
        
        switch mode {
        case .create:
            titleView.titleLabel.text = "게시글 작성"
        case .edit:
            titleView.titleLabel.text = "게시글 수정"
        }
        
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayout() {
        
    }
 
}


//MARK: Types
extension CommunityComposeView {
    enum Mode {
        case create
        case edit
    }
}
