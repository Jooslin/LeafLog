//
//  DetailInfoSectionView.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/17/26.
//
import UIKit
import Then
import SnapKit

final class DetailInfoSectionView: UIView {
    
    private let sectionImage = UIImageView()
    private let titleLabel = UILabel(config: .title14, color: .black)

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.backgroundColor = .primary50
        
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }

    init(imageResource: ImageResource, title: String, rows: [DetailInfoRowView]) {
        super.init(frame: .zero)
        sectionImage.image = UIImage(resource: imageResource)
        titleLabel.text = title

        setupLayout()

        setRows(rows)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(sectionImage)
        addSubview(titleLabel)
        addSubview(stackView)
        
        sectionImage.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(2)
            $0.size.equalTo(14)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.trailing.equalToSuperview()
            $0.leading.equalTo(sectionImage.snp.trailing).offset(4)
        }

        stackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    // 기존의 줄들을 다 지우고 셋팅
    func setRows(_ rows: [DetailInfoRowView]) {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        rows.forEach {
            stackView.addArrangedSubview($0)
        }

        isHidden = rows.isEmpty
    }
    
    // (String, String?) 배열을 받아서 값이 비어있지 않은 것만 DetailInfoRowView로 변환
    func setRows(_ rows: [(String, String?)]) {
        let rowViews = rows.compactMap { title, value -> DetailInfoRowView? in
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else {
                return nil
            }

            return DetailInfoRowView(title: title, value: value)
        }

        setRows(rowViews)
    }
}
