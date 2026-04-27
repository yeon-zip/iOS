//
//  RefreshTokenStore.swift
//  Polaris
//
//  Created by Codex on 4/26/26.
//

import Foundation
import Security

protocol RefreshTokenStore: Sendable {
    func loadRefreshToken() async throws -> String?
    func saveRefreshToken(_ refreshToken: String) async throws
    func clearRefreshToken() async throws
}

actor KeychainRefreshTokenStore: RefreshTokenStore {
    private let service: String
    private let account: String

    init(
        service: String = "dev.nimonic.polaris.auth",
        account: String = "refresh-token"
    ) {
        self.service = service
        self.account = account
    }

    func loadRefreshToken() async throws -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw AuthError.networkFailure
        }

        guard let data = item as? Data,
              let token = String(data: data, encoding: .utf8),
              token.isEmpty == false else {
            return nil
        }

        return token
    }

    func saveRefreshToken(_ refreshToken: String) async throws {
        try await clearRefreshToken()

        var attributes = baseQuery()
        attributes[kSecValueData as String] = Data(refreshToken.utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.networkFailure
        }
    }

    func clearRefreshToken() async throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthError.networkFailure
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

actor InMemoryRefreshTokenStore: RefreshTokenStore {
    private var refreshToken: String?

    init(refreshToken: String? = nil) {
        self.refreshToken = refreshToken
    }

    func loadRefreshToken() async throws -> String? {
        refreshToken
    }

    func saveRefreshToken(_ refreshToken: String) async throws {
        self.refreshToken = refreshToken
    }

    func clearRefreshToken() async throws {
        refreshToken = nil
    }
}
