//
//  DistanceFilter.swift
//  Polaris
//
//  Created by 손유나 on 4/4/26.
//
import UIKit

class DistanceFilterView: UIView {
    
    private let filterTitle = SubTitle(text: "검색 반경")
    
    private let stackView: UIStackView = {
       let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        return stack
    }()
    
    enum Distance: String, CaseIterable {
        case oneKm = "1km"
        case threeKm = "3km"
        case fiveKm = "5km"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        [filterTitle, stackView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            filterTitle.topAnchor.constraint(equalTo: topAnchor),
            filterTitle.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            stackView.topAnchor.constraint(equalTo: filterTitle.bottomAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 40),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        Distance.allCases.forEach { distance in
            let btn = UIButton()
            btn.setTitle(distance.rawValue, for: .normal)
            
            btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            btn.setTitleColor(.black, for: .normal)
            btn.backgroundColor = .white
            
            btn.layer.cornerRadius = 12
            stackView.addArrangedSubview(btn)
        }
        
    }
    
}

#Preview {
    HomeViewController()
}
