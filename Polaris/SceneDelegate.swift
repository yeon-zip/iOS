//
//  SceneDelegate.swift
//  Polaris
//
//  Created by 손유나 on 3/27/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {return}
        
        let window = UIWindow(windowScene: windowScene)
        
       
        let mainViewController = HomeViewController()
        
        window.rootViewController = mainViewController
        
        self.window = window
        window.makeKeyAndVisible( )
    }
}

#Preview {
   return ViewController()
}
