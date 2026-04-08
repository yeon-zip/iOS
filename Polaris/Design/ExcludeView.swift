//
//  ExcludeView.swift
//  Polaris
//
//  Created by 손유나 on 4/7/26.
//

import UIKit

class ExcludeView: UIView {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .trailing
        return stack
    }()
    
    private let checkButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "rectangle"), for: .normal)
        button.setImage(UIImage(systemName: "checkmark.square"), for: .selected)
        
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "운영종료 제외"
        label.font = .systemFont(ofSize: 10)
        label.textColor = .systemRed
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        [checkButton, titleLabel].forEach {
            stackView.addArrangedSubview( $0 )
        }
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            checkButton.widthAnchor.constraint(equalToConstant: 14),
            checkButton.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    
}
