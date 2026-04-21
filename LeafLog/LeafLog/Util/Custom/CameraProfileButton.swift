//
//  CameraProfileButton.swift
//  LeafLog
//
//  Created by 김주희 on 4/14/26.
//

import UIKit
import SnapKit
import Then

/// 프로필 사진 등 이미지를 추가할 때 사용하는 공용 카메라 버튼
/// 가로세로 140x140 사이즈로 고정
final class CameraProfileButton: UIControl {
    
    // MARK: - UI Components
    let cameraImageView = UIImageView().then {
        $0.image = .camera.withRenderingMode(.alwaysTemplate)
        $0.tintColor = .grayScale400
        $0.contentMode = .scaleAspectFit
    }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .grayScale50
        layer.cornerRadius = 70
        clipsToBounds = true
        
        self.snp.makeConstraints {
            $0.size.equalTo(140)
        }
        
        addSubview(cameraImageView)
        cameraImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(24)
        }
    }
}
