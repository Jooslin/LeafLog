//
//  TitleHeaderView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/13/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

/// 공통으로 사용될 TitleHeaderView입니다.
///
/// - Parameters:
///     - text: 타이틀 레이블에 사용될 텍스트입니다.
///     - hasBackButton: 뒤로가기 버튼 표시 유무입니다. true로 설정할 시 뒤로가기 버튼을 표시합니다.
///     - rightButtonImage: 오른쪽 버튼의 이미지 이름입니다. nil일 경우 버튼을 표시하지 않습니다. 기본값은 nil입니다.
class TitleHeaderView: UIView {
    private let titleLabel = UILabel(text: "", config: .title18).then {
        $0.textAlignment = .center
    }
    
    let backButton = UIButton(configuration: .plain()).then {
        $0.configuration?.baseForegroundColor = .black
        $0.setImage(.arrowLeft, for: .normal)
    }
    
    let rightButton = UIButton(configuration: .plain())
    
    init(text: String, hasBackButton: Bool, rightButtonImage: String? = nil, isCollectionView: Bool = false) {
        super.init(frame: .zero)
        configure(text: text, hasBackButton: hasBackButton, rightButtonImage: rightButtonImage)
        isCollectionView ? setLayoutForCollectionView() : setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TitleHeaderView {
    private func configure(text: String, hasBackButton: Bool, rightButtonImage: String? = nil) {
        titleLabel.text = text
        backButton.isHidden = !hasBackButton
        
        guard let imageName = rightButtonImage else {
            rightButton.isHidden = true
            return
        }
        rightButton.setImage(UIImage(named: imageName), for: .normal)
        
        backButton.configuration?.baseForegroundColor = .black
        rightButton.configuration?.baseForegroundColor = .black
    }
    
    private func setLayout() {
        addSubview(titleLabel)
        addSubview(backButton)
        addSubview(rightButton)
        
        backButton.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.leading.equalToSuperview().inset(16)
        }
        
        titleLabel.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(11)
            $0.horizontalEdges.equalToSuperview().inset(40)
        }
        
        rightButton.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.trailing.equalToSuperview().inset(16)
        }
    }
}

extension TitleHeaderView {
    // 색상 변경 메서드
    func apply(color: UIColor) {
        titleLabel.textColor = color
        backButton.configuration?.baseForegroundColor = color
        rightButton.configuration?.baseForegroundColor = color
    }
}

extension TitleHeaderView {
    private func setLayoutForCollectionView() {
        addSubview(titleLabel)
        addSubview(backButton)
        addSubview(rightButton)
        
        backButton.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.leading.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(11)
            $0.horizontalEdges.equalToSuperview().inset(40)
        }
        
        rightButton.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.trailing.equalToSuperview()
        }
    }
}

extension Reactive where Base: TitleHeaderView {
    var backButtonTap: ControlEvent<Void> {
        base.backButton.rx.tap
    }
}
