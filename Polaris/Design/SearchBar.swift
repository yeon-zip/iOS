//
//  SearchBar.swift
//  Polaris
//
//  Created by 손유나 on 4/7/26.
//

import UIKit

class SearchBar: UISearchBar {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupStyle() {
        self.placeholder = "도서명, 저자, 출판사 검색"
        self.searchBarStyle = .minimal
        self.tintColor = .white
        
        if let textField = self.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .white
            textField.font = .systemFont(ofSize: 12)
            textField.borderStyle = .none
            textField.textColor = .black
            textField.layer.cornerRadius = 12
            textField.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                // textField를 SearchBar의 상하좌우 끝에 맞춤
                textField.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                textField.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                textField.topAnchor.constraint(equalTo: self.topAnchor),
                textField.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        }
    }
}

#Preview {
    HomeViewController()
}
