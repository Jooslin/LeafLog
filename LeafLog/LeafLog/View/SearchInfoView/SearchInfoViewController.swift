//
//  SearchInfoViewController.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/15/26.
//
import SnapKit
import Then
import UIKit

final class SearchInfoViewController: UIViewController {
    private let infoView = SearchInfoView()
    private let dimmedView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.20)
    }
    private let cardContainerView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 12
        $0.layer.masksToBounds = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = .clear
        setupUI()
        bindUI()
    }

    private func setupUI() {
        view.addSubview(dimmedView)
        view.addSubview(cardContainerView)
        cardContainerView.addSubview(infoView)

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        cardContainerView.snp.makeConstraints {
            $0.centerY.equalToSuperview().priority(750)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.verticalEdges.greaterThanOrEqualTo(view.safeAreaLayoutGuide).inset(65)
        }

        infoView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func bindUI() {
        dimmedView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTapDimmedView))
        )

        infoView.closeButton.addAction(
            UIAction { [weak self] _ in
                self?.dismiss(animated: false)
            },
            for: .touchUpInside
        )
    }

    @objc private func didTapDimmedView() {
        dismiss(animated: false)
    }
}
