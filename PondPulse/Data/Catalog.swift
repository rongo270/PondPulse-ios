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

    /// Granted forever once the given number of golden ponds have been cleared.
    case bonusReward(Int)

    /// Granted forever once the Daily Pond has been cleared this many days
    /// running. Read against the player's *best* streak, never the live one: an
    /// unlock is permanent, so breaking a streak costs the run, not the prize.
    case streakReward(Int)

    /// Included with the premium upgrade; hidden from the shop until owned.
    case premium

    /// Bought from the shop with coins, at one of the bands in `CoinBank`.
    ///
    /// Coins, not money. Only three things in PondPulse ever charge real money -
    /// the premium upgrade, the hint pack and the coin packs - and everything on
    /// the cosmetic shelves is reachable by playing. That is the whole reason the
    /// campaign pays coins at all: a shelf you can only buy your way onto is a
    /// price list, and a shelf you can play your way onto is a reason to keep
    /// going.
    ///
    /// `bonusCount` is a second door: the golden-pond rung that grants this item
    /// outright. It never replaces the price.
    case coins(price: Int, bonusCount: Int? = nil)

    // MARK: - Readers

    var coinPrice: Int? {
        if case .coins(let price, _) = self { return price }
        return nil
    }

    var rewardLevel: Int? {
        if case .levelReward(let level) = self { return level }
        return nil
    }

    var rewardBonusPonds: Int? {
        if case .bonusReward(let count) = self { return count }
        return nil
    }

    var rewardStreak: Int? {
        if case .streakReward(let days) = self { return days }
        return nil
    }

    var isPremium: Bool {
        if case .premium = self { return true }
        return false
    }

    var isFree: Bool {
        if case .free = self { return true }
        return false
    }

    /// Where an item sits on the ladder of *how you get it*, so every shelf reads
    /// the same way: free, then earned by playing the campaign, then earned in a
    /// golden pond, then earned on a daily streak, then bought, then premium.
    ///
    /// The catalog lists used to be raw authoring order - two shelves written
    /// months apart and appended - so the Tadpole you earn at level 15 sat below
    /// every premium skin, and a shelf gave no sense of what was coming next.
    var rank: Int {
        switch self {
        case .free: return 0
        case .levelReward: return 1
        case .bonusReward: return 2
        case .streakReward: return 3
        case .coins: return 4
        case .premium: return 5
        }
    }

    /// Within a rank, the cheaper or sooner one comes first.
    var step: Int {
        switch self {
        case .levelReward(let level): return level
        case .bonusReward(let count): return count
        case .streakReward(let days): return days
        case .coins(let price, _): return price
        default: return 0
        }
    }
}

