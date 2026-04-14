//
//  HomeView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then

final class HomeView: UIView {
    let titleView = TitleHeaderView(text: "", hasBackButton: false, rightButtonImage: "bell")
    //TODO: image 추후 변경 필요
    let totalPlant = TotalCardView(image: "badgeSproutBig", text: "내 식물 N개")
    let totalWater = TotalCardView(image: "badgeWaterBig", text: "물 준 식물 N개")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .grayScale50
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HomeView {
    func setLayout() {
        addSubview(titleView)
        addSubview(totalPlant)
        addSubview(totalWater)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        totalPlant.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(48)
            $0.width.equalTo(135)
        }
        
        totalWater.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.leading.equalTo(totalPlant.snp.trailing).offset(16)
            $0.height.equalTo(48)
            $0.width.equalTo(150)
        }
    }
}
