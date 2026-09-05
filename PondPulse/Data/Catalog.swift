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

    /// Granted forever once the given number of golden ponds have been cleared.
    case bonusReward(Int)

    /// Granted forever once the Daily Pond has been cleared this many days
    /// running. Read against the player's *best* streak, never the live one: an
    /// unlock is permanent, so breaking a streak costs the run, not the prize.
    case streakReward(Int)

    /// Included with the premium upgrade; hidden from the shop until owned.
    case premium

    /// Comes free with a theme: owning that theme owns this too.
    ///
    /// Every theme but the two free ones has a pair of friends who belong to it
    /// - the toucan lives in the jungle, the comet duck in the galaxy - and the
    /// theme is the only door to them. It is not a second price tag: whatever
    /// the theme cost, in coins, in levels, in golden ponds or in the premium
    /// upgrade, is what these cost, and a theme already owned hands its pair
    /// over the moment the app opens.
    ///
    /// The two free themes have no pair, deliberately. A friend that arrives
    /// before the player has done anything is not a friend they got.
    case themeFriend(String)

    /// Bought with money rather than with coins or with play.
    ///
    /// The five special friends, and nothing else. Everything on the ordinary
    /// shelves is reachable by playing; these are the one place that is not
    /// true, which is why they are a small, closed set at the end of the shelf
    /// rather than a band the catalogue can grow into.
    ///
    /// The price shown must come from StoreKit, never from this number - a
    /// hard-coded "$0.99" is wrong in every country that does not use dollars.
    case money(cents: Int)

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

    /// The theme that hands this item over, if a theme is how you get it.
    var themeFriendOf: String? {
        if case .themeFriend(let id) = self { return id }
        return nil
    }

    var isMoney: Bool {
        if case .money = self { return true }
        return false
    }

    /// Where an item sits on the ladder of *how you get it*, so every shelf reads
    /// the same way: free, then earned in a golden pond, then earned on a daily
    /// streak, then handed over by a theme, then bought, then premium.
    ///
    /// The catalog lists used to be raw authoring order - two shelves written
    /// months apart and appended - so the Tadpole sat below every premium skin,
    /// and a shelf gave no sense of what was coming next.
    var rank: Int {
        switch self {
        case .free: return 0
        case .bonusReward: return 1
        case .streakReward: return 2
        case .themeFriend: return 3
        case .coins: return 4
        case .premium: return 5
        case .money: return 6
        }
    }

    /// Within a rank, the cheaper or sooner one comes first.
    var step: Int {
        switch self {
        case .bonusReward(let count): return count
        case .streakReward(let days): return days
        case .coins(let price, _): return price
        case .money(let cents): return cents
        // A theme friend has no step of its own: the sort is stable, so the
        // twenty of them keep the order they are authored in, which is theme by
        // theme in pairs. Ordering them by their theme's own price instead
        // would split every pair across the shelf.
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

    /// Consumable hint pack: 25 hints per purchase. Premium never needs it.
    ///
    /// The id still says 50, and stays that way. It is live in App Store Connect
    /// and shared with Android's Play Billing id, and an id that moves when the
    /// *contents* change is an id that loses somebody their purchase - the same
    /// rule the coin packs keep. How many a pack grants is what a re-tune gets
    /// to change; what the pack is called is not.
    static let hintsId = "hints_50"
    static let hintsPrice = "$1.99"
    static let hintsPerPack = 25

    /// What one special friend costs, in US cents - $0.99 each.
    ///
    /// The five are priced identically on purpose. A shelf of five mythical
    /// friends at five different prices asks the player to rank them, and the
    /// answer would only ever be "the cheapest"; at one price the question is
    /// which one they like. The *displayed* price comes from StoreKit.
    static let specialCents = 99

    /// A theme bought with money rather than coins.
    ///
    /// Two bands, because they are not the same kind of thing. Autumn Gold moved
    /// off the coin shelf onto the cheaper one - it was always the prettiest of
    /// the coin themes and it is still the gentlest thing money buys. Opal and
    /// Ember were drawn for this band and cost more: the whole point of them is
    /// that they do not look like the twelve palettes anyone can earn.
    static let themeCents = 199
    static let themeGrandCents = 299

    /// The coin packs, in catalog order - the one place money buys coins rather
    /// than the other way round. Paired index for index with
    /// `CoinBank.coinPacks`, so a pack can never grant an amount the economy has
    /// not been priced against.
    ///
    /// Written out rather than interpolated from the amounts. They used to read
    /// `"coins_\(amount)"`, which was tidy right up until the ×10 rescale moved
    /// the amounts and silently renamed all three products - the ids are live in
    /// App Store Connect with real purchases behind them, and an id that drifts
    /// when a *price* changes is an id that loses somebody their coins. The
    /// amount a pack grants is what a rescale gets to change; what the pack is
    /// called is not.
    static let coinPackIds = ["coins_100", "coins_250", "coins_500"]

    /// Offline fallback prices for the coin packs, in `coinPackIds` order. The
    /// App Store's own display prices win once StoreKit has loaded.
    static let coinPackPrices = ["$0.99", "$1.99", "$3.99"]

    /// How many coins the product id grants, or nil if it is not a coin pack.
    static func coinsInPack(_ productId: String) -> Int? {
        guard let index = coinPackIds.firstIndex(of: productId) else { return nil }
        return CoinBank.coinPacks[index]
    }

    // MARK: - Shelves

    /// The theme shelf, in the order it reads: the two you start with, the two
    /// you earn by playing, the six you save up for cheapest first, then the one
    /// premium brings and the three money buys.
    ///
    /// Sorted the way the friends shelf is - by how it is unlocked, then by
    /// price - because a shelf that mixes a free theme, a 5500-coin theme and a
    /// level reward in its first three rows gives a new player no idea which of
    /// them they could actually have.
    private static let authoredThemes: [ThemeItem] = [
        ThemeItem(id: "dusk", nameKey: "theme_dusk", palette: .duskPond, unlock: .free),
        ThemeItem(id: "sunny", nameKey: "theme_sunny", palette: .sunnyMorning, unlock: .free),
        ThemeItem(id: "jungle", nameKey: "theme_jungle", palette: .jungleMist, unlock: .coins(price: CoinBank.priceTheme)),
        ThemeItem(id: "goldenpond", nameKey: "theme_goldenpond", palette: .goldenPond, unlock: .bonusReward(10)),
        ThemeItem(id: "sakura", nameKey: "theme_sakura", palette: .sakuraPond, unlock: .coins(price: CoinBank.priceTheme)),
        ThemeItem(id: "frozen", nameKey: "theme_frozen", palette: .frozenPond, unlock: .coins(price: CoinBank.priceTheme)),
        ThemeItem(id: "coral", nameKey: "theme_coral", palette: .coralReef, unlock: .coins(price: CoinBank.priceTheme)),
        ThemeItem(id: "neon", nameKey: "theme_neon", palette: .midnightNeon, unlock: .coins(price: CoinBank.priceThemeRare)),
        ThemeItem(id: "galaxy", nameKey: "theme_galaxy", palette: .galaxyNight, unlock: .coins(price: CoinBank.priceThemeRare)),
        ThemeItem(id: "candy", nameKey: "theme_candy", palette: .candyPop, unlock: .coins(price: CoinBank.priceThemeRare)),
        ThemeItem(id: "royal", nameKey: "theme_royal", palette: .royalLagoon, unlock: .premium),
        ThemeItem(id: "autumn", nameKey: "theme_autumn", palette: .autumnGold, unlock: .money(cents: themeCents)),
        ThemeItem(id: "opal", nameKey: "theme_opal", palette: .opalLagoon, unlock: .money(cents: themeGrandCents)),
        ThemeItem(id: "ember", nameKey: "theme_ember", palette: .emberHollow, unlock: .money(cents: themeGrandCents)),
    ]

    private static let authoredSkins: [SkinItem] = [
        SkinItem(id: "duck", nameKey: "skin_duck", unlock: .free),
        SkinItem(id: "frog", nameKey: "skin_frog", unlock: .coins(price: CoinBank.priceLadderSkin[1])),
        SkinItem(id: "swan", nameKey: "skin_swan", unlock: .coins(price: CoinBank.priceLadderSkin[4])),
        SkinItem(id: "robo", nameKey: "skin_robo", unlock: .coins(price: CoinBank.priceLadderSkin[8])),
        SkinItem(id: "golden", nameKey: "skin_golden", unlock: .coins(price: CoinBank.priceLadderSkin[11])),
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
        // The second shelf. These twelve used to arrive at a level number
        // each; they are the coin ladder now, cheapest where the level was
        // lowest, so the run still reads in the order it was authored in.
        SkinItem(id: "tadpole", nameKey: "skin_tadpole", unlock: .free),
        SkinItem(id: "snail", nameKey: "skin_snail", unlock: .coins(price: CoinBank.priceLadderSkin[0])),
        SkinItem(id: "crab", nameKey: "skin_crab", unlock: .coins(price: CoinBank.priceLadderSkin[2])),
        SkinItem(id: "heron", nameKey: "skin_heron", unlock: .coins(price: CoinBank.priceLadderSkin[3])),
        SkinItem(id: "goose", nameKey: "skin_goose", unlock: .coins(price: CoinBank.priceLadderSkin[5])),
        SkinItem(id: "capybara", nameKey: "skin_capybara", unlock: .coins(price: CoinBank.priceLadderSkin[6])),
        SkinItem(id: "seal", nameKey: "skin_seal", unlock: .coins(price: CoinBank.priceLadderSkin[7])),
        SkinItem(id: "pelican", nameKey: "skin_pelican", unlock: .coins(price: CoinBank.priceLadderSkin[9])),
        SkinItem(id: "kingfisher", nameKey: "skin_kingfisher", unlock: .coins(price: CoinBank.priceLadderSkin[10])),
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

        // The theme pairs. Authored theme by theme, in the order the themes
        // themselves are authored, because the sort keeps a rank's authoring
        // order and these must never be split up: the pair *is* the theme.
        SkinItem(id: "toucan", nameKey: "skin_toucan", unlock: .themeFriend("jungle")),
        SkinItem(id: "treefrog", nameKey: "skin_treefrog", unlock: .themeFriend("jungle")),
        SkinItem(id: "mandarin", nameKey: "skin_mandarin", unlock: .themeFriend("goldenpond")),
        SkinItem(id: "goldfish", nameKey: "skin_goldfish", unlock: .themeFriend("goldenpond")),
        SkinItem(id: "swallow", nameKey: "skin_swallow", unlock: .themeFriend("sakura")),
        SkinItem(id: "blossomkoi", nameKey: "skin_blossomkoi", unlock: .themeFriend("sakura")),
        SkinItem(id: "neontetra", nameKey: "skin_neontetra", unlock: .themeFriend("neon")),
        SkinItem(id: "glowjelly", nameKey: "skin_glowjelly", unlock: .themeFriend("neon")),
        SkinItem(id: "wooduck", nameKey: "skin_wooduck", unlock: .themeFriend("autumn")),
        SkinItem(id: "squirrel", nameKey: "skin_squirrel", unlock: .themeFriend("autumn")),
        SkinItem(id: "snowgoose", nameKey: "skin_snowgoose", unlock: .themeFriend("frozen")),
        SkinItem(id: "icefish", nameKey: "skin_icefish", unlock: .themeFriend("frozen")),
        SkinItem(id: "clownfish", nameKey: "skin_clownfish", unlock: .themeFriend("coral")),
        SkinItem(id: "starfish", nameKey: "skin_starfish", unlock: .themeFriend("coral")),
        SkinItem(id: "cometduck", nameKey: "skin_cometduck", unlock: .themeFriend("galaxy")),
        SkinItem(id: "moonjelly", nameKey: "skin_moonjelly", unlock: .themeFriend("galaxy")),
        SkinItem(id: "gummyduck", nameKey: "skin_gummyduck", unlock: .themeFriend("candy")),
        SkinItem(id: "bubblegum", nameKey: "skin_bubblegum", unlock: .themeFriend("candy")),
        SkinItem(id: "royalswan", nameKey: "skin_royalswan", unlock: .themeFriend("royal")),
        SkinItem(id: "peacock", nameKey: "skin_peacock", unlock: .themeFriend("royal")),
        SkinItem(id: "opalkoi", nameKey: "skin_opalkoi", unlock: .themeFriend("opal")),
        SkinItem(id: "pearlswan", nameKey: "skin_pearlswan", unlock: .themeFriend("opal")),
        SkinItem(id: "emberdrake", nameKey: "skin_emberdrake", unlock: .themeFriend("ember")),
        SkinItem(id: "cindermoth", nameKey: "skin_cindermoth", unlock: .themeFriend("ember")),

        // The five special friends: the only things in PondPulse that cost
        // money on their own. A closed set, at the end of the shelf, so the
        // shelf above it stays a shelf you can play your way onto.
        SkinItem(id: "starwhale", nameKey: "skin_starwhale", unlock: .money(cents: specialCents)),
        SkinItem(id: "kitsune", nameKey: "skin_kitsune", unlock: .money(cents: specialCents)),
        SkinItem(id: "griffin", nameKey: "skin_griffin", unlock: .money(cents: specialCents)),
        SkinItem(id: "seadragon", nameKey: "skin_seadragon", unlock: .money(cents: specialCents)),
        SkinItem(id: "moonrabbit", nameKey: "skin_moonrabbit", unlock: .money(cents: specialCents)),

        // The far end of every route: the friend for finishing all thirty
        // golden ponds, two more rungs on the daily streak, and a top coin band
        // worth most of a pack. Each is the last thing on its own ladder.
        SkinItem(id: "goldenturtle", nameKey: "skin_goldenturtle", unlock: .bonusReward(30)),
        SkinItem(id: "firefly", nameKey: "skin_firefly", unlock: .streakReward(50)),
        SkinItem(id: "owl", nameKey: "skin_owl", unlock: .streakReward(75)),
        SkinItem(id: "kraken", nameKey: "skin_kraken", unlock: .coins(price: CoinBank.priceSkinLegendary)),
        SkinItem(id: "anglerfish", nameKey: "skin_anglerfish", unlock: .coins(price: CoinBank.priceSkinLegendary)),
        SkinItem(id: "manta", nameKey: "skin_manta", unlock: .coins(price: CoinBank.priceSkinLegendary)),
        SkinItem(id: "raven", nameKey: "skin_raven", unlock: .coins(price: CoinBank.priceSkinLegendary)),
        SkinItem(id: "lionfish", nameKey: "skin_lionfish", unlock: .coins(price: CoinBank.priceSkinLegendary)),
    ]

    private static let authoredPads: [PadItem] = [
        PadItem(id: "lily", nameKey: "pad_lily", unlock: .free),
        PadItem(id: "lotus", nameKey: "pad_lotus", unlock: .coins(price: CoinBank.priceLadderPad[1])),
        PadItem(id: "starlight", nameKey: "pad_starlight", unlock: .coins(price: CoinBank.priceLadderPad[3])),
        PadItem(id: "rainbow", nameKey: "pad_rainbow", unlock: .coins(price: CoinBank.priceLadderPad[5])),
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
        PadItem(id: "leaf", nameKey: "pad_leaf", unlock: .coins(price: CoinBank.priceLadderPad[0])),
        PadItem(id: "mushroom", nameKey: "pad_mushroom", unlock: .coins(price: CoinBank.priceLadderPad[2])),
        PadItem(id: "stone", nameKey: "pad_stone", unlock: .coins(price: CoinBank.priceLadderPad[4])),
        PadItem(id: "cloud", nameKey: "pad_cloud", unlock: .coins(price: CoinBank.priceLadderPad[6])),
        PadItem(id: "nest", nameKey: "pad_nest", unlock: .bonusReward(8)),
        PadItem(id: "coralring", nameKey: "pad_coralring", unlock: .coins(price: CoinBank.pricePadRare)),
        PadItem(id: "bubble", nameKey: "pad_bubble", unlock: .coins(price: CoinBank.pricePad, bonusCount: 18)),
        PadItem(id: "sunburst", nameKey: "pad_sunburst", unlock: .premium),

        // The pad shelf gains the same rungs as the friends shelf, so the two
        // read as siblings: a golden-pond capstone, two streak pads, and a top
        // coin band. Pads are priced under friends throughout - a pad is what
        // the duckling stands on, not what it is - so the top band is 400.
        PadItem(id: "crownlily", nameKey: "pad_crownlily", unlock: .bonusReward(30)),
        PadItem(id: "ember", nameKey: "pad_ember", unlock: .streakReward(50)),
        PadItem(id: "frost", nameKey: "pad_frost", unlock: .streakReward(75)),
        PadItem(id: "pearl", nameKey: "pad_pearl", unlock: .coins(price: CoinBank.pricePadLegendary)),
        PadItem(id: "obsidian", nameKey: "pad_obsidian", unlock: .coins(price: CoinBank.pricePadLegendary)),
        PadItem(id: "origami", nameKey: "pad_origami", unlock: .coins(price: CoinBank.pricePadLegendary)),
        PadItem(id: "rune", nameKey: "pad_rune", unlock: .coins(price: CoinBank.pricePadLegendary)),
        PadItem(id: "prism", nameKey: "pad_prism", unlock: .coins(price: CoinBank.pricePadLegendary)),
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
    static func bonusPrizesAt(_ count: Int) -> [Reward] {
        func rung(_ unlock: Unlock) -> Int? {
            switch unlock {
            case .bonusReward(let c): return c
            case .coins(_, let bonusCount): return bonusCount
            default: return nil
            }
        }
        var out: [Reward] = []
        out += skins.filter { rung($0.unlock) == count }.map { Reward.skin($0) }
        out += pads.filter { rung($0.unlock) == count }.map { Reward.pad($0) }
        out += themes.filter { rung($0.unlock) == count }.map { Reward.theme($0) }
        out += PondCatalog.decor.filter { $0.bonusCount == count }.map { Reward.decor($0) }
        return out
    }

    /// The friends that come with a theme, in shelf order.
    static func friendsOfTheme(_ themeId: String) -> [SkinItem] {
        skins.filter { $0.unlock.themeFriendOf == themeId }
    }

    /// The theme a friend belongs to, or nil if it is not a theme friend.
    static func themeOfFriend(_ skin: SkinItem) -> ThemeItem? {
        skin.unlock.themeFriendOf.flatMap { id in themes.first { $0.id == id } }
    }

    /// The five friends money buys outright, in shelf order.
    static let specialSkins: [SkinItem] = skins.filter(\.unlock.isMoney)

    /// Every theme that has a pair of friends, in shelf order.
    static let themesWithFriends: [ThemeItem] = themes.filter { !friendsOfTheme($0.id).isEmpty }

    /// Everything StoreKit sells, and everything it must be asked about.
    ///
    /// The one list the store queries for prices and the one list the shop
    /// checks before drawing a price. Anything not on it is bought with coins
    /// or earned by playing, and must never reach a purchase.
    static let moneyProductIds: [String] =
        [premiumId, hintsId] + coinPackIds
            + specialSkins.map { skinProductId($0.id) }
            + moneyThemes.map { themeProductId($0.id) }

    /// The themes money buys outright, in shelf order.
    static let moneyThemes: [ThemeItem] = themes.filter(\.unlock.isMoney)

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
