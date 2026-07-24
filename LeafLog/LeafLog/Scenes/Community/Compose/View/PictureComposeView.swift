//
//  PictureComposeView.swift
//  LeafLog
//
//  Created by 변예린 on 7/8/26.
//

import UIKit
import SnapKit
import Then
import RxCocoa
import RxSwift

final class PictureComposeView: BaseCardView {
    //MARK: Components
    private let dashedBorderLayer = CAShapeLayer()
    
    private let plusImageView = UIImageView(image: .plus).then {
        $0.tintColor = .primary800
    }
    
    private let pictureAddLabel = UILabel(text: "사진 추가", config: .label12, color: .primary800)
    
    private(set) lazy var addStack = UIStackView(arrangedSubviews: [plusImageView, pictureAddLabel]).then {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .center
    }
    
    let imageView = UIImageView().then {
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.isUserInteractionEnabled = true
        $0.isHidden = true
    }
    
    
    let cancelButton = UIButton().then {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .black.withAlphaComponent(0.5)
        configuration.baseForegroundColor = .white
        configuration.image = UIImage(resource: .x)
        $0.configuration = configuration
        
        $0.imageView?.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.isHidden = true
    }
    
    //MARK: Gesture
    fileprivate let tapGesture = UITapGestureRecognizer()
    var onPictureSelectionRequested: (() -> Void)?
    
    override init(frame: CGRect = .zero, cornerRadius: CGFloat = 12) {
        super.init(frame: frame, cornerRadius: cornerRadius)
        
        backgroundColor = .grayScale50
        
        dashedBorderLayer.fillColor = UIColor.clear.cgColor
        dashedBorderLayer.strokeColor = UIColor.grayScale100.cgColor
        dashedBorderLayer.lineWidth = 1
        dashedBorderLayer.lineDashPattern = [6, 4]
        dashedBorderLayer.zPosition = 1
        
        layer.addSublayer(dashedBorderLayer)
        
        setLayout()
        setAction()
    }
    
    @available(*, unavailable)
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        dashedBorderLayer.frame = bounds
        dashedBorderLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: layer.cornerRadius
        ).cgPath
    }
}

//MARK: Configure
extension PictureComposeView {
    func setImage(_ image: UIImage?) {
        imageView.image = image

        let hasImage = image != nil
        imageView.isHidden = !hasImage
        cancelButton.isHidden = !hasImage
        addStack.isHidden = hasImage
    }
}

//MARK: Action
extension PictureComposeView: UIGestureRecognizerDelegate {
    private func setAction() {
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }

    @objc private func didTapPictureView() {
        onPictureSelectionRequested?()
    }

    @objc private func didTapCancelButton() {
        setImage(nil)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let touchedView = touch.view else { return true }
        return !touchedView.isDescendant(of: cancelButton)
    }
}

//MARK: Layout
extension PictureComposeView {
    private func setLayout() {
        addSubview(addStack)
        addSubview(imageView)
        
        addStack.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        imageView.addSubview(cancelButton)
        
        cancelButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.top.trailing.equalToSuperview().inset(8)
            
        }
        
        cancelButton.imageView?.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.center.equalToSuperview()
        }
        
        plusImageView.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
    }
}

extension Reactive where Base:  PictureComposeView {
    var tap: ControlEvent<Void> {
        let source = base.tapGesture.rx.event.map { _ in () }
        return ControlEvent(events: source)
    }
    
    var cancelButtonTap: ControlEvent<Void> {
        base.cancelButton.rx.tap
    }
}
