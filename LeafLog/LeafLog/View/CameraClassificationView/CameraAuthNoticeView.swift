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

final class CameraAuthNoticeView: EmptyView {
    override init(frame: CGRect = .zero,
                  image: String = OthersImageAsset.cameraColored.rawValue,
                  title: String = Notice.authorizationDenied.label,
                  subTitle: String = Notice.authorizationDenied.subLabel,
                  needButton: Bool = true,
                  buttonTitle: String? = "설정으로 이동"
    ) {
        super.init(
            image: image,
            title: title,
            subTitle: subTitle,
            needButton: needButton,
            buttonTitle: buttonTitle
        )
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        base.button.rx.tap
    }
}
