//
//  MyActivityPost.swift
//  LeafLog
//

import Foundation

nonisolated enum MyActivityTab: Int {
    case written
    case commented

    var emptyTitle: String {
        switch self {
        case .written:
            return "아직 작성한 글이 없어요"
        case .commented:
            return "아직 댓글단 글이 없어요"
        }
    }

    var emptyDescription: String {
        switch self {
        case .written:
            return "궁금한 점을 질문하거나\n식물 이야기를 나눠보세요"
        case .commented:
            return "궁금한 식물 이야기를 찾아\n댓글로 함께해보세요"
        }
    }

    var emptyButtonTitle: String {
        switch self {
        case .written:
            return "커뮤니티 글쓰기"
        case .commented:
            return "커뮤니티 둘러보기"
        }
    }
}

nonisolated struct MyActivityPost: Hashable, Sendable {
    let id: UUID
    let title: String
    let nickname: String
    let date: String
    let body: String
    let likeCount: String
    let commentCount: String
    let imageName: String?
    let showsSeparator: Bool
}

extension MyActivityPost {
    static func mockPosts() -> [MyActivityPost] {
        [
            MyActivityPost(
                id: UUID(),
                title: "우리집 몬스테라 새잎이 나왔어요!",
                nickname: "뿡뿡뿡이",
                date: "2026.06.27",
                body: "드디어 새잎이 쏙 나왔어요. 매일 보는 즐거움이 있답니다! 몬스테라 후기 남겨요. 너무 이쁘네요.. 여러분들의 몬스테라는 어떤가요?",
                likeCount: "12",
                commentCount: "4",
                imageName: "myActivityCactus",
                showsSeparator: true
            ),
            MyActivityPost(
                id: UUID(),
                title: "저희 집 선인장이 갑자기 쭈그러들었어요..",
                nickname: "식물왕",
                date: "2026.04.27",
                body: "드디어 새잎이 쏙 나왔어요. 매일 보는 즐거움이 있답니다! 몬스테라 후기 남겨요 열심히 키워봅시다",
                likeCount: "132",
                commentCount: "25",
                imageName: nil,
                showsSeparator: true
            ),
            MyActivityPost(
                id: UUID(),
                title: "우리집 몬스테라 새잎이 나왔어요!",
                nickname: "몬스테라 수집가",
                date: "2026.02.27",
                body: "드디어 새잎이 쏙 나왔어요. 매일 보는 즐거움이 있답니다! 몬스테라 후기 남겨요...",
                likeCount: "90",
                commentCount: "32",
                imageName: "myActivityCactus",
                showsSeparator: false
            )
        ]
    }
}
