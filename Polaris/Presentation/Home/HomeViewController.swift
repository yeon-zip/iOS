//
//  HomeViewController.swift
//  Polaris
//
//  Created by 손유나 on 4/4/26.
//

import UIKit

class HomeViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }
    
    private let mainSearchView = MainSearchView()

    private let distanceFilterView = DistanceFilterView()
    
    private let nearbyLibraryListView = NearbyLibraryListView()
    
    private func setupLayout() {
        [mainSearchView, distanceFilterView, nearbyLibraryListView].forEach{
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            mainSearchView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainSearchView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            mainSearchView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            distanceFilterView.topAnchor.constraint(equalTo: mainSearchView.bottomAnchor, constant: 36),
            distanceFilterView.leadingAnchor.constraint(equalTo: mainSearchView.leadingAnchor),
            distanceFilterView.trailingAnchor.constraint(equalTo: mainSearchView.trailingAnchor),
            
            nearbyLibraryListView.topAnchor.constraint(equalTo: distanceFilterView.bottomAnchor, constant: 36),
            nearbyLibraryListView.leadingAnchor.constraint(equalTo: mainSearchView.leadingAnchor),
            nearbyLibraryListView.trailingAnchor.constraint(equalTo: mainSearchView.trailingAnchor)
            
        ])
    }
    
}

#Preview {
    HomeViewController()
}
