//
//  UICollectionView+Pagination.swift
//  LeafLog
//
//  Created by 김주희 on 11/4/26.
//

import RxCocoa
import RxSwift
import UIKit

extension Reactive where Base: UICollectionView {
    /// 단일 섹션 게시글 목록의 추가 조회 및 실패 후 스크롤 재시도 신호.
    var loadNextPage: Observable<Void> {
        let approachingLastItem = willDisplayCell
            .filter { [weak base] _, indexPath in
                guard let base, base.numberOfSections > 0 else { return false }
                let count = base.numberOfItems(inSection: 0)
                return count > 0 && indexPath.item >= count - 5
            }
            .map { _ in () }

        let scrollingNearBottom = didScroll
            .filter { [weak base] in
                guard let base, base.numberOfSections > 0,
                      base.numberOfItems(inSection: 0) > 0,
                      base.isDragging || base.isDecelerating else { return false }
                return base.contentOffset.y + base.bounds.height >= base.contentSize.height - 500
            }

        return Observable.merge(approachingLastItem, scrollingNearBottom)
    }
}
