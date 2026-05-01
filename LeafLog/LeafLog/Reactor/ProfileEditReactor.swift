//
//  ProfileEditReactor.swift
//  LeafLog
//
//  Created by 김주희 on 4/13/26.
//

import UIKit
import ReactorKit
import RxSwift
import Dependencies

final class ProfileEditReactor: Reactor {

    @Dependency(\.profileDBManager) private var profileDBManager
    @Dependency(\.supabaseManager) private var supabaseManager

    enum Action {
        case viewWillAppear
        case updateNickname(String)
        case updateImage(UIImage)
        case deleteImage
        case saveTapped
    }

    enum Mutation {
        case setLoading(Bool)
        case setSaving(Bool)
        case setProfile(UserProfileModel)
        case setNickname(String)
        case setSelectedImage(UIImage?)
        case setProfileImageDeleted(UserProfileModel)
        case setSaveCompleted(Bool)
        case setErrorMessage(String?)
    }

    struct State {
        var isLoading = false
        var isSaving = false
        var profile: UserProfileModel?
        var nickname = ""
        var selectedImage: UIImage?
        @Pulse var saveCompleted = false
        @Pulse var errorMessage: String?
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return loadProfile()

        case .updateNickname(let nickname):
            return .just(.setNickname(nickname))

        case .updateImage(let image):
            return .just(.setSelectedImage(image))

        case .deleteImage:
            return deleteProfileImage()

        case .saveTapped:
            return saveProfile()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setSaving(let isSaving):
            newState.isSaving = isSaving

        case .setProfile(let profile):
            newState.isLoading = false
            newState.profile = profile
            newState.nickname = profile.nickname

        case .setNickname(let nickname):
            newState.nickname = nickname

        case .setSelectedImage(let image):
            newState.selectedImage = image

        case .setProfileImageDeleted(let profile):
            newState.isSaving = false
            newState.profile = profile
            newState.selectedImage = nil

        case .setSaveCompleted(let completed):
            newState.isSaving = false
            newState.saveCompleted = completed

        case .setErrorMessage(let message):
            newState.isLoading = false
            newState.isSaving = false
            newState.errorMessage = message
        }

        return newState
    }

    private func loadProfile() -> Observable<Mutation> {
        Observable.create { observer in
            observer.onNext(.setLoading(true))

            let task = Task {
                do {
                    let profile: UserProfileModel
                    if let existingProfile = try await self.profileDBManager.fetchMyProfile() {
                        profile = existingProfile
                    } else {
                        profile = try await self.profileDBManager.createProfileIfNeeded()
                    }

                    observer.onNext(.setProfile(profile))
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage("프로필 정보를 불러오지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func saveProfile() -> Observable<Mutation> {
        Observable.create { observer in
            guard let profile = self.currentState.profile else {
                observer.onNext(.setErrorMessage("프로필 정보를 먼저 불러와주세요."))
                observer.onCompleted()
                return Disposables.create()
            }

            observer.onNext(.setSaving(true))

            let task = Task {
                do {
                    let imagePath: String?
                    if let selectedImage = self.currentState.selectedImage {
                        imagePath = try await self.supabaseManager.uploadProfileImage(selectedImage, userID: profile.id)
                    } else {
                        imagePath = profile.profileImageURL
                    }

                    _ = try await self.profileDBManager.updateMyProfile(
                        nickname: self.currentState.nickname,
                        profileImageURL: imagePath
                    )

                    observer.onNext(.setSaveCompleted(true))
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage("프로필을 저장하지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func deleteProfileImage() -> Observable<Mutation> {
        Observable.create { observer in
            guard let profile = self.currentState.profile else {
                observer.onNext(.setSelectedImage(nil))
                observer.onCompleted()
                return Disposables.create()
            }

            let storedImagePath = profile.profileImageURL
            guard storedImagePath?.isEmpty == false else {
                observer.onNext(.setSelectedImage(nil))
                observer.onCompleted()
                return Disposables.create()
            }

            observer.onNext(.setSaving(true))

            let task = Task {
                do {
                    let updatedProfile = try await self.profileDBManager.deleteMyProfileImage()

                    if let storedImagePath, !storedImagePath.isEmpty {
                        try? await self.supabaseManager.deleteProfileImage(path: storedImagePath)
                    }

                    observer.onNext(.setProfileImageDeleted(updatedProfile))
                    observer.onCompleted()
                } catch let error as AuthError {
                    observer.onNext(.setErrorMessage(error.userMessage))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setErrorMessage("프로필 사진을 삭제하지 못했어요. \(error.localizedDescription)"))
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
}
