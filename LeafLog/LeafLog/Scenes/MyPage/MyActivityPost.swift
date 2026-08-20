//
//  MyActivityPost.swift
//  LeafLog
//
//  Created by 김주희 on 8/19/26.
//

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
