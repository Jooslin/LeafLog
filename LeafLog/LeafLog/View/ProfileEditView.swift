//
//  ProfileEditView.swift
//  LeafLog
//
//  Created by OpenAI Codex on 4/13/26.
//

import UIKit
import SnapKit
import Then

final class ProfileEditView: UIView {

    let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 50
        $0.backgroundColor = .systemGray5
        $0.image = UIImage(named: "userEmpty") ?? UIImage(systemName: "person.crop.circle.fill")
        $0.tintColor = .systemGray
    }

    let imageButton = UIButton(type: .system).then {
        $0.tintColor = .clear
    }

    let cameraButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = .systemBlue
        $0.layer.cornerRadius = 16
    }

    let nicknameTextField = UITextField().then {
        $0.placeholder = "닉네임을 입력해주세요"
        $0.borderStyle = .roundedRect
        $0.clearButtonMode = .whileEditing
    }

    let providerTitleLabel = UILabel().then {
        $0.text = "Provider"
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .secondaryLabel
    }

    let providerValueLabel = UILabel().then {
        $0.text = "-"
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .label
    }

    let emailTitleLabel = UILabel().then {
        $0.text = "이메일"
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .secondaryLabel
    }

    let emailValueLabel = UILabel().then {
        $0.text = "-"
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    let saveButton = UIButton(type: .system).then {
        $0.setTitle("저장", for: .normal)
    }

    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 16
        $0.alignment = .fill
    }

    private let providerStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 6
        $0.alignment = .fill
    }

    private let emailStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 6
        $0.alignment = .fill
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(contentStackView)

        contentStackView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(24)
        }

        profileImageView.snp.makeConstraints {
            $0.size.equalTo(100)
        }

        let imageContainerView = UIView()
        imageContainerView.addSubview(imageButton)
        imageButton.addSubview(profileImageView)
        imageButton.addSubview(cameraButton)

        imageButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(100)
            $0.verticalEdges.equalToSuperview()
        }

        profileImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        cameraButton.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview()
            $0.size.equalTo(32)
        }

        providerStackView.addArrangedSubview(providerTitleLabel)
        providerStackView.addArrangedSubview(providerValueLabel)

        emailStackView.addArrangedSubview(emailTitleLabel)
        emailStackView.addArrangedSubview(emailValueLabel)

        contentStackView.addArrangedSubview(imageContainerView)
        contentStackView.addArrangedSubview(nicknameTextField)
        contentStackView.addArrangedSubview(providerStackView)
        contentStackView.addArrangedSubview(emailStackView)
        contentStackView.addArrangedSubview(saveButton)
    }
}
