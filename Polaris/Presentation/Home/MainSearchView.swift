//
//  MainSearchView.swift
//  Polaris
//
//  Created by 손유나 on 4/7/26.
//

import UIKit

class MainSearchView: UIView {
    private let locationTitle: UILabel = {
        let label = UILabel()
        label.text = "경상북도 구미시 대학로 61"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .black
        return label
    }()
    
    private let iconStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        return stack
    }()
    
    private func createIconButton(imageName: String) -> UIButton {
        let btn = UIButton(type: .system)
        
        if let image = UIImage(named: imageName) {
            btn.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        
        btn.tintColor = .black
        return btn
    }
    
    private let searchBar = SearchBar()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let heartBtn = createIconButton(imageName: "HeartIcon")
        let alarmBtn = createIconButton(imageName: "AlarmIcon")
        let profileBtn = createIconButton(imageName: "ProfileIcon")
        
        [heartBtn, alarmBtn, profileBtn].forEach{
            iconStackView.addArrangedSubview($0)
        }
        
        [locationTitle, iconStackView, searchBar].forEach{
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            locationTitle.topAnchor.constraint(equalTo: topAnchor),
            locationTitle.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            iconStackView.centerYAnchor.constraint(equalTo: locationTitle.centerYAnchor),
            iconStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            searchBar.topAnchor.constraint(equalTo: locationTitle.bottomAnchor, constant: 14),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchBar.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
