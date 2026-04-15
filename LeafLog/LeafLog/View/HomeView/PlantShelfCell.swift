//
//  PlantShelfCell.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then

class PlantShelfCell: UICollectionViewCell {
    private let plants = [
        UIImageView(),
        UIImageView(),
        UIImageView()
    ]
    
    private let cards = [
        PlantLabelCardView(),
        PlantLabelCardView(),
        PlantLabelCardView()
    ]
    
    private let shelf = SeparateBar().then {
        $0.snp.makeConstraints {
            $0.height.equalTo(6)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setAttributes()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlantShelfCell {
    private func setAttributes() {
        plants.forEach {
            $0.snp.makeConstraints {
                $0.width.height.equalTo(96)
            }
        }
        
        cards.forEach {
            $0.snp.makeConstraints {
                $0.width.equalTo(88)
            }
        }
    }
    
    private func generateStackView() -> UIStackView {
        let verticals = zip(plants, cards).map {
            generateVerticalStack(views: [$0.0, $0.1])
        }
        
        let horizontal = generateHorizontalStack(views: verticals)
        return horizontal
    }
    
    private func generateHorizontalStack(views: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views).then {
            $0.axis = .horizontal
            $0.distribution = .equalSpacing
        }
        
        return stackView
    }
    
    private func generateVerticalStack(views: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views).then {
            $0.axis = .vertical
            $0.spacing = 18
            $0.alignment = .center
        }
        
        views[1].setContentHuggingPriority(.defaultLow, for: .vertical)
        views[1].setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        return stackView
    }
    
    private func setLayout() {
        let plantStackView = generateHorizontalStack(views: plants)
        let cardStackView = generateHorizontalStack(views: cards)
//        let plantStackView = UIStackView(arrangedSubviews: plants).then {
//            $0.axis = .horizontal
//            $0.distribution = .equalSpacing
//        }
//        
//        let cardStackView = UIStackView(arrangedSubviews: cards).then {
//            $0.axis = .horizontal
//            $0.spacing = 15
//            $0.distribution = .fillEqually
//        }
        
        
        contentView.addSubview(plantStackView)
        contentView.addSubview(shelf)
        contentView.addSubview(cardStackView)
        
        plantStackView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        shelf.snp.makeConstraints {
            $0.top.equalTo(plantStackView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
        }
        
        cardStackView.snp.makeConstraints {
            $0.top.equalTo(shelf.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(18)
        }
    }
}

extension PlantShelfCell {
    func configure(_ data: [HomeView.ShelfPlant?]) {
        guard data.count == 3 else { return } // 데이터는 3개씩 들어와야함
        
        data.enumerated().forEach {
            let index = $0.offset
            let plant = $0.element
            
            if let plant {
                plants[index].image = UIImage(named: plant.category.defaultImageAssetName)
                cards[index].nameLabel.text = plant.name
                cards[index].recentDayLabel.text = "\(String(describing: plant.daysFromLastWatering))일 전"
                cards[index].nextDayLabel.text = "\(String(describing: plant.daysToNextWatering))일"
                cards[index].waterButton.isSelected = plant.didWater
            } else {
                cards[index].isHidden = true
                
                if index > 0 {
                    plants[index].image = plants[plants.index(before: index)].image == .plantAdd ? nil : .plantAdd
                } else {
                    plants[index].image = .plantAdd
                } 
            }
        }
    }
}
