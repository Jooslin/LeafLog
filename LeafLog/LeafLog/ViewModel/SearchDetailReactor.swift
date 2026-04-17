//
//  SearchDetailReactor.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/16/26.
//
import Foundation
import ReactorKit
import RxSwift
import Dependencies

final class SearchDetailReactor: Reactor {

    enum Action {
        case viewDidLoad
    }

    enum Mutation {
        case setDetail(PlantDetail)
        case setImages([PlantFileItem])
    }

    struct State {
        var contentNumber: String
        var detail: PlantDetail?
        var images: [PlantFileItem] = []
        var displayName: String = "이름 정보 없음"
        var displayImages: [PlantFileItem] = []

        var displayImageURLs: [String] {
            displayImages.compactMap(\.displayImageURL)
        }
    }

    let initialState: State

    @Dependency(\.networkManager) private var networkManager

    init(contentNumber: String) {
        self.initialState = State(contentNumber: contentNumber)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .concat([
                fetchDetail(contentNumber: currentState.contentNumber),
                fetchImages(contentNumber: currentState.contentNumber)
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setDetail(let detail):
            newState.detail = detail
            newState.displayName = Self.makeDisplayName(from: newState.images)

        case .setImages(let images):
            newState.images = images
            newState.displayImages = Self.makeDisplayImages(from: images)
            newState.displayName = Self.makeDisplayName(from: images)
        }

        return newState
    }

    private func fetchDetail(contentNumber: String) -> Observable<Mutation> {
        Observable.create { [networkManager] observer in
            let task = Task {
                do {
                    let detail = try await networkManager.fetchPlantDetail(contentNumber: contentNumber)
                    
                    observer.onNext(.setDetail(detail))
                    observer.onCompleted()
                } catch {
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    private func fetchImages(contentNumber: String) -> Observable<Mutation> {
        Observable.create { [networkManager] observer in
            let task = Task {
                do {
                    let images = try await networkManager.fetchPlantFiles(contentNumber: contentNumber)

                    observer.onNext(.setImages(images))
                    observer.onCompleted()
                } catch {
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    // 적절한 이미지만 만들기
    private static func makeDisplayImages(from images: [PlantFileItem]) -> [PlantFileItem] {
        images.filter(\.isImage)
    }
    // 이미지 이름 판별
    private static func makeDisplayName(from images: [PlantFileItem]) -> String {
        let imageName = images
            .lazy
            .compactMap(\.name)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })

        return imageName ?? "이름 정보 없음"
    }
}
