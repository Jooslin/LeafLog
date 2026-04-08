//
//  Extension.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit

extension UIViewController {
    
    // MARK: 확인 버튼 1개 알림창 (단순 알림)
    func showAlert(
        title: String = "오류",
        message: String,
        confirmTitle: String = "확인",
        onConfirm: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirm = UIAlertAction(title: confirmTitle, style: .default) { _ in
            onConfirm?()
        }
        alert.addAction(confirm)
        present(alert, animated: true)
    }
    
    // MARK: 버튼 2개 알림창 (회원 탈퇴, 글 삭제, 로그아웃 등)
    func showDestructiveAlert(
        title: String,
        message: String,
        confirmTitle: String,
        onConfirm: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        let confirm = UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            onConfirm?()
        }
        alert.addAction(cancel)
        alert.addAction(confirm)
        present(alert, animated: true)
    }
}
