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

final class SearchDetailReactor: AsyncReactor {

    enum Action {
        case viewDidLoad
        case selectPlant
    }

    enum Mutation {
        case setLoading(Bool)
        case setDetail(PlantDetail)
        case setImages([PlantFileItem])
        case setError(String)
        case setSelectedPlant(SelectedPlant)
    }

    struct State {
        var contentNumber: String
        var isLoading: Bool = false
        var detail: PlantDetail?
        var images: [PlantFileItem] = []
        var displayName: String = "이름 정보 없음"
        var displayImages: [PlantFileItem] = []
        @Pulse var selectedPlant: SelectedPlant? = nil
        @Pulse var errorMessage: String? = nil

        var displayImageURLs: [String] {
            displayImages.compactMap(\.displayImageURL)
        }
    }

    let initialState: State

    @Dependency(\.networkManager) private var networkManager

    init(contentNumber: String) {
        self.initialState = State(contentNumber: contentNumber)
    }

    func mutate(action: Action, continuation: MutationStreamContinuation) async throws {
        switch action {
        case .viewDidLoad:
            continuation.yield(.setLoading(true))
            async let detailMutation = fetchDetail(contentNumber: currentState.contentNumber)
            async let imagesMutation = fetchImages(contentNumber: currentState.contentNumber)
            continuation.yield(await detailMutation)
            continuation.yield(await imagesMutation)
            continuation.yield(.setLoading(false))

        case .selectPlant:
            guard let detail = currentState.detail else {
                continuation.yield(.setError("식물 정보를 아직 불러오지 못했어요."))
                return
            }

            let name = Self.makeSelectedPlantName(detail: detail, displayName: currentState.displayName)
            continuation.yield(
                .setSelectedPlant(
                    SelectedPlant(
                        name: name,
                        contentNumber: currentState.contentNumber,
                        detail: detail,
                        category: nil
                    )
                )
            )
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setDetail(let detail):
            newState.detail = detail
            newState.displayName = Self.makeDisplayName(from: newState.images)

        case .setImages(let images):
            newState.images = images
            newState.displayImages = Self.makeDisplayImages(from: images)
            newState.displayName = Self.makeDisplayName(from: images)

        case .setError(let message):
            newState.errorMessage = message
        case .setSelectedPlant(let selectedPlant):
            newState.selectedPlant = selectedPlant
        }

        return newState
    }

    private func fetchDetail(contentNumber: String) async -> Mutation {
        do {
            let detail = try await networkManager.fetchPlantDetail(contentNumber: contentNumber)
            return .setDetail(detail)
        } catch {
            return .setError(Self.errorMessage(from: error))
        }
    }
    
    private func fetchImages(contentNumber: String) async -> Mutation {
        do {
            let images = try await networkManager.fetchPlantFiles(contentNumber: contentNumber)
            return .setImages(images)
        } catch {
            return .setError(Self.errorMessage(from: error))
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

    private static func errorMessage(from error: Error) -> String {
        if let networkError = error as? NetworkManager.NetworkError {
            return networkError.errorDescription ?? "식물 정보를 불러오지 못했습니다."
        }

        return error.localizedDescription
    }

    private static func makeSelectedPlantName(detail: PlantDetail, displayName: String) -> String {
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDisplayName.isEmpty, trimmedDisplayName != "이름 정보 없음" {
            return trimmedDisplayName
        }

        let detailName = detail.contentNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (detailName?.isEmpty == false ? detailName : nil) ?? "이름 정보 없음"
    }
}
