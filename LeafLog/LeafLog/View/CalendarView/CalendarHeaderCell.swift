//
//  CalendarHeaderCell.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class CalendarHeaderCell: UICollectionViewCell {
    private(set) var disposeBag = DisposeBag()
    
    fileprivate let previousButton = UIButton(configuration: .plain())
    fileprivate let nextButton = UIButton(configuration: .plain())
    
    private var year: Int = 0
    private var month: Int = 0
    private let dateLabel = UILabel(text: "", config: .label16)
    
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

extension CalendarHeaderCell {
    private func setButtonAttributes() {
        previousButton.setImage(.arrowLeft, for: .normal)
        nextButton.setImage(.arrowRight, for: .normal)
        
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .black
        
        previousButton.configuration = config
        nextButton.configuration = config
    }
    
    private func setLayout() {
        let stackView = generateStackView()
        
        contentView.addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.centerX.equalToSuperview()
        }
    }
    
    private func generateStackView() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [previousButton, dateLabel, nextButton]).then {
            $0.axis = .horizontal
            $0.spacing = 32
        }
        
        previousButton.setContentHuggingPriority(.required, for: .horizontal)
        previousButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        nextButton.setContentHuggingPriority(.required, for: .horizontal)
        nextButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return stackView
    }
}

extension CalendarHeaderCell {
    func configure(year: Int, month: Int) {
        dateLabel.text = "\(year)년 \(month)월"
    }
}

extension Reactive where Base: CalendarHeaderCell {
    var headerPreviousButtonTap: ControlEvent<Void> {
        base.previousButton.rx.tap
    }
    
    var headerNextButtonTap: ControlEvent<Void> {
        base.nextButton.rx.tap
    }
}
