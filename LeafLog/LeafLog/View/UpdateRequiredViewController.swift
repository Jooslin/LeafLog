//
//  UpdateRequiredViewController.swift
//  LeafLog
//
//  Created by 김주희 on 5/1/26.
//

import Dependencies
import SnapKit
import Then
import UIKit
internal import System

// MARK: - 강제 업데이트 전용 화면
final class UpdateRequiredViewController: UIViewController {
    @Dependency(\.uiApplication) private var uiApplication

    private let message: String
    private let storeURL: URL

    private let logoImageView = UIImageView(image: .launchLogoSquare).then {
        $0.contentMode = .scaleAspectFit
    }

    private let titleLabel = UILabel().then {
        $0.text = "업데이트가 필요해요"
        $0.textColor = .grayScale900
        $0.font = .systemFont(ofSize: 24, weight: .bold)
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }

    private lazy var messageLabel = UILabel().then {
        $0.text = message
        $0.textColor = .grayScale600
        $0.font = .systemFont(ofSize: 16, weight: .regular)
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }

    private let updateButton = BottomSaveButton(title: "업데이트하기")

    init(message: String, storeURL: URL) {
        self.message = message
        self.storeURL = storeURL
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupAction()
    }

    private func setupUI() {
        [logoImageView, titleLabel, messageLabel, updateButton].forEach {
            view.addSubview($0)
        }

        logoImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-120)
            $0.width.height.equalTo(120)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(logoImageView.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview().inset(32)
        }

        messageLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(32)
        }

        updateButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(52)
        }
    }

    private func setupAction() {
        updateButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.uiApplication.open(self.storeURL)
        }, for: .touchUpInside)
    }
}
