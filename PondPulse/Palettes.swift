//
//  Palettes.swift
//  PondPulse
//
//  One hand-tuned pond palette; the whole game is drawn from it. The 11
//  palette value sets live in the generated PaletteData.swift. Mirrors the
//  Android ui/theme/Theme.kt + Palettes.kt.
//

import SwiftUI

extension Color {
    /// `Color(hex: 0x17607F)` - same literals as the Android palettes.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

struct PondPalette {
    let isDark: Bool
    let background: Color
    let backgroundHigh: Color
    let surface: Color
    let surfaceHigh: Color
    let outline: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let water: Color
    let waterDeep: Color
    let waterRim: Color
    let ripple: Color
    let rock: Color
    let rockDark: Color
    let pad: Color
    let padDark: Color
    let duck: Color
    let duckShade: Color
    let beak: Color
    let turtle: Color
    let turtleShell: Color
    let current: Color
    let star: Color
    let danger: Color

    func duckTint(_ color: DuckColor?) -> Color {
        switch color {
        case nil: duck
        case .red: Color(hex: 0xFF7B6E)
        case .green: Color(hex: 0x7BE08A)
        case .blue: Color(hex: 0x6FB9FF)
        }
    }

    func padRing(_ color: DuckColor?) -> Color? {
        switch color {
        case nil: nil
        case .red: Color(hex: 0xFF7B6E)
        case .green: Color(hex: 0xB4F0BD)
        case .blue: Color(hex: 0x6FB9FF)
        }
    }

    /// Ink used on top of the accent color (buttons), same on every theme.
    static let onAccent = Color(hex: 0x203040)
}

/// The equipped palette, provided from the root so every view draws from it.
private struct PaletteKey: EnvironmentKey {
    static let defaultValue = PondPalette.duskPond
}

extension EnvironmentValues {
    var palette: PondPalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
