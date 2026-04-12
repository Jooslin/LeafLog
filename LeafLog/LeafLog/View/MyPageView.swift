//
//  MyPageView.swift
//  LeafLog
//
//  Created by OpenAI Codex on 4/12/26.
//

import UIKit
import SnapKit
import Then

final class MyPageView: UIView {

    // 프로필 카드 버튼 (상세화면으로 이동)
    let profileCardButton = UIButton(type: .system).then {
        $0.backgroundColor = UIColor(white: 0.97, alpha: 1)
        $0.layer.cornerRadius = 20
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(white: 0.92, alpha: 1).cgColor
    }

    // 프로필 사진
    let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 40
        $0.backgroundColor = UIColor(red: 0.84, green: 0.89, blue: 0.98, alpha: 1)
        $0.image = UIImage(named: "userEmpty") ?? UIImage(systemName: "person.crop.circle.fill")
    }

    // 닉네임
    let nicknameLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 18)
        $0.textColor = .black
        $0.text = "프로필을 불러오는 중..."
    }

    // 이메일
    let emailLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .darkGray
        $0.numberOfLines = 1
    }

    // 꺽쇠
    let chevronImageView = UIImageView().then {
        $0.image = UIImage(systemName: "chevron.right")
        $0.tintColor = .black
        $0.contentMode = .scaleAspectFit
    }

    let accountSectionLabel = UILabel().then {
        $0.text = "계정 관리"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .black
    }

    let logoutButton = MyPageRowButton(title: "로그아웃")
    let withdrawalButton = MyPageRowButton(title: "회원탈퇴", isDestructive: true)


    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    private func setupUI() {
        let profileTextStackView = UIStackView(arrangedSubviews: [nicknameLabel, emailLabel]).then {
            $0.axis = .vertical
            $0.spacing = 6
            $0.alignment = .leading
        }

        let profileContentStackView = UIStackView(arrangedSubviews: [profileImageView, profileTextStackView, chevronImageView]).then {
            $0.axis = .horizontal
            $0.spacing = 16
            $0.alignment = .center
        }

        let accountStackView = UIStackView(arrangedSubviews: [logoutButton, withdrawalButton]).then {
            $0.axis = .vertical
            $0.spacing = 0
        }

        addSubview(profileCardButton)
        addSubview(accountSectionLabel)
        addSubview(accountStackView)

        profileCardButton.addSubview(profileContentStackView)

        profileCardButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(118)
        }

        profileContentStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(20)
        }

        profileImageView.snp.makeConstraints {
            $0.size.equalTo(80)
        }

        chevronImageView.snp.makeConstraints {
            $0.size.equalTo(18)
        }

        accountSectionLabel.snp.makeConstraints {
            $0.top.equalTo(profileCardButton.snp.bottom).offset(36)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        accountStackView.snp.makeConstraints {
            $0.top.equalTo(accountSectionLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
    }
}


// 커스텀 버튼
final class MyPageRowButton: UIButton {

    private let titleText: String
    private let isDestructive: Bool

    init(title: String, isDestructive: Bool = false) {
        self.titleText = title
        self.isDestructive = isDestructive
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 16
        contentHorizontalAlignment = .fill

        let titleLabel = UILabel().then {
            $0.text = titleText
            $0.font = .systemFont(ofSize: 17, weight: .medium)
            $0.textColor = isDestructive ? .systemRed : .black
        }

        let chevronView = UIImageView().then {
            $0.image = UIImage(systemName: "chevron.right")
            $0.tintColor = isDestructive ? .systemRed : .black
            $0.contentMode = .scaleAspectFit
        }

        let separatorView = UIView().then {
            $0.backgroundColor = UIColor(white: 0.93, alpha: 1)
        }

        addSubview(titleLabel)
        addSubview(chevronView)
        addSubview(separatorView)

        snp.makeConstraints {
            $0.height.equalTo(66)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        chevronView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }

        separatorView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
}
