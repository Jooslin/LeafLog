//
//  ViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import Dependencies
import RxFlow
import RxSwift
import RxCocoa
import SnapKit
import ReactorKit
import PhotosUI

/*
 RxFlow 사용 예시입니다. 추후 삭제 예정입니다.
 하단에 SecondViewController가 선언되어있습니다.
 ViewController와 SecondViewController는 BaseViewController를 상속합니다.
 */

final class ViewController: BaseViewController, View {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.reactor = TempReactor()
        
        let pushButton = UIButton(configuration: .plain())
        pushButton.setTitle("push", for: .normal)
        
        view.addSubview(pushButton)
        
        pushButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        pushButton.rx.tap
            .map { _ in AppStep.photoSelect } // push Step으로 변환
            .bind(to: steps) // VC의 steps와 바인딩 -> 버튼을 누를 때마다 'push' 스텝이 방출
            .disposed(by: disposeBag)
    }
    
    func bind(reactor: TempReactor) {
        bindState(reactor: reactor)
    }
    
    private func bindState(reactor: TempReactor) {
        reactor.state
            .map { AppStep.classificationResult($0.classificationResult)
            }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    // picker에서 이미지 선택 시(picker 종료 시) 동작
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let item = results.first,
              item.itemProvider.canLoadObject(ofClass: UIImage.self) else {
            picker.dismiss(animated: true)
            return
        }
        
        // itemProvider에서 UIImage로 로드가 가능하다면 UIImage로 선택된 사진 load
        item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self, weak picker] image, error in // loadObject는 비동기로 작동하므로 picker도 약한 참조
            guard let image = image as? UIImage else {
                picker?.dismiss(animated: true)
                return
            }
            
            Task { @MainActor [weak self, weak picker] in
                picker?.dismiss(animated: true) { [weak self] in
                    self?.reactor?.action.onNext(TempReactor.Action.classificationImageSelected(image))
                }
            }
        }
    }
}

//TODO: 추후 등록쪽 Reactor에 추가하기
final class TempReactor: Reactor {
    @Dependency(\.plantClassificationService) private var plantClassificationService
    
    enum Action {
        case classificationImageSelected(UIImage)
    }
    
    enum Mutation {
        case analyzeResult([String: PlantClassificationService.Confidence])
    }
    
    struct State {
        var classificationResult: [String: PlantClassificationService.Confidence] = [:]
    }
    
    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .classificationImageSelected(let image):
            return analyzeImage(image)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .analyzeResult(let result):
            newState.classificationResult = result
        }
        return newState
    }
    
    private func analyzeImage(_ image: UIImage) -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            Task {
                do {
                    let classificationResult = try self.plantClassificationService.analyzeImage(image: image)
                    observer.onNext(.analyzeResult(classificationResult))
                    observer.onCompleted()
                } catch {
                    print(error)
                    observer.onNext(.analyzeResult([:]))
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}
