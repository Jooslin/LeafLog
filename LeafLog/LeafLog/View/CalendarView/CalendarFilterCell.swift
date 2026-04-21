//
//  CalendarFilterCell.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class CalendarFilterCell: UICollectionViewCell {
        
    fileprivate let buttons = [
        SelectionButton(title: ""),
        SelectionButton(title: ""),
        SelectionButton(title: ""),
        SelectionButton(title: ""),
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setButtonAttributes()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarFilterCell {
    private func setButtonAttributes() {
        buttons.enumerated().forEach { button in
            button.element.tag = button.offset
        }
    }
    
    private func setLayout() {
        let buttonStack = generateButtonStack()
        
        contentView.addSubview(buttonStack)
        
        buttonStack.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }
    
    private func generateButtonStack() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: buttons).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.distribution = .fill
        }
        
        return stackView
    }
}

extension CalendarFilterCell {
    func configure(_ data: [String]) {
        buttons.forEach {
            if $0.tag < data.count {
                $0.setup(title: data[$0.tag])
            } else {
                $0.isHidden = true
            }
        }
    }
}

extension Reactive where Base: CalendarFilterCell {
    var filterItemSelected: ControlEvent<[Badge]> {
        let taps = Observable.merge(
            base.buttons.map { button in
                button.rx.tap
                    .map { [weak base] in
                        guard let base else { return [Badge]() }
                        
                        button.isSelected.toggle()
                        
                        return base.buttons.compactMap {
                            guard $0.isSelected,
                                  let title = $0.titleLabel?.text else { return nil }
                            return Badge(rawValue: title)
                        }
                    }
            }
        )
        
        return ControlEvent(events: taps)
    }
}
