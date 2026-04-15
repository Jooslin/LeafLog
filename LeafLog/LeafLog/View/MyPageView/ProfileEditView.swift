//
//  ProfileEditView.swift
//  LeafLog
//
//  Created by 김주희 on 4/13/26.
//

import UIKit
import SnapKit
import Then

final class ProfileEditView: UIView {
    
    // MARK: - UI Components
    
    let profileEditHeaderView = TitleHeaderView(text: "정보 수정", hasBackButton: true)
    
    // 키보드에 가려지는 것을 방지하기 위해 스크롤뷰 추가
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .onDrag // 스크롤 시 키보드 내리기
    }
    private let contentView = UIView()
    
    // 프사 삽입 버튼
    let profileImageButton = CameraProfileButton().then {
        $0.layer.cornerRadius = 70
        $0.clipsToBounds = true
    }
    
    // 이름
    private let nameTitleLabel = UILabel().then {
        $0.text = "이름"
        $0.apply(.title14, color: .black)
    }
    
    let nameTextField = UITextField().then {
        $0.placeholder = "이름을 입력해주세요"
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.clearButtonMode = .whileEditing
        $0.layer.borderColor = UIColor.grayScale100.cgColor
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        $0.leftView = paddingView
        $0.leftViewMode = .always
    }
    
    
    // 로그인 정보 섹션
    private let loginInfoTitleLabel = UILabel().then {
        $0.text = "로그인 정보"
        $0.apply(.title14, color: .black)
    }
    
    private let loginInfoContainerView = UIView().then {
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
    let providerIconImageView = UIImageView().then {
        $0.image = .kakao
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 18
        $0.clipsToBounds = true
    }
    
    let providerValueLabel = UILabel().then {
        $0.apply(.title16, color: .black)
    }
    
    let providerDescriptionLabel = UILabel().then {
        $0.apply(.body14, color: .grayScale600)
    }
    
    let saveButton = BottomSaveButton(title: "수정하기")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        [profileEditHeaderView, scrollView, saveButton].forEach { addSubview($0) }
        scrollView.addSubview(contentView)
        
        profileEditHeaderView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(64)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(48)
        }
        
        
        saveButton.snp.makeConstraints {
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.height.equalTo(48)
        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(profileEditHeaderView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(saveButton.snp.top).offset(-16)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
        
        // 내부 요소들 조립
        [profileImageButton, nameTitleLabel, nameTextField, loginInfoTitleLabel, loginInfoContainerView].forEach {
            contentView.addSubview($0)
        }
        
        let providerTextStack = UIStackView(arrangedSubviews: [providerValueLabel, providerDescriptionLabel]).then {
            $0.axis = .vertical
            $0.spacing = 0
        }
        
        [providerIconImageView, providerTextStack].forEach {
            loginInfoContainerView.addSubview($0)
        }
        
        profileImageButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.centerX.equalToSuperview()
        }
        
        nameTitleLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageButton.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        nameTextField.snp.makeConstraints {
            $0.top.equalTo(nameTitleLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalTo(nameTitleLabel)
            $0.height.equalTo(48)
        }
        
        loginInfoTitleLabel.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom).offset(24)
            $0.horizontalEdges.equalTo(nameTitleLabel)
        }
        
        loginInfoContainerView.snp.makeConstraints {
            $0.top.equalTo(loginInfoTitleLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalTo(nameTitleLabel)
            $0.height.equalTo(68)
            $0.bottom.equalToSuperview().offset(-32)
        }
        
        providerIconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(36)
        }
        
        providerTextStack.snp.makeConstraints {
            $0.leading.equalTo(providerIconImageView.snp.trailing).offset(16)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(16)
        }
    }
}
