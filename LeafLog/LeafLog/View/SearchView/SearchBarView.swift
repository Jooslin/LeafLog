//
//  SearchBarView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/13/26.
//

import SnapKit
import Then
import UIKit

final class SearchBarView: UIView {
    let textField = UITextField().then {
        $0.placeholder = "place holder"
        $0.borderStyle = .none
        $0.autocapitalizationType = .none
        $0.returnKeyType = .search
        $0.font = .systemFont(ofSize: 16, weight: .regular)
        $0.textColor = .label
    }

    let cameraButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "camera")
        configuration.baseForegroundColor = UIColor(red: 0.39, green: 0.39, blue: 0.39, alpha: 1)
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        $0.configuration = configuration
    }

    private let searchIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "magnifyingglass")
        $0.tintColor = UIColor(red: 0.79, green: 0.79, blue: 0.79, alpha: 1)
        $0.contentMode = .scaleAspectFit
    }

    private let dividerView = UIView().then {
        $0.backgroundColor = UIColor(red: 0.79, green: 0.79, blue: 0.79, alpha: 1)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.grayScale100.cgColor

        addSubview(searchIconImageView)
        addSubview(textField)
        addSubview(dividerView)
        addSubview(cameraButton)

        searchIconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        cameraButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(30)
        }

        dividerView.snp.makeConstraints {
            $0.trailing.equalTo(cameraButton.snp.leading).offset(-12)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(1 / UIScreen.main.scale)
            $0.height.equalTo(30)
        }

        textField.snp.makeConstraints {
            $0.leading.equalTo(searchIconImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(dividerView.snp.leading).offset(-12)
            $0.centerY.equalToSuperview()
        }
    }
}
