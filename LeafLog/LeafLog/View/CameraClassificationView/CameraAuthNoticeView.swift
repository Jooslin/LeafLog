//
//  CameraAuthNoticeView.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/17/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class CameraAuthNoticeView: UIView {
    let imageView = UIImageView(image: .cameraColored).then {
        $0.setContentHuggingPriority(.defaultLow, for: .vertical)
        $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        $0.snp.makeConstraints {
            $0.width.height.equalTo(96)
        }
    }
    let label = UILabel(text: "카메라 권한이 없어요", config: .title18).then {
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
        $0.textAlignment = .center
    }
    let subLabel = UILabel(text: "설정으로 이동해 카메라 권한을 허용하면 카메라를 이용할 수 있어요", config: .body14, color: .grayScale600).then {
        $0.textAlignment = .center
    }
    //TODO: component 수정 필요
    //    let settingButton = BottomSaveButton(title: "설정으로 이동")
    let settingButton = UIButton(configuration: .filled()).then {
        $0.setTitle("설정으로 이동", for: .normal)
        $0.snp.makeConstraints {
            $0.height.equalTo(24)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setLayout()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayout() {
        let labelStack = UIStackView(arrangedSubviews: [label, subLabel]).then {
            $0.axis = .vertical
            $0.spacing = 8
        }
        
        let stackView = UIStackView(arrangedSubviews: [imageView, labelStack]).then {
            $0.axis = .vertical
            $0.spacing = 32
            $0.alignment = .center
        }
        
        addSubview(stackView)
        addSubview(settingButton)
        
        stackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(76)
        }
        
        settingButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
        }
    }
}

extension CameraAuthNoticeView {
    enum Notice {
        case authorizationDenied
        case cameraNotReady
        
        var label: String {
            switch self {
            case .authorizationDenied:
                "카메라 권한이 없어요"
            case .cameraNotReady:
                "카메라를 실행할 수 없어요"
            }
        }
        
        var subLabel: String {
            switch self {
            case .authorizationDenied:
                "설정으로 이동해 카메라 권한을 허용하면 카메라를 이용할 수 있어요"
            case .cameraNotReady:
                "잠시 후에 다시 시도해주세요."
            }
        }
    }
    
    func configure(with type: Notice) {
        switch type {
        case .authorizationDenied:
            label.text = type.label
            subLabel.text = type.subLabel
        case .cameraNotReady:
            label.text = type.label
            subLabel.text = type.subLabel
        }
    }
}

extension Reactive where Base: CameraAuthNoticeView {
    var settingButtonTap: ControlEvent<Void> {
        base.settingButton.rx.tap
    }
}
