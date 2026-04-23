//
//  SearchDetailImageCell.swift
//  LeafLog
//
//  Created by Yeseul Jang on 4/17/26.
//
import UIKit
import Then
import SnapKit
import Kingfisher

final class SearchDetailImageCell: UICollectionViewCell {
    static let reuseIdentifier = "SearchDetailImageCell"

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .grayScale100
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = UIImage(systemName: "photo")
    }

    func configure(imageURLString: String?) {
        let placeholderImage = UIImage(resource: .placeholder)

        guard let imageURLString, !imageURLString.isEmpty,
              let url = URL(string: imageURLString) else {
            imageView.image = placeholderImage
            return
        }

        imageView.kf.setImage(with: url, placeholder: placeholderImage)
    }
}

