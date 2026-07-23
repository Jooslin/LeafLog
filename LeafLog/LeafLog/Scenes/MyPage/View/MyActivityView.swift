//
//  MyActivityView.swift
//  LeafLog
//

import SnapKit
import UIKit

final class MyActivityView: UIView {
    let headerView = TitleHeaderView(text: "내 활동", hasBackButton: true)

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

        headerView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(48)
        }
    }
}
