//
//  DesignTextField.swift
//  LeafLog
//
//  Created by 변예린 on 7/2/26.
//

import UIKit

class DesignTextField: UITextField {
    private let contentInsets = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        textColor = .label
        layer.borderWidth = 1
        layer.borderColor = UIColor.grayScale100.cgColor
        
        layer.cornerRadius = 12
        clipsToBounds = true
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: contentInsets)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: contentInsets)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: contentInsets)
    }
    
    func setPlaceholder(text: String) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.grayScale300
        ]
        
        attributedPlaceholder = NSAttributedString(string: text, attributes: attributes)
    }
}
