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
    
    private let logoImageView = UIImageView(image: .launchLogo)
    
    let logoLabel = UILabel(text: "나만의 식물 다이어리", config: .headline18, color: .grayScale700)
    
    let googleLoginButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        var titleAttr = AttributedString("Google로 로그인")
        titleAttr.font = .systemFont(ofSize: 18, weight: .semibold)
        config.attributedTitle = titleAttr
        config.baseForegroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
        config.image = UIImage(named: "google")
        config.imagePadding = 4
        config.imagePlacement = .leading
        config.background.backgroundColor = .white
        config.background.cornerRadius = 8
        config.background.strokeWidth = 1
        config.background.strokeColor = UIColor(red: 0.85, green: 0.86, blue: 0.88, alpha: 1)
        
        $0.configuration = config
    }

    let kakaoLoginButton = UIButton().then {
        var config = UIButton.Configuration.filled() // 배경색이 있는 스타일
        var titleAttr = AttributedString("카카오로 로그인")
        titleAttr.font = .systemFont(ofSize: 18, weight: .semibold)
        config.attributedTitle = titleAttr
        config.baseForegroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
        config.image = UIImage(named: "kakao")
        config.imagePadding = 4
        config.background.backgroundColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        config.background.cornerRadius = 8
        
        $0.configuration = config
    }
    
    let appleLoginButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black)

    private let appleLoginCooldownLabel = UILabel(
        text: "",
        config: .label12,
        color: .subRed,
        lines: 0
    ).then {
        $0.textAlignment = .center
        $0.isHidden = true
    }

    private let agreementPrefixLabel = UILabel(text: "시작하면 ", config: .label12, color: .grayScale800)
    let termsButton = UIButton(type: .system)
    private let agreementMiddleLabel = UILabel(text: " 및 ", config: .label12, color: .grayScale800)
    let privacyPolicyButton = UIButton(type: .system)
    private let agreementSuffixLabel = UILabel(text: "에 동의하게 됩니다.", config: .label12, color: .grayScale800)

    private let agreementStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 0
    }

    // MARK: -  Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupAgreementButtons()
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    
    // MARK: - UI Setup
    private func setupUI() {
        [
            logoImageView,
            logoLabel,
            appleLoginButton,
            appleLoginCooldownLabel,
            kakaoLoginButton,
            googleLoginButton,
            agreementStackView
        ].forEach { addSubview($0) }

        [
            agreementPrefixLabel,
            termsButton,
            agreementMiddleLabel,
            privacyPolicyButton,
            agreementSuffixLabel
        ].forEach { agreementStackView.addArrangedSubview($0) }

        agreementStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(70)
        }

        googleLoginButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(50)
            $0.horizontalEdges.equalToSuperview().inset(15)
            $0.bottom.equalTo(agreementStackView.snp.top).offset(-106)
        }
        
        kakaoLoginButton.snp.makeConstraints {
            $0.centerX.height.equalTo(googleLoginButton)
            $0.horizontalEdges.equalTo(googleLoginButton)
            $0.bottom.equalTo(googleLoginButton.snp.top).offset(-16)
        }

        appleLoginCooldownLabel.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalTo(kakaoLoginButton.snp.top).offset(-8)
        }
        
        appleLoginButton.snp.makeConstraints {
            $0.centerX.height.equalTo(googleLoginButton)
            $0.horizontalEdges.equalToSuperview().inset(15)
            $0.bottom.equalTo(appleLoginCooldownLabel.snp.top).offset(-8)
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

    func setAppleLoginCooldownVisible(_ isVisible: Bool) {
        appleLoginCooldownLabel.text = isVisible ? "Apple 계정 연결 해제 처리 중입니다. 잠시 후 다시 시도해주세요." : nil
        appleLoginCooldownLabel.isHidden = !isVisible
        appleLoginButton.alpha = isVisible ? 0.45 : 1
    }

    private func setupAgreementButtons() {
        configureAgreementLinkButton(termsButton, title: "이용약관")
        configureAgreementLinkButton(privacyPolicyButton, title: "개인정보처리방침")
    }

    private func configureAgreementLinkButton(_ button: UIButton, title: String) {
        let font = UIFontMetrics(forTextStyle: .footnote).scaledFont(
            for: .systemFont(ofSize: 12, weight: .medium)
        )
        let attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: font,
                .foregroundColor: UIColor.grayScale800,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )

        button.setAttributedTitle(attributedTitle, for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityTraits.insert(.link)
    }
}
