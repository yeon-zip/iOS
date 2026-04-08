//
//  LikeViewController.swift
//  Polaris
//
//  Created by 손유나 on 4/1/26.
//
import UIKit

class LikeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad( )
        
        view.backgroundColor = .systemBackground
        self.navigationItem.title = "찜 화면"
        setupLabel()
    }
    
    private func setupLabel() {
        let label = UILabel()
        label.text = "찜 화면"
        label.font = .systemFont(ofSize: 20)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
