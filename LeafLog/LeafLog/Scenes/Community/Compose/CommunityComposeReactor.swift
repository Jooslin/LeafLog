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

enum CommunityComposeMode {
    case create
    case edit(CommunityPost)
}

struct CommunityComposePicture {
    let existingImage: CommunityPostImage?
    let localImageID: UUID?
    let previewImage: UIImage?

    init(existingImage: CommunityPostImage, previewImage: UIImage? = nil) {
        self.existingImage = existingImage
        self.localImageID = nil
        self.previewImage = previewImage
    }

    init(localImageID: UUID = UUID(), image: UIImage) {
        self.existingImage = nil
        self.localImageID = localImageID
        self.previewImage = image
    }

    func replacing(with image: UIImage) -> CommunityComposePicture {
        CommunityComposePicture(
            existingImage: existingImage,
            localImageID: UUID(),
            previewImage: image
        )
    }

    func settingPreview(_ image: UIImage) -> CommunityComposePicture {
        CommunityComposePicture(
            existingImage: existingImage,
            localImageID: localImageID,
            previewImage: image
        )
    }

    private init(
        existingImage: CommunityPostImage?,
        localImageID: UUID?,
        previewImage: UIImage?
    ) {
        self.existingImage = existingImage
        self.localImageID = localImageID
        self.previewImage = previewImage
    }
}

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
        case setExistingPicturePreview(id: UUID, image: UIImage)
        case setSaving(Bool)
        case setSaveCompleted
        case setWarningMessage(String)
        case setErrorMessage(String)
    }
    
    struct State {
        let mode: CommunityComposeMode
        let postID: UUID
        var category: PostCategory
        var title: String
        var pictures: [CommunityComposePicture]
        var removedExistingImagePaths: [String] = []
        var body: String
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
    
    let initialState: State

    init(mode: CommunityComposeMode = .create) {
        switch mode {
        case .create:
            initialState = State(
                mode: mode,
                postID: UUID(),
                category: .plantLife,
                title: "",
                pictures: [],
                body: ""
            )

        case .edit(let post):
            initialState = State(
                mode: mode,
                postID: post.id,
                category: post.category,
                title: post.title,
                pictures: post.images
                    .sorted { $0.sortOrder < $1.sortOrder }
                    .map { CommunityComposePicture(existingImage: $0) },
                body: post.content
            )
        }
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return loadExistingPicturePreviews(state: currentState)
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
            newState.pictures.append(
                contentsOf: pictures.map {
                    CommunityComposePicture(image: $0)
                }
            )
        case let .replacePicture(index, image):
            guard newState.pictures.indices.contains(index) else {
                return state
            }
            newState.pictures[index] = newState.pictures[index]
                .replacing(with: image)
        case .removePicture(let index):
            guard newState.pictures.indices.contains(index) else {
                return state
            }
            let removedPicture = newState.pictures.remove(at: index)
            if let imagePath = removedPicture.existingImage?.imagePath {
                newState.removedExistingImagePaths.append(imagePath)
            }
        case let .movePicture(from, to):
            guard
                newState.pictures.indices.contains(from),
                newState.pictures.indices.contains(to)
            else {
                return state
            }
            let picture = newState.pictures.remove(at: from)
            newState.pictures.insert(picture, at: to)
        case let .setExistingPicturePreview(id, image):
            guard let index = newState.pictures.firstIndex(where: {
                $0.existingImage?.id == id && $0.localImageID == nil
            }) else {
                return state
            }
            newState.pictures[index] = newState.pictures[index]
                .settingPreview(image)
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

    private func loadExistingPicturePreviews(
        state: State
    ) -> Observable<Mutation> {
        let existingImages = state.pictures.compactMap(\.existingImage)

        return Observable.from(existingImages)
            .concatMap { [supabaseManager] image in
                Single<UIImage?>.create {
                    guard let url = try await supabaseManager
                        .resolveCommunityPostImageURL(
                            from: image.imagePath,
                            cacheKey: image.id.uuidString
                        )
                    else {
                        return nil
                    }

                    let (data, response) = try await URLSession.shared.data(
                        from: url
                    )
                    guard
                        let response = response as? HTTPURLResponse,
                        (200..<300).contains(response.statusCode)
                    else {
                        return nil
                    }

                    return UIImage(data: data)
                }
                .asObservable()
                .compactMap { preview in
                    preview.map {
                        Mutation.setExistingPicturePreview(
                            id: image.id,
                            image: $0
                        )
                    }
                }
                .catch { _ in .empty() }
            }
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

            let uploadResult = try await Self.preparePictures(
                state.pictures,
                userID: userID,
                postID: state.postID,
                supabaseManager: supabaseManager
            )
            let input = CommunityPostSaveInput(
                id: state.postID,
                category: state.category,
                title: state.title,
                content: state.body,
                images: uploadResult.images
            )

            switch state.mode {
            case .create:
                _ = try await communityPostDBManager.createPost(input: input)

            case .edit:
                _ = try await communityPostDBManager.updatePost(input: input)

                let deletedPaths = Set(
                    state.removedExistingImagePaths
                        + uploadResult.replacedImagePaths
                )
                try? await supabaseManager.deleteCommunityPostImages(
                    paths: Array(deletedPaths)
                )
            }

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

    private static func preparePictures(
        _ pictures: [CommunityComposePicture],
        userID: UUID,
        postID: UUID,
        supabaseManager: SupabaseManager
    ) async throws -> CommunityImageUploadResult {
        var imageInputs: [CommunityPostImageInput] = []
        var replacedImagePaths: [String] = []
        var hasImageUploadFailure = false

        for picture in pictures {
            try Task.checkCancellation()

            guard
                let localImageID = picture.localImageID,
                let localImage = picture.previewImage
            else {
                if let existingImage = picture.existingImage {
                    imageInputs.append(
                        CommunityPostImageInput(
                            id: existingImage.id,
                            imagePath: existingImage.imagePath
                        )
                    )
                }
                continue
            }

            if let imagePath = try await uploadPicture(
                localImage,
                userID: userID,
                postID: postID,
                imageID: localImageID,
                supabaseManager: supabaseManager
            ) {
                imageInputs.append(
                    CommunityPostImageInput(
                        id: localImageID,
                        imagePath: imagePath
                    )
                )

                if let existingPath = picture.existingImage?.imagePath {
                    replacedImagePaths.append(existingPath)
                }
            } else {
                hasImageUploadFailure = true

                if let existingImage = picture.existingImage {
                    imageInputs.append(
                        CommunityPostImageInput(
                            id: existingImage.id,
                            imagePath: existingImage.imagePath
                        )
                    )
                }
            }
        }

        return CommunityImageUploadResult(
            images: imageInputs,
            replacedImagePaths: replacedImagePaths,
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
    let replacedImagePaths: [String]
    let hasImageUploadFailure: Bool
}
