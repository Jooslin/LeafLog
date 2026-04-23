//
//  ImageSourcePickerPresenter.swift
//  LeafLog
//
//  Created by 김주희 on 4/22/26.
//

import PhotosUI
import UIKit

enum ImageSourcePickerPresenter {
    static func present(
        from presenter: UIViewController,
        sourceView: UIView,
        delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate & PHPickerViewControllerDelegate),
        deleteTitle: String? = nil,
        onDelete: (() -> Void)? = nil,
    ) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "카메라", style: .default) { [weak presenter, weak delegate] _ in
                guard let presenter, let delegate else { return }
                presentCameraPicker(from: presenter, delegate: delegate)
            })
        }

        alertController.addAction(UIAlertAction(title: "앨범", style: .default) { [weak presenter, weak delegate] _ in
            guard let presenter, let delegate else { return }
            presentPhotoPicker(from: presenter, delegate: delegate)
        })

        if let deleteTitle, let onDelete {
            alertController.addAction(UIAlertAction(title: deleteTitle, style: .destructive) { _ in
                onDelete()
            })
        }

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
        }

        presenter.present(alertController, animated: true)
    }

    private static func presentCameraPicker(
        from presenter: UIViewController,
        delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate
    ) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        // 카메라 선택 시
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = delegate

        presenter.present(picker, animated: true)
    }

    private static func presentPhotoPicker(
        from presenter: UIViewController,
        delegate: PHPickerViewControllerDelegate
    ) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        // 앨범 선택 시
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = delegate

        presenter.present(picker, animated: true)
    }
}
