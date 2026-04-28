//
//  SinglePlantShelfCell.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/15/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class PlantShelfCell: UICollectionViewCell {
    private(set) var disposeBag = DisposeBag()
    private let plant = UIImageView()
    fileprivate let card = PlantLabelCardView()
    
    private let shelf = SeparateBar().then {
        $0.snp.makeConstraints {
            $0.height.equalTo(6)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}

extension PlantShelfCell {
    
    private func setLayout() {
        contentView.addSubview(plant)
        contentView.addSubview(shelf)
        contentView.addSubview(card)
        
        plant.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(plant.snp.width)
        }
        
        shelf.snp.makeConstraints {
            $0.top.equalTo(plant.snp.bottom).offset(-4)
            $0.horizontalEdges.equalToSuperview()
        }
        
        card.snp.makeConstraints {
            $0.top.equalTo(shelf.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(8)
//            $0.bottom.equalToSuperview().inset(18)
        }
    }
}

extension PlantShelfCell {
    func configure(_ data: HomeView.ShelfPlant) {
        switch data.emptyShelf {
        case .none:
            card.isHidden = false
            plant.image = UIImage(named: data.defaultImageAssetName ?? "")
            card.nameLabel.text = data.name ?? ""
            card.recentDayLabel.text = "\(data.daysFromLastWatering ?? 0)일 전"
            card.nextDayLabel.text = "\(data.daysToNextWatering ?? 0)일"
            card.waterButton.isSelected = data.didWater ?? false
        case .first:
            card.isHidden = true
            plant.image = .plantAdd
        default:
            card.isHidden = true
            plant.image = nil
        }
        
        configureShelf(order: data.shelfOrder)
    }
    
    private func configureShelf(order: ShelfOrder) {
        switch order {
        case .first:
            shelf.layer.cornerRadius = 3
            shelf.clipsToBounds = true
            shelf.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMinXMinYCorner, .layerMinXMaxYCorner)
        case .second:
            shelf.layer.cornerRadius = 0
            shelf.clipsToBounds = false
        case .third:
            shelf.layer.cornerRadius = 3
            shelf.clipsToBounds = true
            shelf.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMaxXMinYCorner, .layerMaxXMaxYCorner)
        }
    }
}

extension Reactive where Base: PlantShelfCell {
    var waterButtonTap: ControlEvent<Void> {
        base.card.waterButton.rx.tap
    }
}
