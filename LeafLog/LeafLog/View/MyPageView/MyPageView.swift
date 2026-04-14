//
//  MyPageView.swift
//  LeafLog
//
//  Created by 김주희 on 4/14/26.
//


import UIKit
import SnapKit
import Then

final class MyPageView: UIView {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
    }
    
    private let mainStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.alignment = .fill
    }
    
    private let profileCardView = UIView().then {
        $0.backgroundColor = .grayScale50
        $0.layer.cornerRadius = 12
    }
    
    private let profileTextStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 2
        $0.alignment = .fill
    }
    
    private let profileChevronImageView = UIImageView().then {
        $0.image = .arrowRight
        $0.contentMode = .scaleAspectFit
    }
    
    let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 32
        $0.backgroundColor = .grayScale100
        $0.image = .userEmpty
    }
    
    let nicknameLabel = UILabel().then {
        $0.apply(.title16, color: .black, lines: 1)
        $0.text = "User1234"
    }
    
    let emailLabel = UILabel().then {
        $0.apply(.label14, color: .grayScale600, lines: 1)
        $0.text = "email@email.com"
    }
    
    let editProfileButton = UIButton(type: .system).then {
        $0.backgroundColor = .clear
        $0.tintColor = .clear
        $0.accessibilityLabel = "프로필 수정"
    }
    
    // 푸시알림 스위치
    let pushAlertSwitch = UISwitch().then {
        $0.onTintColor = .primary600
        $0.isOn = true
    }
    
    let versionValueLabel = UILabel().then {
        $0.apply(.body14, color: .black)
        $0.textAlignment = .right
    }
    
    // 각 Row를 터치할 버튼들
    let inquiryButton = UIButton(type: .system)
    let reportErrorButton = UIButton(type: .system)
    let privacyPolicyButton = UIButton(type: .system)
    let termsButton = UIButton(type: .system)
    let logoutButton = UIButton(type: .system)
    let withdrawalButton = UIButton(type: .system)
    
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        
        setupButtons()
        setupUI()
        applyVersionText()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupButtons() {
        // 버튼 시각 효과
        editProfileButton.addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        editProfileButton.addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit, .touchUpOutside])
    }
    
    private func setupUI() {
        addSubview(scrollView)
        scrollView.addSubview(mainStackView)
        
        scrollView.snp.makeConstraints {
            $0.horizontalEdges.top.equalTo(safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }
        
        mainStackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(32)
            $0.bottom.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.width.equalToSuperview().offset(-32)
        }
        
        // 1. 프로필 카드 설정
        setupProfileCard()
        mainStackView.addArrangedSubview(profileCardView)
        mainStackView.setCustomSpacing(32, after: profileCardView) // 카드와 아래 메뉴 사이 띄우기
        
        // 2. 알림 설정 섹션
        let alertTitle = makeSectionTitle("알림 설정")
        mainStackView.addArrangedSubview(alertTitle)
        mainStackView.setCustomSpacing(16, after: alertTitle)
        mainStackView.addArrangedSubview(makeRow(title: "푸시알림", accessory: pushAlertSwitch, showSeparator: true))
        mainStackView.addArrangedSubview(makeSpacer(height: 32))
        
        // 3. 고객 지원 섹션
        let supportTitle = makeSectionTitle("고객 지원")
        mainStackView.addArrangedSubview(supportTitle)
        mainStackView.setCustomSpacing(16, after: supportTitle)
        mainStackView.addArrangedSubview(makeRow(title: "문의하기", button: inquiryButton))
        mainStackView.setCustomSpacing(4, after: inquiryButton)
        mainStackView.addArrangedSubview(makeRow(title: "오류신고", button: reportErrorButton))
        mainStackView.addArrangedSubview(makeSpacer(height: 32))
        
        // 4. 앱 정보 섹션
        let infoTitle = makeSectionTitle("앱 정보")
        mainStackView.addArrangedSubview(infoTitle)
        mainStackView.setCustomSpacing(16, after: infoTitle)
        mainStackView.addArrangedSubview(makeRow(title: "개인정보처리방침", button: privacyPolicyButton))
        mainStackView.setCustomSpacing(4, after: privacyPolicyButton)
        mainStackView.addArrangedSubview(makeRow(title: "이용약관", button: termsButton))
        mainStackView.setCustomSpacing(4, after: termsButton)
        mainStackView.addArrangedSubview(makeRow(title: "버전", accessory: versionValueLabel))
        
        mainStackView.addArrangedSubview(makeSpacer(height: 32))
        
        // 5. 계정 관리 섹션
        let accountTitle = makeSectionTitle("계정 관리")
        mainStackView.addArrangedSubview(accountTitle)
        mainStackView.setCustomSpacing(16, after: accountTitle)
        mainStackView.addArrangedSubview(makeRow(title: "로그아웃", button: logoutButton))
        mainStackView.setCustomSpacing(4, after: logoutButton)
        mainStackView.addArrangedSubview(makeRow(title: "회원탈퇴", button: withdrawalButton, titleColor: .subRed))
    }
    
    // 프로필 카드 내부 설정
    private func setupProfileCard() {
        profileCardView.snp.makeConstraints {
            $0.height.equalTo(96)
        }
        
        profileTextStackView.addArrangedSubview(nicknameLabel)
        profileTextStackView.addArrangedSubview(emailLabel)
        
        [profileImageView, profileTextStackView, profileChevronImageView, editProfileButton].forEach {
            profileCardView.addSubview($0)
        }
        
        profileImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(64)
        }
        
        profileChevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
        
        profileTextStackView.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(16)
            $0.trailing.lessThanOrEqualTo(profileChevronImageView.snp.leading).offset(-16) // 길어졌을때 화살표 침범 방지
            $0.centerY.equalToSuperview()
        }
        
        editProfileButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    // 앱 버전 꺼내오기
    private func applyVersionText() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        versionValueLabel.text = version
    }
    
    // MARK: - Component Builders
    private func makeSectionTitle(_ text: String) -> UIView {
        let label = UILabel().then {
            $0.text = text
            $0.apply(.title14, color: .black)
        }
        return label
    }
    
    private func makeRow(title: String, accessory: UIView? = nil, button: UIButton? = nil, titleColor: UIColor = .black, showSeparator: Bool = true) -> UIView {
        let rowView = UIView()
        rowView.snp.makeConstraints { $0.height.equalTo(48) }
        
        let titleLabel = UILabel().then {
            $0.text = title
            $0.apply(.label14, color: titleColor)
        }
        rowView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }
        
        if let accessory {
            rowView.addSubview(accessory)
            accessory.snp.makeConstraints {
                $0.trailing.centerY.equalToSuperview()
                $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
            }
        }
        
        if let button {
            rowView.addSubview(button)
            button.setTitle(nil, for: .normal)
            button.backgroundColor = .clear
            button.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
        
        if showSeparator {
            let separator = UIView().then { $0.backgroundColor = .grayScale50 }
            rowView.addSubview(separator)
            separator.snp.makeConstraints {
                $0.horizontalEdges.equalToSuperview().inset(-16)
                $0.bottom.equalToSuperview()
                $0.height.equalTo(1)
            }
        }
        return rowView
    }
    
    private func makeSpacer(height: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(height) }
        return spacer
    }
    
    // MARK: - Actions
    @objc private func handleTouchDown() {
        profileCardView.alpha = 0.7
    }
    
    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.18) {
            self.profileCardView.alpha = 1
        }
    }
}

@available(iOS 17.0,*)
#Preview {
    MyPageViewController()
}
