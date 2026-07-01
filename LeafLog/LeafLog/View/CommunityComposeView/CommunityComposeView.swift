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
    private let contentView = UIView()
    
    let categoryDailyButton = UIButton(config: .lSize, title: "식물 일상").then {
        $0.layer.cornerRadius = 8
    }
    let categoryQuestionButton = UIButton(config: .lSize, title: "식물 고민").then {
        $0.layer.cornerRadius = 8
    }
    let categoryPlanetButton = UIButton(config: .lSize, title: "초록별 여행").then {
        $0.layer.cornerRadius = 8
    }
    let saveButton = BottomSaveButton(title: "")
    
    //MARK: init
    init(mode: Mode) {
        super.init(frame: .zero)
        
        switch mode {
        case .create:
            titleView.titleLabel.text = "게시글 작성"
            saveButton.setTitle("등록하기")
        case .edit:
            titleView.titleLabel.text = "게시글 수정"
            saveButton.setTitle("수정하기")
        }
        
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayout() {
        let buttonStack = UIStackView(arrangedSubviews: [categoryDailyButton, categoryQuestionButton, categoryPlanetButton]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }
        
        addSubview(titleView)
        addSubview(scrollView)
        addSubview(saveButton)
        scrollView.addSubview(contentView)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
        }
        
        saveButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(24)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.snp.width)
        }
    }
 
}

//MARK: Components
extension CommunityComposeView {
    
}

//MARK: Types
extension CommunityComposeView {
    enum Mode {
        case create
        case edit
    }
}
