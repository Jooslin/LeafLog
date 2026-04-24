//
//  CalendarTitleCell.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/14/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class CalendarTitleCell: UICollectionViewCell {
    private(set) var disposeBag = DisposeBag()
    
    fileprivate let titleView = TitleHeaderView(text: "", hasBackButton: false, rightButtonImage: "bell", isCollectionView: true)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleView)
        titleView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}

extension Reactive where Base: CalendarTitleCell {
    var alarmButtonTap: ControlEvent<Void> {
        base.titleView.rightButton.rx.tap
    }
}
