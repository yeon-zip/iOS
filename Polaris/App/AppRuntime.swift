//
//  AppRuntime.swift
//  Polaris
//
//  Created by Codex on 5/5/26.
//

import UIKit

@MainActor
final class AppRuntime {
    static let shared = AppRuntime()

    let dependencies: AppDependencies
    let pushNotificationCoordinator: PushNotificationCoordinator

    private init(environment: AppEnvironment = .current) {
        let dependencies = AppDependencies.make(for: environment)
        self.dependencies = dependencies
        self.pushNotificationCoordinator = PushNotificationCoordinator(
            repository: dependencies.pushNotificationRepository
        )
    }

    func configure(application: UIApplication) {
        pushNotificationCoordinator.configure(application: application)
    }
}
