//
//  PHPickerViewController+.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/21/26.
//

import PhotosUI
import RxCocoa
import RxSwift

extension Reactive where Base: PHPickerViewController {
    var delegate: RxPHPickerViewControllerDelegateProxy {
        return RxPHPickerViewControllerDelegateProxy.proxy(for: base)
    }

    func setDelegate(_ delegate: PHPickerViewControllerDelegate) -> Disposable {
        return RxPHPickerViewControllerDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    var selectedImages: ControlEvent<[UIImage]> {
        let source = delegate.didFinishPickingRelay
            .map {
                $0.map { $0.rx.loadImage().catchAndReturn(nil).compactMap { $0 } }
            }
            .flatMap { Observable.zip($0) }
        return ControlEvent(events: source.take(until: base.rx.deallocated))
    }
}
nonisolated
class RxPHPickerViewControllerDelegateProxy: DelegateProxy<PHPickerViewController, PHPickerViewControllerDelegate>, DelegateProxyType, PHPickerViewControllerDelegate {
    let didFinishPickingRelay = PublishSubject<[PHPickerResult]>()

    // delegate를 가진 클래스를 RxDelegateProxy 클래스로 등록
    static func registerKnownImplementations() {
        register {
            RxPHPickerViewControllerDelegateProxy(parentObject: $0, delegateProxy: RxPHPickerViewControllerDelegateProxy.self)
        }
    }

    static func currentDelegate(for object: PHPickerViewController) -> PHPickerViewControllerDelegate? {
        MainActor.assumeIsolated {
            return object.delegate
        }
    }

    static func setCurrentDelegate(_ delegate: PHPickerViewControllerDelegate?, to object: PHPickerViewController) {
        MainActor.assumeIsolated {
            object.delegate = delegate
        }
    }

    // 선택한 이미지(PHPickerResult)를 Relay로 방출
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        didFinishPickingRelay.on(.next(results))
        picker.dismiss(animated: true)
    }

    // Relay가 onCompleted되면 메모리에서 해제
    deinit {
        didFinishPickingRelay.on(.completed)
    }
}

extension PHPickerResult: @retroactive ReactiveCompatible {}

extension Reactive where Base == PHPickerResult {
    func loadImage() -> Observable<UIImage?> {
        return Observable.create { [base] observer in
            if base.itemProvider.canLoadObject(ofClass: UIImage.self) {
                base.itemProvider.loadObject(ofClass: UIImage.self) { item, error in
                    if let image = item as? UIImage {
                        observer.on(.next(image))
                    } else if let error {
                        observer.on(.error(error))
                    }
                    observer.on(.completed)
                }
            } else {
                observer.on(.next(nil))
                observer.on(.completed)
            }
            return Disposables.create()
        }
    }
}
