//
//  CommunityTempViewController.swift
//  LeafLog
//
//  Created by OpenAI Codex on 7/30/26.
//

import Dependencies
import ReactorKit
import RxCocoa
import SnapKit
import UIKit

final class CommunityTempReactor: Reactor {
    @Dependency(\.communityPostDBManager)
    private var communityPostDBManager

    enum Action {
        case editLatestPostTapped
    }

    enum Mutation {
        case setLoading(Bool)
        case setLatestPost(CommunityPost)
        case setNoticeMessage(String)
        case setErrorMessage(String)
    }

    struct State {
        var isLoading = false
        @Pulse var latestPost: CommunityPost?
        @Pulse var noticeMessage: String?
        @Pulse var errorMessage: String?
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .editLatestPostTapped:
            return fetchLatestPost()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setLatestPost(let post):
            newState.latestPost = post
        case .setNoticeMessage(let message):
            newState.noticeMessage = message
        case .setErrorMessage(let message):
            newState.errorMessage = message
        }

        return newState
    }

    private func fetchLatestPost() -> Observable<Mutation> {
        guard !currentState.isLoading else { return .empty() }

        let fetchPost = Single<CommunityPost?>.create {
            [communityPostDBManager] in
            try await communityPostDBManager
                .fetchMyPosts(limit: 1, offset: 0)
                .first
        }
        .asObservable()
        .flatMap { post -> Observable<Mutation> in
            guard let post else {
                return .from([
                    .setLoading(false),
                    .setNoticeMessage("작성한 게시글이 없어요.")
                ])
            }

            return .from([
                .setLoading(false),
                .setLatestPost(post)
            ])
        }
        .catch { error in
            let message = (error as? AuthError)?.userMessage
                ?? "작성한 게시글을 불러오지 못했어요. 잠시 후 다시 시도해주세요."

            return .from([
                .setLoading(false),
                .setErrorMessage(message)
            ])
        }

        return .concat(
            .just(.setLoading(true)),
            fetchPost
        )
    }
}

final class CommunityTempViewController: BaseViewController, View {
    private let createButton = BottomSaveButton(title: "게시글 작성")
    private let editButton = BottomSaveButton(title: "최근 게시글 수정")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .grayScale50
        setLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func bind(reactor: CommunityTempReactor) {
        createButton.rx.tap
            .subscribe(with: self) { viewController, _ in
                viewController.steps.accept(AppStep.communityComposeCreate)
            }
            .disposed(by: disposeBag)

        editButton.rx.tap
            .map { CommunityTempReactor.Action.editLatestPostTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state
            .map(\.isLoading)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: editButton) { button, isLoading in
                button.isEnabled = !isLoading
                button.setTitle(
                    isLoading ? "게시글 불러오는 중" : "최근 게시글 수정"
                )
            }
            .disposed(by: disposeBag)

        reactor.pulse(\.$latestPost)
            .compactMap { $0 }
            .subscribe(with: self) { viewController, post in
                viewController.steps.accept(
                    AppStep.communityComposeEdit(post)
                )
            }
            .disposed(by: disposeBag)

        reactor.pulse(\.$noticeMessage)
            .compactMap { $0 }
            .subscribe(with: self) { viewController, message in
                viewController.steps.accept(
                    AppStep.alert("안내", message)
                )
            }
            .disposed(by: disposeBag)

        reactor.pulse(\.$errorMessage)
            .compactMap { $0 }
            .subscribe(with: self) { viewController, message in
                viewController.steps.accept(
                    AppStep.alert("오류", message)
                )
            }
            .disposed(by: disposeBag)
    }

    private func setLayout() {
        let stackView = UIStackView(
            arrangedSubviews: [createButton, editButton]
        )
        stackView.axis = .vertical
        stackView.spacing = 12

        view.addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.centerY.equalToSuperview()
        }

        [createButton, editButton].forEach {
            $0.snp.makeConstraints {
                $0.height.equalTo(48)
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    let viewController = CommunityTempViewController()
    viewController.reactor = CommunityTempReactor()
    return viewController
}
