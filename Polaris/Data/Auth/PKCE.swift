//
//  PKCE.swift
//  Polaris
//
//  Created by Codex on 4/26/26.
//

import CryptoKit
import Foundation
import Security

struct PKCEChallenge: Equatable, Sendable {
    let codeVerifier: String
    let codeChallenge: String
    let method: String
}

protocol PKCEGenerating: Sendable {
    func makeChallenge() throws -> PKCEChallenge
}

struct SecurePKCEGenerator: PKCEGenerating {
    private let verifierByteCount: Int

    init(verifierByteCount: Int = 32) {
        self.verifierByteCount = verifierByteCount
    }

    func makeChallenge() throws -> PKCEChallenge {
        var bytes = [UInt8](repeating: 0, count: verifierByteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw AuthError.networkFailure
        }

        let codeVerifier = Data(bytes).base64URLEncodedString()
        let digest = SHA256.hash(data: Data(codeVerifier.utf8))
        let codeChallenge = Data(digest).base64URLEncodedString()

        return PKCEChallenge(
            codeVerifier: codeVerifier,
            codeChallenge: codeChallenge,
            method: "S256"
        )
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
