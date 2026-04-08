//
//  LibraryCardView.swift
//  Polaris
//
//  Created by 손유나 on 4/7/26.
//
import UIKit

class LibraryCardView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    private let openingStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    private let heartButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "HeartIcon"), for: .normal)
        btn.tintColor = .lightGray
        return btn
    }()
    
    init(title: String, distance: String, isOpen: Bool) {
        super.init(frame: .zero)
        self.titleLabel.text = title
        self.distanceLabel.text = distance
        self.openingStatusLabel.text = isOpen ? "운영중" : "운영종료"
        
        setupStyle()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        [titleLabel, distanceLabel, openingStatusLabel, heartButton].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // 타이틀
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            
            // 찜 버튼
            heartButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            heartButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            heartButton.widthAnchor.constraint(equalToConstant: 20),
            heartButton.heightAnchor.constraint(equalToConstant: 20),
            
            // 거리
            distanceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            distanceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            distanceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            // 상태
            openingStatusLabel.centerYAnchor.constraint(equalTo: distanceLabel.centerYAnchor),
            openingStatusLabel.leadingAnchor.constraint(equalTo: distanceLabel.trailingAnchor, constant: 6),
        ])
    }
    
    private func setupStyle() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 12
        
    }
}
