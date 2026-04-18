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
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let profileRepository: any ProfileRepository
    private(set) var state = State()

    init(profileRepository: any ProfileRepository) {
        self.profileRepository = profileRepository
    }

    func load() async {
        state.profile = await profileRepository.fetchProfile()
        onStateChange?(state)
    }

    func didTapBack() {
        onRoute?(.back)
    }
}
