//
//  SubTitle.swift
//  Polaris
//
//  Created by 손유나 on 4/4/26.
//

import UIKit

class SubTitle: UILabel {
    
    init(text: String)  {
        super.init(frame: .zero)
        self.text = text
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupStyle() {
        self.font = .systemFont(ofSize: 16, weight: .medium)
        self.textColor = .black
    }
}
