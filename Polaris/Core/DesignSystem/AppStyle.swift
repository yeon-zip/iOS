//
//  AppStyle.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit

enum AppColor {
    static let background = UIColor(hex: 0xF2F4F6)
    static let surface = UIColor.white
    static let elevated = UIColor(hex: 0xF9FAFB)
    static let line = UIColor(hex: 0xE5E8EB)
    static let textPrimary = UIColor(hex: 0x191F28)
    static let textSecondary = UIColor(hex: 0x6B7684)
    static let textTertiary = UIColor(hex: 0x8B95A1)
    static let accent = UIColor(hex: 0x3182F6)
    static let success = UIColor(hex: 0x2F9E44)
    static let danger = UIColor(hex: 0xF04452)
    static let warning = UIColor(hex: 0xF2C94C)
    static let chipFill = UIColor(hex: 0xF7F8FA)
    static let shadow = UIColor(hex: 0x101828, alpha: 0.08)
}

enum AppTypography {
    static let hero = UIFont.systemFont(ofSize: 22, weight: .bold)
    static let title = UIFont.systemFont(ofSize: 28, weight: .bold)
    static let section = UIFont.systemFont(ofSize: 22, weight: .bold)
    static let headline = UIFont.systemFont(ofSize: 18, weight: .semibold)
    static let body = UIFont.systemFont(ofSize: 16, weight: .medium)
    static let subheadline = UIFont.systemFont(ofSize: 15, weight: .medium)
    static let caption = UIFont.systemFont(ofSize: 13, weight: .medium)
    static let tiny = UIFont.systemFont(ofSize: 12, weight: .semibold)
}

enum AppSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

enum AppRadius {
    static let small: CGFloat = 12
    static let medium: CGFloat = 18
    static let large: CGFloat = 24
}

enum AppShadow {
    static func applyCard(to view: UIView) {
        view.layer.shadowColor = AppColor.shadow.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 20
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
