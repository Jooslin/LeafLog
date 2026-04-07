//
//  ViewController.swift
//  LeafLog
//
//  Created by t2025-m0143 on 4/3/26.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    let plantService = PlantClassificationService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let imageView = UIImageView(image: .monstera)
        let button = UIButton(configuration: .plain())
        button.setTitle("analyze", for: .normal)
        let resultLabel = UILabel()
        
        view.addSubview(imageView)
        view.addSubview(button)
        view.addSubview(resultLabel)
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(300)
            $0.center.equalToSuperview()
        }
        
        button.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }
        
        resultLabel.snp.makeConstraints {
            $0.top.equalTo(button.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }
        
        button.addAction(UIAction { _ in
            guard let image = imageView.image else {
                print("이미지가 없음")
                return
            }
            
            print(self.plantService.analyzeImage(image: image))
        }, for: .touchUpInside)
    }


}

