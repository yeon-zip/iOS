//
//  NearbyLibraryListView.swift
//  Polaris
//
//  Created by 손유나 on 4/4/26.
//
import UIKit

class NearbyLibraryListView: UIView {
    private let libraryTitleLabel = SubTitle(text: "주변 도서관")
    
    private let excludeView = ExcludeView()
    
    private let vStack: UIStackView = {
       let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fill
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addDummyCards()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        [libraryTitleLabel, excludeView, vStack].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // 타이틀 배치
            libraryTitleLabel.topAnchor.constraint(equalTo: topAnchor),
            libraryTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            // 제외 기능 배치
            excludeView.centerYAnchor.constraint(equalTo: libraryTitleLabel.centerYAnchor),
            excludeView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // VStack 배치
            vStack.topAnchor.constraint(equalTo: libraryTitleLabel.bottomAnchor, constant: 10),
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func addDummyCards() {
        let library1 = LibraryCardView(title: "강남 도서관", distance: "0.5km", isOpen: true)
        let library2 = LibraryCardView(title: "강남 도서관", distance: "0.5km", isOpen: false)
        let library3 = LibraryCardView(title: "강남 도서관", distance: "0.5km", isOpen: true)
        let library4 = LibraryCardView(title: "강남 도서관", distance: "0.5km", isOpen: true)
        
        [library1, library2, library3, library4].forEach {
            vStack.addArrangedSubview($0)
        }
    }
}
