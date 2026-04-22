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
        SelectionButton(title: "전체"),
        SelectionButton(title: "물주기"),
        SelectionButton(title: "분갈이"),
        SelectionButton(title: "비료"),
        SelectionButton(title: "치료"),
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
            if button.offset == 0 {
                button.element.tag = buttons.count
                return
            }
            button.element.tag = button.offset - 1
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
    func configure(selectedTags: Set<Int>) {
        buttons.forEach { button in
            if selectedTags.isEmpty {
                button.isSelected = button.tag == buttons.count ? true : false
            } else {
                button.isSelected = button.tag == buttons.count ? false
                : selectedTags.contains(button.tag) ? true : false
            }
        }
    }
    
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
//    var filterItemSelected: ControlEvent<[Badge]> {
//        let taps = Observable.merge(
//            base.buttons.map { button in
//                button.rx.tap
//                    .map { [weak base] in
//                        guard let base else { return [Badge]() }
//                        
//                        button.isSelected.toggle()
//                        
//                        return base.buttons.compactMap {
//                            guard $0.isSelected,
//                                  let title = $0.titleLabel?.text else { return nil }
//                            return Badge(rawValue: title)
//                        }
//                    }
//            }
//        )
//        
//        return ControlEvent(events: taps)
//    }
    var filterButtonTap: ControlEvent<Int> {
        let taps = Observable.merge(
            base.buttons.map { button in
                button.rx.tap.map { button.tag }
            })
        
        return ControlEvent(events: taps)
    }
}
