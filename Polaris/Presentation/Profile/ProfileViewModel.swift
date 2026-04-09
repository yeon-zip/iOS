//
//  ProfileViewModel.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

@MainActor
final class ProfileViewModel {
    struct State: Equatable {
        var profile: UserProfile?
        var isLoading = false
        var errorMessage: String?
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let profileRepository: any ProfileRepository
    private(set) var state = State()

    init(profileRepository: any ProfileRepository) {
        self.profileRepository = profileRepository
    }

    func load() async {
        state.isLoading = true
        state.errorMessage = nil
        onStateChange?(state)

        do {
            let profile = try await profileRepository.fetchProfile()
            state.profile = profile
            state.errorMessage = nil
        } catch {
            state.profile = nil
            state.errorMessage = "프로필 정보를 불러오지 못했습니다."
        }

        state.isLoading = false
        onStateChange?(state)
    }

    func didTapBack() {
        onRoute?(.back)
    }
}