/// Sorts a shelf onto that ladder, keeping authoring order as the tiebreak.
func byUnlock<T>(_ items: [T], _ unlockOf: (T) -> Unlock) -> [T] {
    items.enumerated()
        .sorted { a, b in
            let ua = unlockOf(a.element), ub = unlockOf(b.element)
            if ua.rank != ub.rank { return ua.rank < ub.rank }
            if ua.step != ub.step { return ua.step < ub.step }
            return a.offset < b.offset
        }
        .map(\.element)
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

    // ---------------------------------------------------------------------
    // Development switch: every theme, pond friend and lily pad is unlocked,
    // whatever it normally costs or asks you to earn.
    //
    // It is ANDed with a #if DEBUG check below, so leaving it switched on can
    // never ship an unlocked shop to the App Store - a release build locks up
    // again by itself. The premium *levels* still follow `isPremium`; this is
    // about the cosmetics the shop sells.
    //
    // Held OFF now that the coin economy is live: with it on, no shelf ever
    // quotes a price and the whole earn-and-spend loop is invisible in a debug
    // build, which is exactly the thing that most needs playing.
    // ---------------------------------------------------------------------
    static let unlockAllCosmetics = false

    static var cosmeticsUnlocked: Bool {
        #if DEBUG
        return unlockAllCosmetics
        #else
        return false
        #endif
    }

    /// Levels from this global number on need the premium upgrade.
    static let premiumFromLevel = 301

    static let premiumId = "premium"
    static let premiumPrice = "$2.99"

    /// Consumable hint pack: 50 hints per purchase. Premium never needs it.
    static let hintsId = "hints_50"
    static let hintsPrice = "$0.99"
    static let hintsPerPack = 50

    /// The coin packs, in catalog order - the one place money buys coins rather
    /// than the other way round. Product ids match `CoinBank.coinPacks` one for
    /// one, so a pack can never grant an amount the economy has not been priced
    /// against.
    static let coinPackIds: [String] = CoinBank.coinPacks.map { "coins_\($0)" }

    /// Offline fallback prices for the coin packs, in `coinPackIds` order. The
    /// App Store's own display prices win once StoreKit has loaded.
    static let coinPackPrices = ["$0.99", "$1.99", "$3.49"]

    /// How many coins the product id grants, or nil if it is not a coin pack.
    static func coinsInPack(_ productId: String) -> Int? {
        CoinBank.coinPacks.first { "coins_\($0)" == productId }
    }

    // MARK: - Shelves

    private static let authoredThemes: [ThemeItem] = [
        ThemeItem(id: "dusk", nameKey: "theme_dusk", palette: .duskPond, unlock: .free),
        ThemeItem(id: "sunny", nameKey: "theme_sunny", palette: .sunnyMorning, unlock: .free),
        ThemeItem(id: "jungle", nameKey: "theme_jungle", palette: .jungleMist, unlock: .levelReward(75)),
        ThemeItem(id: "goldenpond", nameKey: "theme_goldenpond", palette: .goldenPond, unlock: .bonusReward(10)),
        ThemeItem(id: "sakura", nameKey: "theme_sakura", palette: .sakuraPond, unlock: .coins(price: CoinBank.priceTheme)),
        ThemeItem(id: "neon", nameKey: "theme_neon", palette: .midnightNeon, unlock: .coins(price: CoinBank.priceThemeRare)),
        ThemeItem(id: "autumn", nameKey: "theme_autumn", palette: .autumnGold, unlock: .coins(price: CoinBank.priceTheme)),
        ThemeItem(id: "frozen", nameKey: "theme_frozen", palette: .frozenPond, unlock: .coins(price: CoinBank.priceTheme)),
        ThemeItem(id: "coral", nameKey: "theme_coral", palette: .coralReef, unlock: .coins(price: CoinBank.priceTheme)),
        ThemeItem(id: "galaxy", nameKey: "theme_galaxy", palette: .galaxyNight, unlock: .coins(price: CoinBank.priceThemeRare)),
        ThemeItem(id: "candy", nameKey: "theme_candy", palette: .candyPop, unlock: .coins(price: CoinBank.priceThemeRare)),
        ThemeItem(id: "royal", nameKey: "theme_royal", palette: .royalLagoon, unlock: .premium),
    ]

    private static let authoredSkins: [SkinItem] = [
        SkinItem(id: "duck", nameKey: "skin_duck", unlock: .free),
        SkinItem(id: "frog", nameKey: "skin_frog", unlock: .levelReward(50)),
        SkinItem(id: "swan", nameKey: "skin_swan", unlock: .levelReward(100)),
        SkinItem(id: "robo", nameKey: "skin_robo", unlock: .levelReward(200)),
        SkinItem(id: "golden", nameKey: "skin_golden", unlock: .levelReward(300)),
        SkinItem(id: "gosling", nameKey: "skin_gosling", unlock: .bonusReward(20)),
        SkinItem(id: "koi", nameKey: "skin_koi", unlock: .coins(price: CoinBank.priceSkin, bonusCount: 1)),
        SkinItem(id: "penguin", nameKey: "skin_penguin", unlock: .coins(price: CoinBank.priceSkin, bonusCount: 5)),
        SkinItem(id: "flamingo", nameKey: "skin_flamingo", unlock: .coins(price: CoinBank.priceSkin, bonusCount: 9)),
        SkinItem(id: "boat", nameKey: "skin_boat", unlock: .coins(price: CoinBank.priceSkin, bonusCount: 13)),
        SkinItem(id: "axolotl", nameKey: "skin_axolotl", unlock: .coins(price: CoinBank.priceSkinUncommon, bonusCount: 19)),
        SkinItem(id: "otter", nameKey: "skin_otter", unlock: .coins(price: CoinBank.priceSkin, bonusCount: 16)),
        SkinItem(id: "jelly", nameKey: "skin_jelly", unlock: .coins(price: CoinBank.priceSkinUncommon, bonusCount: 23)),
        SkinItem(id: "dragon", nameKey: "skin_dragon", unlock: .premium),
        SkinItem(id: "narwhal", nameKey: "skin_narwhal", unlock: .premium),
        SkinItem(id: "beaver", nameKey: "skin_beaver", unlock: .premium),
        SkinItem(id: "tadpole", nameKey: "skin_tadpole", unlock: .levelReward(15)),
        SkinItem(id: "snail", nameKey: "skin_snail", unlock: .levelReward(40)),
        SkinItem(id: "crab", nameKey: "skin_crab", unlock: .levelReward(65)),
        SkinItem(id: "heron", nameKey: "skin_heron", unlock: .levelReward(90)),
        SkinItem(id: "goose", nameKey: "skin_goose", unlock: .levelReward(115)),
        SkinItem(id: "capybara", nameKey: "skin_capybara", unlock: .levelReward(150)),
        SkinItem(id: "seal", nameKey: "skin_seal", unlock: .levelReward(175)),
        SkinItem(id: "pelican", nameKey: "skin_pelican", unlock: .levelReward(225)),
        SkinItem(id: "kingfisher", nameKey: "skin_kingfisher", unlock: .levelReward(260)),
        SkinItem(id: "dragonfly", nameKey: "skin_dragonfly", unlock: .streakReward(7)),
        SkinItem(id: "crane", nameKey: "skin_crane", unlock: .streakReward(30)),
        SkinItem(id: "lantern", nameKey: "skin_lantern", unlock: .streakReward(100)),
        SkinItem(id: "puffer", nameKey: "skin_puffer", unlock: .coins(price: CoinBank.priceSkinUncommon)),
        SkinItem(id: "seahorse", nameKey: "skin_seahorse", unlock: .coins(price: CoinBank.priceSkinUncommon, bonusCount: 26)),
        SkinItem(id: "octopus", nameKey: "skin_octopus", unlock: .coins(price: CoinBank.priceSkinRare, bonusCount: 29)),
        SkinItem(id: "platypus", nameKey: "skin_platypus", unlock: .coins(price: CoinBank.priceSkinRare)),
        SkinItem(id: "submarine", nameKey: "skin_submarine", unlock: .coins(price: CoinBank.priceSkinRare)),
        SkinItem(id: "pixel", nameKey: "skin_pixel", unlock: .coins(price: CoinBank.priceSkinUncommon)),
        SkinItem(id: "phoenix", nameKey: "skin_phoenix", unlock: .premium),
        SkinItem(id: "unicorn", nameKey: "skin_unicorn", unlock: .premium),
    ]

    private static let authoredPads: [PadItem] = [
        PadItem(id: "lily", nameKey: "pad_lily", unlock: .free),
        PadItem(id: "lotus", nameKey: "pad_lotus", unlock: .levelReward(30)),
        PadItem(id: "starlight", nameKey: "pad_starlight", unlock: .levelReward(60)),
        PadItem(id: "rainbow", nameKey: "pad_rainbow", unlock: .levelReward(125)),
        PadItem(id: "goldenlily", nameKey: "pad_goldenlily", unlock: .bonusReward(3)),
        PadItem(id: "ice", nameKey: "pad_ice", unlock: .coins(price: CoinBank.pricePad, bonusCount: 4)),
        PadItem(id: "shell", nameKey: "pad_shell", unlock: .coins(price: CoinBank.pricePad, bonusCount: 7)),
        PadItem(id: "sunflower", nameKey: "pad_sunflower", unlock: .coins(price: CoinBank.pricePad, bonusCount: 12)),
        PadItem(id: "clover", nameKey: "pad_clover", unlock: .coins(price: CoinBank.pricePad, bonusCount: 15)),
        PadItem(id: "gem", nameKey: "pad_gem", unlock: .coins(price: CoinBank.pricePadRare, bonusCount: 22)),
        PadItem(id: "honey", nameKey: "pad_honey", unlock: .coins(price: CoinBank.pricePadRare, bonusCount: 25)),
        PadItem(id: "moon", nameKey: "pad_moon", unlock: .coins(price: CoinBank.pricePadRare, bonusCount: 28)),
        PadItem(id: "crown", nameKey: "pad_crown", unlock: .premium),
        PadItem(id: "aurora", nameKey: "pad_aurora", unlock: .premium),
        PadItem(id: "leaf", nameKey: "pad_leaf", unlock: .levelReward(20)),
        PadItem(id: "mushroom", nameKey: "pad_mushroom", unlock: .levelReward(45)),
        PadItem(id: "stone", nameKey: "pad_stone", unlock: .levelReward(85)),
        PadItem(id: "cloud", nameKey: "pad_cloud", unlock: .levelReward(140)),
        PadItem(id: "nest", nameKey: "pad_nest", unlock: .bonusReward(8)),
        PadItem(id: "coralring", nameKey: "pad_coralring", unlock: .coins(price: CoinBank.pricePadRare)),
        PadItem(id: "bubble", nameKey: "pad_bubble", unlock: .coins(price: CoinBank.pricePad, bonusCount: 18)),
        PadItem(id: "sunburst", nameKey: "pad_sunburst", unlock: .premium),
    ]

    /// Every shelf, sorted onto the how-you-get-it ladder. These are the lists
    /// the whole app reads - the shop, the pond roster, the collection tallies -
    /// so an item sits in the same place wherever it is drawn.
    static let themes: [ThemeItem] = byUnlock(authoredThemes) { $0.unlock }
    static let skins: [SkinItem] = byUnlock(authoredSkins) { $0.unlock }
    static let pads: [PadItem] = byUnlock(authoredPads) { $0.unlock }

    // MARK: - Rewards

    /// A prize a pond pays out, whatever shelf it came from - so the level list
    /// and the win card can talk about "what you get" without caring whether it
    /// is a friend, a sky or a lily pad.
    enum Reward {
        case skin(SkinItem)
        case theme(ThemeItem)
        case pad(PadItem)
        case decor(PondCatalog.Decor)

        var nameKey: String {
            switch self {
            case .skin(let item): return item.nameKey
            case .theme(let item): return item.nameKey
            case .pad(let item): return item.nameKey
            case .decor(let item): return item.nameKey
            }
        }
    }

    /// The prize the golden-pond ladder pays at `count` cleared ponds.
    ///
    /// Android's `GoldenPondLadderTest` proves exactly one thing sits on every
    /// rung from 1 to the last golden pond, so this never has to choose between
    /// two.
    static func bonusPrizeAt(_ count: Int) -> Reward? {
        func rung(_ unlock: Unlock) -> Int? {
            switch unlock {
            case .bonusReward(let c): return c
            case .coins(_, let bonusCount): return bonusCount
            default: return nil
            }
        }
        if let item = skins.first(where: { rung($0.unlock) == count }) { return .skin(item) }
        if let item = pads.first(where: { rung($0.unlock) == count }) { return .pad(item) }
        if let item = themes.first(where: { rung($0.unlock) == count }) { return .theme(item) }
        if let item = PondCatalog.decor.first(where: { $0.bonusCount == count }) { return .decor(item) }
        return nil
    }

    /// The product id a `Reward` is owned under.
    static func productIdOf(_ reward: Reward) -> String {
        switch reward {
        case .skin(let item): return skinProductId(item.id)
        case .pad(let item): return padProductId(item.id)
        case .theme(let item): return themeProductId(item.id)
        case .decor(let item): return PondCatalog.decorProductId(item.id)
        }
    }

    /// How `reward` is unlocked, for an ownership check.
    static func unlockOf(_ reward: Reward) -> Unlock {
        switch reward {
        case .skin(let item): return item.unlock
        case .pad(let item): return item.unlock
        case .theme(let item): return item.unlock
        // A decoration has no Unlock of its own: coins, or the golden pond rung.
        case .decor(let item): return .coins(price: item.price, bonusCount: item.bonusCount)
        }
    }

    /// What solving global level `level` pays out, or nil if it pays nothing.
    static func rewardAtLevel(_ level: Int) -> Reward? {
        if let item = skins.first(where: { $0.unlock.rewardLevel == level }) { return .skin(item) }
        if let item = themes.first(where: { $0.unlock.rewardLevel == level }) { return .theme(item) }
        if let item = pads.first(where: { $0.unlock.rewardLevel == level }) { return .pad(item) }
        return nil
    }

    /// Every level number that pays a prize - the level list's badge test.
    static let rewardLevels: Set<Int> = Set(
        (skins.map(\.unlock) + themes.map(\.unlock) + pads.map(\.unlock))
            .compactMap(\.rewardLevel)
    )

    /// The next prize waiting after `level`, with the level that pays it.
    ///
    /// The win card uses it to say what is coming. Rewards used to arrive with
    /// no warning at all, which made them feel like weather rather than
    /// something you were climbing towards.
    static func nextRewardAfter(_ level: Int) -> (Int, Reward)? {
        guard let at = rewardLevels.filter({ $0 > level }).min(),
              let reward = rewardAtLevel(at) else { return nil }
        return (at, reward)
    }

    static func themeById(_ id: String?) -> ThemeItem {
        themes.first { $0.id == id } ?? themes[0]
    }

    static func skinById(_ id: String?) -> SkinItem {
        skins.first { $0.id == id } ?? skins[0]
    }

    static func padById(_ id: String?) -> PadItem {
        pads.first { $0.id == id } ?? pads[0]
    }

    static func themeProductId(_ id: String) -> String { "theme_\(id)" }
    static func skinProductId(_ id: String) -> String { "skin_\(id)" }
    static func padProductId(_ id: String) -> String { "pad_\(id)" }
}
