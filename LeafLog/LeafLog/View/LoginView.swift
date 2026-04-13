//
//  LoginView.swift
//  LeafLog
//
//  Created by 김주희 on 4/5/26.
//

import UIKit
import SnapKit
import Then
import AuthenticationServices

final class LoginView: UIView {
    
    // MARK: - UI Components
    
    private let logoImageView = UIImageView(image: UIImage(named: "launch_logo"))
    
    let logoLabel = UILabel(text: "나만의 식물 다이어리", config: .headline18, color: UIColor(named: "#4A4A4A"))
    
    let googleLoginButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        var titleAttr = AttributedString("Google로 시작하기")
        titleAttr.font = .systemFont(ofSize: 16, weight: .semibold)
        config.attributedTitle = titleAttr
        config.baseForegroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
        config.image = UIImage(named: "google")
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.background.backgroundColor = .white
        config.background.cornerRadius = 8
        config.background.strokeWidth = 1
        config.background.strokeColor = UIColor(red: 0.85, green: 0.86, blue: 0.88, alpha: 1)
        
        $0.configuration = config
    }

    let kakaoLoginButton = UIButton().then {
        var config = UIButton.Configuration.filled() // 배경색이 있는 스타일
        var titleAttr = AttributedString("카카오로 시작하기")
        titleAttr.font = .systemFont(ofSize: 16, weight: .semibold)
        config.attributedTitle = titleAttr
        config.baseForegroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
        config.image = UIImage(named: "kakao")
        config.imagePadding = 8
        config.background.backgroundColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        config.background.cornerRadius = 8
        
        $0.configuration = config
    }
    
    let appleLoginButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signUp, authorizationButtonStyle: .black)
    
    let privacyLabel = UILabel(text: "시작하면 이용약관 및 개인정보처리방침에 동의하게 됩니다.", config: .label12, color: UIColor(named: "#303030"))
    
    
    // MARK: -  Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    
    // MARK: - UI Setup
    private func setupUI() {
        [logoImageView, logoLabel, appleLoginButton, kakaoLoginButton, googleLoginButton, privacyLabel].forEach { addSubview($0) }
        
        privacyLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(70.5159)
        }
        
        googleLoginButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(50)
            $0.width.equalTo(345)
            $0.bottom.equalTo(privacyLabel.snp.top).offset(-106)
        }
        
        kakaoLoginButton.snp.makeConstraints {
            $0.centerX.height.width.equalTo(googleLoginButton)
            $0.bottom.equalTo(googleLoginButton.snp.top).offset(-16)
        }
        
        appleLoginButton.snp.makeConstraints {
            $0.centerX.height.width.equalTo(googleLoginButton)
            $0.bottom.equalTo(kakaoLoginButton.snp.top).offset(-16)
        }
        
        logoLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(appleLoginButton.snp.top).offset(-106)
        }
        
        logoImageView.snp.makeConstraints {
            $0.width.equalTo(148)
            $0.height.equalTo(109)
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(logoLabel.snp.top).offset(-24)
        }
    }
}
