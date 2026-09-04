//
//  PalettesPremium.swift
//  PondPulse
//
//  The two paid themes' palettes.
//
//  Kept out of `PaletteData.swift` because that file is generated from the
//  Android `Palettes.kt` by `tools/convert_palettes.py` and would lose anything
//  written into it by hand. These two are iOS-first; when they cross over, they
//  move into the Kotlin source and come back through the generator like the
//  other twelve.
//
//  They are also the two that had to *look* like they cost money, which is why
//  neither of them is another blue pond at another time of day. Opal is the only
//  light palette in the game whose water is not blue, and Ember is the only one
//  where the water is the brightest thing on the screen.
//

import SwiftUI

extension PondPalette {

    /// Opal Lagoon: pearl, mint and orchid, like light through a cut stone.
    ///
    /// The trick with an iridescent palette is that it cannot actually shift -
    /// nothing here animates a colour - so the shimmer has to come from three
    /// hues that are *equally* pale sitting next to each other: mint water,
    /// orchid accent, pearl-white ducks. No single one of them dominates, and
    /// the eye reads the whole thing as one shifting surface.
    static let opalLagoon = PondPalette(
        isDark: false,
        background: Color(hex: 0xF4EFF8),
        backgroundHigh: Color(hex: 0xEAE1F2),
        surface: Color(hex: 0xFFFFFF),
        surfaceHigh: Color(hex: 0xF9F3FC),
        outline: Color(hex: 0xCDB9DD),
        textPrimary: Color(hex: 0x3B2C4B),
        textSecondary: Color(hex: 0x7D6C8F),
        accent: Color(hex: 0xC97FC0),
        water: Color(hex: 0x9BD8D0),
        waterDeep: Color(hex: 0x81C6C6),
        waterRim: Color(hex: 0x69AEC4),
        ripple: Color(hex: 0xFFFFFF),
        rock: Color(hex: 0xC7BCD4),
        rockDark: Color(hex: 0xA294B6),
        pad: Color(hex: 0x8FD4B2),
        padDark: Color(hex: 0x69B795),
        duck: Color(hex: 0xFDF2F8),
        duckShade: Color(hex: 0xEBD8E7),
        beak: Color(hex: 0xF2A2B6),
        turtle: Color(hex: 0xA9C7E2),
        turtleShell: Color(hex: 0x88A9CA),
        current: Color(hex: 0xE9F8FA),
        star: Color(hex: 0xC97FC0),
        danger: Color(hex: 0xE86D8A),
    )

    /// Ember Hollow: a pond in a caldera - charcoal banks, molten water, ash.
    ///
    /// The one palette where the water is the light source. Everything else is
    /// pulled down towards charcoal so the pond glows out of it, which is also
    /// why `rock` and `pad` are so desaturated: a scorched bank has no green
    /// left in it, and any that crept in would read as a bug rather than as
    /// grass.
    static let emberHollow = PondPalette(
        isDark: true,
        background: Color(hex: 0x1B1214),
        backgroundHigh: Color(hex: 0x25181A),
        surface: Color(hex: 0x2E1E1F),
        surfaceHigh: Color(hex: 0x3C2725),
        outline: Color(hex: 0x5C3B32),
        textPrimary: Color(hex: 0xFFEEE3),
        textSecondary: Color(hex: 0xC59C8B),
        accent: Color(hex: 0xFFA23A),
        water: Color(hex: 0xB4471F),
        waterDeep: Color(hex: 0x8C3315),
        waterRim: Color(hex: 0xFF7C31),
        ripple: Color(hex: 0xFFD9A4),
        rock: Color(hex: 0x6C5B56),
        rockDark: Color(hex: 0x483B38),
        pad: Color(hex: 0x8B5B33),
        padDark: Color(hex: 0x5F3B20),
        duck: Color(hex: 0xFFB44D),
        duckShade: Color(hex: 0xE68B2B),
        beak: Color(hex: 0xFF6C2C),
        turtle: Color(hex: 0x8B6B4B),
        turtleShell: Color(hex: 0x644930),
        current: Color(hex: 0xFFCA8C),
        star: Color(hex: 0xFFA23A),
        danger: Color(hex: 0xFF5B5B),
    )
}
