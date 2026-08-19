//
//  PictureComposeView.swift
//  LeafLog
//
//  Created by 변예린 on 7/8/26.
//

import UIKit
import Kingfisher
import SnapKit
import Then
import RxCocoa
import RxSwift

final class PictureComposeView: BaseCardView {
    //MARK: Components
    private let dashedBorderLayer = CAShapeLayer()
    private var currentImageSource: ImageSource?
    
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
    fileprivate let longPressGesture = UILongPressGestureRecognizer().then {
        $0.minimumPressDuration = 0.3
    }
    
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
    enum ImageSource: Equatable {
        case local(UIImage)
        case remote(url: URL?, cacheKey: String)

        static func == (lhs: ImageSource, rhs: ImageSource) -> Bool {
            switch (lhs, rhs) {
            case let (.local(lhsImage), .local(rhsImage)):
                lhsImage === rhsImage
            case let (
                .remote(lhsURL, lhsCacheKey),
                .remote(rhsURL, rhsCacheKey)
            ):
                lhsURL == rhsURL && lhsCacheKey == rhsCacheKey
            default:
                false
            }
        }
    }

    func setImage(_ source: ImageSource?, isOccupied: Bool) {
        if currentImageSource != source {
            currentImageSource = source
            imageView.kf.cancelDownloadTask()

            switch source {
            case .local(let image):
                imageView.image = image

            case .remote(let url, let cacheKey):
                imageView.image = nil
                guard let url else { break }

                let resource = KF.ImageResource(
                    downloadURL: url,
                    cacheKey: cacheKey
                )
                imageView.kf.setImage(
                    with: resource,
                    options: [
                        .cacheOriginalImage,
                        .transition(.fade(0.2))
                    ]
                )

            case nil:
                imageView.image = nil
            }
        }

        imageView.isHidden = !isOccupied
        cancelButton.isHidden = !isOccupied
        addStack.isHidden = isOccupied
        dashedBorderLayer.isHidden = isOccupied
    }
}

//MARK: Action
extension PictureComposeView: UIGestureRecognizerDelegate {
    private func setAction() {
        tapGesture.delegate = self
        longPressGesture.delegate = self
        tapGesture.require(toFail: longPressGesture)
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(longPressGesture)
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

    var longPress: ControlEvent<UILongPressGestureRecognizer> {
        ControlEvent(events: base.longPressGesture.rx.event)
    }
}
