//
//  SceneDelegate.swift
//  Polaris
//
//  Created by 손유나 on 3/27/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appNavigator: AppNavigator?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {return}
        
        let window = UIWindow(windowScene: windowScene)

        let navigationController = UINavigationController()
        let dependencies = AppDependencies.make()
        let navigator = AppNavigator(navigationController: navigationController, dependencies: dependencies)
        navigator.start()

        window.rootViewController = navigationController
        self.window = window
        self.appNavigator = navigator
        window.makeKeyAndVisible( )
    }
}
