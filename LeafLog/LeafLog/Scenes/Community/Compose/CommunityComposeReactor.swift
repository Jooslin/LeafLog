//
//  CommunityComposeReactor.swift
//  LeafLog
//
//  Created by 변예린 on 7/9/26.
//

import UIKit
import ReactorKit
import Supabase
import Dependencies

final class CommunityComposeReactor: Reactor {
    @Dependency(\.communityPostDBManager) private var communityPostDBManager
    @Dependency(\.supabaseManager) private var supabaseManager

    enum Action {
        case viewWillAppear
        case selectCategory(Int)
        case enterTitle(String)
        case enterBody(String)
        
        case addPictures([UIImage])
        case replacePicture(index: Int, image: UIImage)
        case removePicture(index: Int)
        case movePicture(from: Int, to: Int)
        case saveTapped
    }
    
    enum Mutation {
        case setCategory(PostCategory)
        case setTitle(String)
        case setBody(String)
        
        case appendPictures([UIImage])
        case replacePicture(index: Int, image: UIImage)
        case removePicture(index: Int)
        case movePicture(from: Int, to: Int)
        case setSaving(Bool)
        case setSaveCompleted
        case setWarningMessage(String)
        case setErrorMessage(String)
    }
    
    struct State {
        let postID = UUID()
        var category: PostCategory
        var title: String = ""
        var pictures: [UIImage] = []
        var body: String = ""
        var isSaving = false
        @Pulse var saveCompleted = false
        @Pulse var warningMessage: String?
        @Pulse var errorMessage: String?
        
        var isButtonActive: Bool {
            let normalizedTitle = title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            let normalizedBody = body.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            return !normalizedTitle.isEmpty
                && normalizedTitle.count <= 50
                && !normalizedBody.isEmpty
                && body.count <= CommunityComposeView.bodyMaxCount
                && !isSaving
                && !saveCompleted
        }
    }
    
    let initialState = State(category: .plantLife)
    
    //MARK: Properties
    private let calendar = Calendar.current
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return .empty()
        case .selectCategory(let tag):
            return
                .just(.setCategory(PostCategory(rawValue: tag) ?? .plantLife))
        case .enterTitle(let title):
            return .just(.setTitle(title))
        case .addPictures(let pictures):
            return .just(.appendPictures(pictures))
        case let .replacePicture(index, image):
            return .just(.replacePicture(index: index, image: image))
        case .removePicture(let index):
            return .just(.removePicture(index: index))
        case let .movePicture(from, to):
            return .just(.movePicture(from: from, to: to))
        case .enterBody(let body):
            return .just(.setBody(body))
        case .saveTapped:
            return savePost(state: currentState)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setCategory(let category):
            newState.category = category
        case .setTitle(let title):
            newState.title = title
        case .appendPictures(let pictures):
            newState.pictures.append(contentsOf: pictures)
        case let .replacePicture(index, image):
            guard newState.pictures.indices.contains(index) else {
                return state
            }
            newState.pictures[index] = image
        case .removePicture(let index):
            guard newState.pictures.indices.contains(index) else {
                return state
            }
            newState.pictures.remove(at: index)
        case let .movePicture(from, to):
            guard
                newState.pictures.indices.contains(from),
                newState.pictures.indices.contains(to)
            else {
                return state
            }
            let picture = newState.pictures.remove(at: from)
            newState.pictures.insert(picture, at: to)
        case .setBody(let body):
            newState.body = body
        case .setSaving(let isSaving):
            newState.isSaving = isSaving
        case .setSaveCompleted:
            newState.isSaving = false
            newState.saveCompleted = true
        case .setWarningMessage(let message):
            newState.warningMessage = message
        case .setErrorMessage(let message):
            newState.isSaving = false
            newState.errorMessage = message
        }
        return newState
    }

    private func savePost(state: State) -> Observable<Mutation> {
        guard !state.isSaving else { return .empty() }

        let savePostSingle = Single<Bool>.create {
            [communityPostDBManager, supabaseManager] in
            guard let userID = supabaseManager.client.auth.currentUser?.id else {
                throw AuthError.communityFailed(
                    "로그인 정보를 확인하지 못했어요. 다시 로그인해주세요."
                )
            }

            let uploadResult = try await Self.uploadPictures(
                state.pictures,
                userID: userID,
                postID: state.postID,
                supabaseManager: supabaseManager
            )

            _ = try await communityPostDBManager.createPost(
                input: CommunityPostSaveInput(
                    id: state.postID,
                    category: state.category,
                    title: state.title,
                    content: state.body,
                    images: uploadResult.images
                )
            )

            return uploadResult.hasImageUploadFailure
        }

        let saveMutations = savePostSingle
            .asObservable()
            .flatMap { hasImageUploadFailure -> Observable<Mutation> in
                guard hasImageUploadFailure else {
                    return .just(.setSaveCompleted)
                }

                return .from([
                    .setSaveCompleted,
                    .setWarningMessage(
                        "업로드하지 못한 사진이 있어요. 잠시 후 다시 시도해주세요."
                    )
                ])
            }
            .catch { error in
                guard !(error is CancellationError) else {
                    return .empty()
                }

                if let error = error as? AuthError {
                    return .just(.setErrorMessage(error.userMessage))
                }

                return .just(
                    .setErrorMessage(
                        "게시글을 저장하지 못했어요. 잠시 후 다시 시도해주세요."
                    )
                )
            }

        return .concat(
            .just(.setSaving(true)),
            saveMutations
        )
    }

    private static func uploadPictures(
        _ pictures: [UIImage],
        userID: UUID,
        postID: UUID,
        supabaseManager: SupabaseManager
    ) async throws -> CommunityImageUploadResult {
        var uploadedImages: [CommunityPostImageInput] = []
        var hasImageUploadFailure = false

        for picture in pictures {
            try Task.checkCancellation()
            let imageID = UUID()

            if let imagePath = try await uploadPicture(
                picture,
                userID: userID,
                postID: postID,
                imageID: imageID,
                supabaseManager: supabaseManager
            ) {
                uploadedImages.append(
                    CommunityPostImageInput(
                        id: imageID,
                        imagePath: imagePath
                    )
                )
            } else {
                hasImageUploadFailure = true
            }
        }

        return CommunityImageUploadResult(
            images: uploadedImages,
            hasImageUploadFailure: hasImageUploadFailure
        )
    }

    private static func uploadPicture(
        _ picture: UIImage,
        userID: UUID,
        postID: UUID,
        imageID: UUID,
        supabaseManager: SupabaseManager
    ) async throws -> String? {
        for attempt in 0..<3 {
            do {
                try Task.checkCancellation()

                return try await supabaseManager.uploadCommunityPostImage(
                    picture,
                    userID: userID,
                    postID: postID,
                    imageID: imageID
                )
            } catch {
                if Task.isCancelled {
                    throw CancellationError()
                }

                guard attempt < 2 else { return nil }
            }
        }

        return nil
    }
}

private struct CommunityImageUploadResult {
    let images: [CommunityPostImageInput]
    let hasImageUploadFailure: Bool
}
