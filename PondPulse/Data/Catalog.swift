//
//  Catalog.swift
//  PondPulse
//
//  Everything sellable or unlockable, in display order - a 1:1 port of the
//  Android shop/Catalog.kt. Product ids double as the App Store product ids
//  ("theme_sakura", "skin_koi", "premium", ...).
//

import Foundation

/// How a shop item becomes usable.
enum Unlock {
    case free

    /// Granted forever once the given global level number is solved.
    case levelReward(Int)

    /// Included with the premium upgrade; hidden from the shop until owned.
    case premium

    /// Bought once; the price is the display price (StoreKit owns the real one).
    case paid(String)

    var price: String? {
        if case .paid(let price) = self { return price }
        return nil
    }

    var rewardLevel: Int? {
        if case .levelReward(let level) = self { return level }
        return nil
    }

    var isPremium: Bool {
        if case .premium = self { return true }
        return false
    }
}

struct ThemeItem: Identifiable {
    let id: String
    let nameKey: String
    let palette: PondPalette
    let unlock: Unlock
}

/// A floater skin: what the ducklings look like on the pond.
struct SkinItem: Identifiable {
    let id: String
    let nameKey: String
    let unlock: Unlock
}

struct PadItem: Identifiable {
    let id: String
    let nameKey: String
    let unlock: Unlock
}

enum Catalog {

    /// Levels from this global number on need the premium upgrade.
    static let premiumFromLevel = 301

    static let premiumId = "premium"
    static let premiumPrice = "$2.99"

    /// Consumable hint pack: 50 hints per purchase. Premium never needs it.
    static let hintsId = "hints_50"
    static let hintsPrice = "$0.99"
    static let hintsPerPack = 50

    private static let themePrice = "$0.99"
    private static let skinPrice = "$0.49"
    private static let padPrice = "$0.49"

    static let themes: [ThemeItem] = [
        ThemeItem(id: "dusk", nameKey: "theme_dusk", palette: .duskPond, unlock: .free),
        ThemeItem(id: "sunny", nameKey: "theme_sunny", palette: .sunnyMorning, unlock: .free),
        ThemeItem(id: "jungle", nameKey: "theme_jungle", palette: .jungleMist, unlock: .levelReward(75)),
        ThemeItem(id: "sakura", nameKey: "theme_sakura", palette: .sakuraPond, unlock: .paid(themePrice)),
        ThemeItem(id: "neon", nameKey: "theme_neon", palette: .midnightNeon, unlock: .paid(themePrice)),
        ThemeItem(id: "autumn", nameKey: "theme_autumn", palette: .autumnGold, unlock: .paid(themePrice)),
        ThemeItem(id: "frozen", nameKey: "theme_frozen", palette: .frozenPond, unlock: .paid(themePrice)),
        ThemeItem(id: "coral", nameKey: "theme_coral", palette: .coralReef, unlock: .paid(themePrice)),
        ThemeItem(id: "galaxy", nameKey: "theme_galaxy", palette: .galaxyNight, unlock: .paid(themePrice)),
        ThemeItem(id: "candy", nameKey: "theme_candy", palette: .candyPop, unlock: .paid(themePrice)),
        ThemeItem(id: "royal", nameKey: "theme_royal", palette: .royalLagoon, unlock: .premium),
    ]

    static let skins: [SkinItem] = [
        SkinItem(id: "duck", nameKey: "skin_duck", unlock: .free),
        SkinItem(id: "frog", nameKey: "skin_frog", unlock: .levelReward(50)),
        SkinItem(id: "swan", nameKey: "skin_swan", unlock: .levelReward(100)),
        SkinItem(id: "robo", nameKey: "skin_robo", unlock: .levelReward(200)),
        SkinItem(id: "golden", nameKey: "skin_golden", unlock: .levelReward(300)),
        SkinItem(id: "koi", nameKey: "skin_koi", unlock: .paid(skinPrice)),
        SkinItem(id: "penguin", nameKey: "skin_penguin", unlock: .paid(skinPrice)),
        SkinItem(id: "flamingo", nameKey: "skin_flamingo", unlock: .paid(skinPrice)),
        SkinItem(id: "boat", nameKey: "skin_boat", unlock: .paid(skinPrice)),
        SkinItem(id: "axolotl", nameKey: "skin_axolotl", unlock: .paid(skinPrice)),
        SkinItem(id: "otter", nameKey: "skin_otter", unlock: .paid(skinPrice)),
        SkinItem(id: "jelly", nameKey: "skin_jelly", unlock: .paid(skinPrice)),
        SkinItem(id: "dragon", nameKey: "skin_dragon", unlock: .premium),
        SkinItem(id: "narwhal", nameKey: "skin_narwhal", unlock: .premium),
        SkinItem(id: "beaver", nameKey: "skin_beaver", unlock: .premium),
    ]

    static let pads: [PadItem] = [
        PadItem(id: "lily", nameKey: "pad_lily", unlock: .free),
        PadItem(id: "lotus", nameKey: "pad_lotus", unlock: .levelReward(30)),
        PadItem(id: "starlight", nameKey: "pad_starlight", unlock: .levelReward(60)),
        PadItem(id: "rainbow", nameKey: "pad_rainbow", unlock: .levelReward(125)),
        PadItem(id: "ice", nameKey: "pad_ice", unlock: .paid(padPrice)),
        PadItem(id: "shell", nameKey: "pad_shell", unlock: .paid(padPrice)),
        PadItem(id: "sunflower", nameKey: "pad_sunflower", unlock: .paid(padPrice)),
        PadItem(id: "clover", nameKey: "pad_clover", unlock: .paid(padPrice)),
        PadItem(id: "gem", nameKey: "pad_gem", unlock: .paid(padPrice)),
        PadItem(id: "honey", nameKey: "pad_honey", unlock: .paid(padPrice)),
        PadItem(id: "moon", nameKey: "pad_moon", unlock: .paid(padPrice)),
        PadItem(id: "crown", nameKey: "pad_crown", unlock: .premium),
        PadItem(id: "aurora", nameKey: "pad_aurora", unlock: .premium),
    ]

    static func themeById(_ id: String?) -> ThemeItem {
        themes.first { $0.id == id } ?? themes[0]
    }

    static func themeProductId(_ id: String) -> String { "theme_\(id)" }
    static func skinProductId(_ id: String) -> String { "skin_\(id)" }
    static func padProductId(_ id: String) -> String { "pad_\(id)" }
}
