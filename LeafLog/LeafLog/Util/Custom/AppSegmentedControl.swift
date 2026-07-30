//
//  AppSegmentedControl.swift
//  LeafLog
//

import UIKit

final class AppSegmentedControl: UISegmentedControl {
    init(items: [String]) {
        super.init(items: items)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        selectedSegmentIndex = 0
        backgroundColor = .grayScale50
        selectedSegmentTintColor = .primary600

        setTitleTextAttributes([
            .foregroundColor: UIColor.grayScale400,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ], for: .normal)

        setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ], for: .selected)
    }
}
