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
    private(set) var disposeBag = DisposeBag()
    
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
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
            $0.top.equalToSuperview().offset(20)
            $0.bottom.equalToSuperview().inset(36)
        }
    }
    
    private func generateButtonStack() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: buttons).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.distribution = .fillEqually
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
}

extension Reactive where Base: CalendarFilterCell {
    var filterButtonTap: Observable<Int> {
        let taps = Observable.merge(
            base.buttons.map { button in
                button.rx.tap.map { button.tag }
            })
        
        return taps
    }
}
