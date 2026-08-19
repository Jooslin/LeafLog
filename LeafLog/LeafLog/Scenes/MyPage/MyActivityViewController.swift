//
//  MyActivityViewController.swift
//  LeafLog
//

import Dependencies
import OSLog
import RxCocoa
import RxSwift
import UIKit

final class MyActivityViewController: BaseViewController {
    @Dependency(\.communityPostDBManager) private var communityPostDBManager
    @Dependency(\.supabaseManager) private var supabaseManager

    private let myActivityView = MyActivityView()
    private var writtenPosts: [CommunityPost] = []
    private var authorNicknames: [UUID: String] = [:]
    private var authorProfileImageURLs: [UUID: URL] = [:]
    private var postImageURLs: [UUID: URL] = [:]
    private var selectedTab: MyActivityTab = .written
    private var sort: PlantCareTimelineSort = .latestFirst
    private var loadPostsTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "LeafLog", category: "MyActivityViewController")

    override func loadView() {
        view = myActivityView
    }

    override func viewDidLoad() {
        maximumDynamicTypeCategory = .accessibilityLarge
        super.viewDidLoad()

        myActivityView.headerView.rx.backButtonTap
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)

        myActivityView.segmentedControl.rx.selectedSegmentIndex
            .compactMap(MyActivityTab.init(rawValue:))
            .subscribe(onNext: { [weak self] tab in
                self?.selectedTab = tab
                self?.render(tab: tab)
            })
            .disposed(by: disposeBag)

        myActivityView.emptyActionButtonTap
            .compactMap { [weak self] in
                switch self?.selectedTab {
                case .written:
                    return AppStep.communityComposeCreate
                case .commented:
                    return AppStep.communityTab
                case nil:
                    return nil
                }
            }
            .bind(to: steps)
            .disposed(by: disposeBag)

        myActivityView.sortButtonTap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                sort = sort.toggled
                myActivityView.configureSortButton(sort: sort)
                render(tab: selectedTab)
            })
            .disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadWrittenPosts()
    }

    private func render(tab: MyActivityTab) {
        let unsortedPosts: [CommunityPost] = switch tab {
        case .written:
            writtenPosts
        case .commented:
            []
        }

        let posts = unsortedPosts.sorted { lhs, rhs in
            switch sort {
            case .latestFirst:
                return lhs.createdAt > rhs.createdAt
            case .oldestFirst:
                return lhs.createdAt < rhs.createdAt
            }
        }

        myActivityView.render(
            posts: posts,
            tab: tab,
            authorNicknames: authorNicknames,
            authorProfileImageURLs: authorProfileImageURLs,
            postImageURLs: postImageURLs
        )
    }

    private func loadWrittenPosts() {
        loadPostsTask?.cancel()
        loadPostsTask = Task { [weak self] in
            guard let self else { return }

            do {
                let posts = try await communityPostDBManager.fetchMyPosts()
                let publicProfiles = try await communityPostDBManager.fetchPublicProfiles(
                    authorIDs: posts.map(\.authorID)
                )
                let nicknames = publicProfiles.compactMapValues(\.nickname)
                let profileImageURLs = await communityPostDBManager
                    .resolvePublicProfileImageURLs(profiles: publicProfiles)

                var resolvedImageURLs: [UUID: URL] = [:]
                for post in posts {
                    guard let imagePath = post.firstImagePath else { continue }

                    do {
                        if let imageURL = try await supabaseManager.resolveCommunityPostImageURL(
                            from: imagePath,
                            cacheKey: post.id.uuidString
                        ) {
                            resolvedImageURLs[post.id] = imageURL
                        }
                    } catch {
                        logger.error(
                            "Community post image URL resolution failed. postID: \(post.id.uuidString, privacy: .public), error: \(String(describing: error), privacy: .private)"
                        )
                    }
                }

                guard !Task.isCancelled else { return }
                writtenPosts = posts
                authorNicknames = nicknames
                authorProfileImageURLs = profileImageURLs
                postImageURLs = resolvedImageURLs
                render(tab: selectedTab)
            } catch {
                guard !Task.isCancelled else { return }
                let message = (error as? AuthError)?.userMessage
                    ?? "작성한 게시글을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
                steps.accept(AppStep.alert("오류", message))
            }
        }
    }
}
