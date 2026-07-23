//
//  MyActivityView.swift
//  LeafLog
//

import SnapKit
import UIKit

final class MyActivityView: UIView {
    let headerView = TitleHeaderView(text: "내 활동", hasBackButton: true)

    private let emptyView = EmptyView(
        image: OthersImageAsset.chatColored.rawValue,
        title: "아직 활동 내역이 없어요",
        subTitle: "커뮤니티에서 활동하면\n여기에 모아볼 수 있어요.",
        needButton: false
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(headerView)
        addSubview(emptyView)

        headerView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(48)
        }

        emptyView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
}
