import UIKit
import UserNotifications
#if canImport(FirebaseCore) && canImport(FirebaseMessaging)
import FirebaseCore
import FirebaseMessaging
#endif

@MainActor
final class PushNotificationCoordinator: NSObject {
    private let repository: any PushNotificationRepository
    private var isConfigured = false
    private var isFirebaseReady = false
    private var activationTask: Task<Void, Never>?
    private var registrationTask: Task<Void, Never>?

    init(repository: any PushNotificationRepository) {
        self.repository = repository
        super.init()
    }

    func configure(application: UIApplication) {
        guard isConfigured == false else { return }

        isConfigured = true
        UNUserNotificationCenter.current().delegate = self
        configureFirebaseIfAvailable()
    }

    func activate() {
        guard isFirebaseReady else { return }

        activationTask?.cancel()
        activationTask = Task { @MainActor [weak self] in
            await self?.requestAuthorizationAndRefreshToken()
        }
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) {
#if canImport(FirebaseCore) && canImport(FirebaseMessaging)
        guard isFirebaseReady else { return }

        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { [weak self] token, error in
            if let error {
                pushDebugLog("Failed to refresh FCM token: \(error)")
                return
            }
            guard let token, token.isEmpty == false else { return }
            Task { @MainActor in
                self?.registerDeviceToken(token)
            }
        }
#endif
    }

    private func configureFirebaseIfAvailable() {
#if canImport(FirebaseCore) && canImport(FirebaseMessaging)
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            pushDebugLog("GoogleService-Info.plist is missing. Push notifications are disabled.")
            return
        }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        Messaging.messaging().delegate = self
        isFirebaseReady = true
#else
        pushDebugLog("FirebaseMessaging is not linked. Push notifications are disabled.")
#endif
    }

    private func requestAuthorizationAndRefreshToken() async {
        do {
            let isGranted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            guard isGranted else { return }

            UIApplication.shared.registerForRemoteNotifications()
            refreshFCMToken()
        } catch {
            pushDebugLog("Notification authorization failed: \(error)")
        }
    }

    private func refreshFCMToken() {
#if canImport(FirebaseCore) && canImport(FirebaseMessaging)
        guard isFirebaseReady else { return }

        Messaging.messaging().token { [weak self] token, error in
            if let error {
                pushDebugLog("Failed to fetch FCM token: \(error)")
                return
            }
            guard let token, token.isEmpty == false else { return }
            Task { @MainActor in
                self?.registerDeviceToken(token)
            }
        }
#endif
    }

    private func registerDeviceToken(_ token: String) {
        registrationTask?.cancel()
        registrationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.repository.registerDeviceToken(token)
            } catch {
                pushDebugLog("Failed to register push token: \(error)")
            }
        }
    }
}

#if canImport(FirebaseCore) && canImport(FirebaseMessaging)
extension PushNotificationCoordinator: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, fcmToken.isEmpty == false else { return }
        Task { @MainActor in
            self.registerDeviceToken(fcmToken)
        }
    }
}
#endif

extension PushNotificationCoordinator: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

private func pushDebugLog(_ message: String) {
#if DEBUG
    print("[PushNotification] \(message)")
#endif
}
