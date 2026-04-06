//
//  LoginView.swift
//  LeafLog
//
//  Created by 김주희 on 4/5/26.
//

import UIKit
import SnapKit
import Then

final class LoginView: UIView {
    
    // MARK: - UI Components
    let googleLoginButton = UIButton().then {
        $0.setTitle("Google로 시작하기", for: .normal)
        $0.setTitleColor(.black, for: .normal)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 8
        $0.titleLabel?.font = .boldSystemFont(ofSize: 16)
    }
    
    let kakaoLoginButton = UIButton().then {
        $0.setTitle("카카오톡으로 시작하기", for: .normal)
        $0.setTitleColor(.black, for: .normal)
        $0.backgroundColor = .systemYellow
        $0.layer.cornerRadius = 8
        $0.titleLabel?.font = .boldSystemFont(ofSize: 16)

    }
    
    let appleLoginButton = UIButton().then {
        $0.setTitle("Apple로 시작하기", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 8
        $0.titleLabel?.font = .boldSystemFont(ofSize: 16)
    }
    
    
    // MARK: -  Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    
    // MARK: - UI Setup
    private func setupUI() {
        [kakaoLoginButton, googleLoginButton, appleLoginButton].forEach { addSubview($0) }
        
        kakaoLoginButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-30)
            $0.height.equalTo(50)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        googleLoginButton.snp.makeConstraints {
            $0.top.equalTo(kakaoLoginButton.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.height.horizontalEdges.equalTo(kakaoLoginButton)
        }
        
        appleLoginButton.snp.makeConstraints {
            $0.top.equalTo(googleLoginButton.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.height.horizontalEdges.equalTo(kakaoLoginButton)
        }
    }
}
