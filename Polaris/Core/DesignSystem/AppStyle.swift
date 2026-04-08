//
//  AppStyle.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit

enum AppColor {
    static let background = UIColor(hex: 0xF6F7FB)
    static let surface = UIColor.white
    static let elevated = UIColor(hex: 0xF1F4F8)
    static let line = UIColor(hex: 0xE8ECF2)
    static let lineStrong = UIColor(hex: 0xD7DEE8)
    static let textPrimary = UIColor(hex: 0x1B2430)
    static let textSecondary = UIColor(hex: 0x566170)
    static let textTertiary = UIColor(hex: 0x98A2B3)
    static let accent = UIColor(hex: 0x3478F6)
    static let accentSurface = UIColor(hex: 0xEEF4FF)
    static let success = UIColor(hex: 0x2F9E44)
    static let successSurface = UIColor(hex: 0xEAF7ED)
    static let danger = UIColor(hex: 0xF04452)
    static let dangerSurface = UIColor(hex: 0xFDEBEC)
    static let warning = UIColor(hex: 0xFFB84D)
    static let warningSurface = UIColor(hex: 0xFFF4D8)
    static let heart = UIColor(hex: 0xFF6B81)
    static let heartSurface = UIColor(hex: 0xFFF0F4)
    static let iconSurface = UIColor(hex: 0xF3F5F8)
    static let chipFill = UIColor(hex: 0xF7F9FC)
    static let shadow = UIColor(hex: 0x0F172A, alpha: 0.04)
}

enum AppTypography {
    static let hero = rounded(22, weight: .semibold)
    static let title = rounded(18, weight: .semibold)
    static let section = rounded(17, weight: .semibold)
    static let headline = rounded(16, weight: .semibold)
    static let body = rounded(14, weight: .regular)
    static let subheadline = rounded(14, weight: .semibold)
    static let caption = rounded(12, weight: .regular)
    static let tiny = rounded(11, weight: .semibold)

    private static func rounded(_ size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let baseFont = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = baseFont.fontDescriptor.withDesign(.rounded) else {
            return baseFont
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}

enum AppSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 18
    static let xxxl: CGFloat = 24
}

enum AppRadius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 18
    static let large: CGFloat = 28
}

enum AppShadow {
    static func applyCard(to view: UIView) {
        view.layer.shadowColor = AppColor.shadow.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = 14
        view.layer.masksToBounds = false
    }
}

extension UIView {
    func pinEdges(to other: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -insets.bottom)
        ])
    }

    func addSubviews(_ views: UIView...) {
        views.forEach(addSubview)
    }
}
