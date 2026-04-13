//
//  MyPageView.swift
//  LeafLog
//
//  Created by OpenAI Codex on 4/13/26.
//

import UIKit
import SnapKit
import Then

final class MyPageView: UIView {

    // 프로필 이미지는 VC에서 실제 이미지 또는 기본 이미지를 넣어줌
    let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 50
        $0.backgroundColor = .systemGray5
        $0.image = UIImage(named: "userEmpty") ?? UIImage(systemName: "person.crop.circle.fill")
        $0.tintColor = .systemGray
    }

    let nicknameLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .label
        $0.textAlignment = .center
    }

    let emailLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }

    let editProfileButton = UIButton(type: .system).then {
        $0.setTitle("정보 수정", for: .normal)
    }

    let logoutButton = UIButton(type: .system).then {
        $0.setTitle("로그아웃", for: .normal)
    }

    let withdrawalButton = UIButton(type: .system).then {
        $0.setTitle("회원탈퇴", for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
    }

    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 16
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

        let imageContainer = UIView()
        imageContainer.addSubview(profileImageView)
        profileImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.verticalEdges.equalToSuperview()
        }

        contentStackView.addArrangedSubview(imageContainer)
        contentStackView.addArrangedSubview(nicknameLabel)
        contentStackView.addArrangedSubview(emailLabel)
        contentStackView.addArrangedSubview(editProfileButton)
        contentStackView.addArrangedSubview(logoutButton)
        contentStackView.addArrangedSubview(withdrawalButton)
    }
}
