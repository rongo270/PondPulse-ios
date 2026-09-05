//
//  PondCatalog.swift
//  PondPulse
//
//  A 1:1 port of the Android pond/PondCatalog.kt.
//

import CoreGraphics
import Foundation

/// Everything the pond itself sells, and the four games played on it.
///
/// Kept apart from `Catalog`, which sells what you *play as* - friends, pads and
/// themes. This file sells what the pond *is*: the things floating on it, the
/// sky over it, and the seats around it. Two catalogues rather than one because
/// they are bought in two different places and neither list should grow a column
/// of "not for sale here".
enum PondCatalog {

    /// Where a decoration is allowed to be: floating, or on the bank.
    enum Zone {
        case water, shore
    }

    /// One decoration.
    ///
    /// `at` is only where it *starts*. The Decorate screen lets the player drag
    /// it anywhere its `zone` allows, and that position is saved - a pond you
    /// arrange yourself is the whole point of the screen, and a catalogue of
    /// fixed anchors made every pond look the same.
    ///
    /// The zone is not decoration: a dock floating in open water and a lily
    /// stranded on grass both read as bugs, so a shore item dragged over the
    /// water slides back to the nearest bank and a water item dragged onto the
    /// grass does the reverse.
    struct Decor: Identifiable, Hashable {
        let id: String
        let nameKey: String
        let price: Int
        let zone: Zone
        /// Where it sits before anyone moves it, in fractions of the pond.
        let at: CGPoint
        /// Side length, in fractions of the pond's width.
        let scale: CGFloat
        /// Cleared golden ponds that grant this one outright, or nil if coins
        /// are the only way to it.
        ///
        /// A decoration is the one thing in the pond that had no route except
        /// paying, which is why golden ponds could not hand one out. It keeps
        /// its `price` as well: the golden pond is a second door, not a
        /// replacement, so nobody who was saving up for a bench loses the bench.
        let bonusCount: Int?

        init(
            _ id: String,
            _ nameKey: String,
            _ price: Int,
            _ zone: Zone,
            _ at: CGPoint,
            _ scale: CGFloat,
            bonusCount: Int? = nil
        ) {
            self.id = id
            self.nameKey = nameKey
            self.price = price
            self.zone = zone
            self.at = at
            self.scale = scale
            self.bonusCount = bonusCount
        }
    }

    /// A sky: the light over the water, and whatever falls out of it.
    struct Weather: Identifiable, Hashable {
        let id: String
        let nameKey: String
        let price: Int

        init(_ id: String, _ nameKey: String, _ price: Int) {
            self.id = id
            self.nameKey = nameKey
            self.price = price
        }
    }

    /// Everything the pond sells, cheapest first.
    ///
    /// The order is the order the Decorate tray shows them, and it is by price
    /// on purpose: the first thing a player can afford is the first thing they
    /// see, and the willow at the far end is what the tray is for.
    static let decor: [Decor] = [
        Decor("reeds", "decor_reeds", 600, .water, CGPoint(x: 0.13, y: 0.28), 0.22, bonusCount: 2),
        Decor("toadstools", "decor_toadstools", 800, .shore, CGPoint(x: 0.52, y: 0.94), 0.13, bonusCount: 6),
        Decor("buoy", "decor_buoy", 900, .water, CGPoint(x: 0.86, y: 0.68), 0.11, bonusCount: 11),
        Decor("flowers", "decor_flowers", 1000, .water, CGPoint(x: 0.55, y: 0.72), 0.16, bonusCount: 14),
        Decor("birdhouse", "decor_birdhouse", 1200, .shore, CGPoint(x: 0.84, y: 0.06), 0.14, bonusCount: 17),
        Decor("lilies", "decor_lilies", 1300, .water, CGPoint(x: 0.72, y: 0.30), 0.21, bonusCount: 21),
        Decor("log", "decor_log", 1500, .water, CGPoint(x: 0.26, y: 0.62), 0.28, bonusCount: 24),
        Decor("bench", "decor_bench", 1600, .shore, CGPoint(x: 0.22, y: 0.93), 0.21, bonusCount: 27),
        Decor("rock", "decor_rock", 1700, .water, CGPoint(x: 0.87, y: 0.46), 0.17, bonusCount: 30),
        Decor("stones", "decor_stones", 1900, .water, CGPoint(x: 0.62, y: 0.55), 0.26),
        Decor("fence", "decor_fence", 2000, .shore, CGPoint(x: 0.17, y: 0.055), 0.27),
        Decor("lantern", "decor_lantern", 2200, .water, CGPoint(x: 0.40, y: 0.40), 0.13),
        Decor("dock", "decor_dock", 2500, .shore, CGPoint(x: 0.33, y: 0.075), 0.30),
        Decor("spring", "decor_spring", 2800, .water, CGPoint(x: 0.50, y: 0.26), 0.18),
        Decor("boat", "decor_boat", 3200, .water, CGPoint(x: 0.30, y: 0.44), 0.27),
        Decor("willow", "decor_willow", 3800, .shore, CGPoint(x: 0.82, y: 0.90), 0.33),

        // The second shelf. Fourteen more, none of them on the golden-pond
        // ladder: all thirty rungs were already spoken for, and moving one
        // would revoke a prize somebody has already earned.
        Decor("gnome", "decor_gnome", 700, .shore, CGPoint(x: 0.66, y: 0.055), 0.12),
        Decor("cattails", "decor_cattails", 950, .water, CGPoint(x: 0.07, y: 0.62), 0.19),
        Decor("mailbox", "decor_mailbox", 1100, .shore, CGPoint(x: 0.06, y: 0.93), 0.14),
        Decor("koi", "decor_koi", 1400, .water, CGPoint(x: 0.45, y: 0.58), 0.24),
        Decor("picnic", "decor_picnic", 1750, .shore, CGPoint(x: 0.42, y: 0.055), 0.24),
        Decor("swans", "decor_swans", 1950, .water, CGPoint(x: 0.66, y: 0.42), 0.26),
        Decor("hammock", "decor_hammock", 2100, .shore, CGPoint(x: 0.60, y: 0.94), 0.29),
        Decor("firepit", "decor_firepit", 2350, .shore, CGPoint(x: 0.10, y: 0.055), 0.18),
        Decor("fountain", "decor_fountain", 2550, .water, CGPoint(x: 0.50, y: 0.36), 0.22),
        Decor("swing", "decor_swing", 2700, .shore, CGPoint(x: 0.90, y: 0.94), 0.26),
        Decor("arch", "decor_arch", 2950, .shore, CGPoint(x: 0.50, y: 0.055), 0.26),
        Decor("canoe", "decor_canoe", 3100, .water, CGPoint(x: 0.20, y: 0.34), 0.30),
        Decor("waterwheel", "decor_waterwheel", 3500, .water, CGPoint(x: 0.90, y: 0.60), 0.26),
        Decor("pier", "decor_pier", 4000, .shore, CGPoint(x: 0.14, y: 0.075), 0.34),
    ].sorted { $0.price < $1.price }

    /// Day is free and is what a new pond looks like; the rest are bought. The
    /// order is the order they appear in the pond's shop.
    static let weathers: [Weather] = [
        Weather("day", "weather_day", 0),
        Weather("sunset", "weather_sunset", 1500),
        Weather("fog", "weather_fog", 1600),
        Weather("night", "weather_night", 1800),
        Weather("rain", "weather_rain", 2000),
        Weather("snow", "weather_snow", 2200),
        Weather("aurora", "weather_aurora", 2400),
        Weather("storm", "weather_storm", 2600),
        Weather("rainbow", "weather_rainbow", 2800),
        Weather("starry", "weather_starry", 3000),
    ]

    /// The surface of the water, and the bank around it.
    ///
    /// Both were fixed until now: the sky changed and everything under it
    /// stayed the same pond. They are separate from the sky on purpose - a
    /// bright noon over dark koi water is a real pond somebody would want, and
    /// folding the two together would make it unreachable.
    ///
    /// The first of each is free and is what an unarranged pond looks like, so
    /// nobody has to buy their way back to the default.
    struct Surface: Identifiable, Hashable {
        let id: String
        let nameKey: String
        let price: Int

        init(_ id: String, _ nameKey: String, _ price: Int) {
            self.id = id
            self.nameKey = nameKey
            self.price = price
        }
    }

    static let waters: [Surface] = [
        Surface("clear", "water_clear", 0),
        Surface("reedy", "water_reedy", 1200),
        Surface("deep", "water_deep", 1400),
        Surface("sparkle", "water_sparkle", 1500),
        Surface("mirror", "water_mirror", 1600),
        Surface("emerald", "water_emerald", 1700),
    ]

    static let shores: [Surface] = [
        Surface("meadow", "shore_meadow", 0),
        Surface("sand", "shore_sand", 1200),
        Surface("pebbles", "shore_pebbles", 1400),
        Surface("moss", "shore_moss", 1500),
        Surface("snow", "shore_snow", 1700),
        Surface("autumn", "shore_autumn", 1800),
    ]

    /// Saved ponds. Three is enough for a summer pond, a winter one and one
    /// being tinkered with, and few enough that the tab is a row of thumbnails.
    static let layoutSlots = 3

    static func waterById(_ id: String?) -> Surface { waters.first { $0.id == id } ?? waters[0] }
    static func shoreById(_ id: String?) -> Surface { shores.first { $0.id == id } ?? shores[0] }

    /// Product id prefixes, so a bought decoration lands in the same owned set.
    ///
    /// `nonisolated` because they are string concatenation over their argument
    /// and touch no state at all. `SWIFT_DEFAULT_ACTOR_ISOLATION` otherwise puts
    /// them on the main actor, and then passing one *by reference* - which
    /// Decorate does, handing `waterProductId` to `surfaceStrip` - is an
    /// isolation crossing the compiler has to warn about, for a function that
    /// could never have raced with anything.
    nonisolated static func decorProductId(_ id: String) -> String { "decor_\(id)" }
    nonisolated static func weatherProductId(_ id: String) -> String { "weather_\(id)" }
    nonisolated static func waterProductId(_ id: String) -> String { "water_\(id)" }
    nonisolated static func shoreProductId(_ id: String) -> String { "shore_\(id)" }

    static func decorById(_ id: String) -> Decor? { decor.first { $0.id == id } }

    static func weatherById(_ id: String?) -> Weather {
        weathers.first { $0.id == id } ?? weathers[0]
    }

    /// One of the four games.
    ///
    /// `coinsPerPoint` and `coinCap` together are the whole payout rule: a run's
    /// score divides down to a handful of coins and can never pay more than the
    /// cap, whatever happens on the board. Deliberately stingy - the week's
    /// ceiling is `CoinBank.pondWeeklyCap` and no single run should be a
    /// meaningful slice of it.
    struct MiniGame: Identifiable, Hashable {
        let id: String
        let nameKey: String
        let blurbKey: String
        let coinsPerPoint: Int
        let coinCap: Int

        init(_ id: String, _ nameKey: String, _ blurbKey: String, _ coinsPerPoint: Int, _ coinCap: Int) {
            self.id = id
            self.nameKey = nameKey
            self.blurbKey = blurbKey
            self.coinsPerPoint = coinsPerPoint
            self.coinCap = coinCap
        }
    }

    /// The four games, in the order the pond lists them.
    static let games: [MiniGame] = [
        MiniGame("chain", "game_chain", "game_chain_blurb", 5, 10),
        MiniGame("herd", "game_herd", "game_herd_blurb", 2, 10),
        MiniGame("seek", "game_seek", "game_seek_blurb", 1, 10),
        MiniGame("target", "game_target", "game_target_blurb", 1, 10),
    ]

    static func gameById(_ id: String) -> MiniGame? { games.first { $0.id == id } }

    /// How much more a run pays than the rate the four games were tuned at.
    ///
    /// The games are the pond's only earner and the original tuning was stingy
    /// enough to read as mean rather than as restraint - a run that played
    /// perfectly was worth a tenth of the week. Everything a run can pay goes up
    /// by a fifth, and `CoinBank.pondWeeklyCap` goes up by the same fifth: a
    /// raise under an unchanged ceiling only ever reaches the players who were
    /// not hitting the ceiling anyway.
    ///
    /// Written as a fraction rather than as `1.2`, and applied with integer
    /// division, because the whole point of a multiplier here is that it lands
    /// on a whole coin: `Int(Double(10) * 1.2)` is arithmetic that can pay 11
    /// on one build and 12 on the next, and coins are the one number in the app
    /// nobody should have to take on trust.
    static let payoutBoost = (times: 6, over: 5)

    /// `coins` at the boosted rate.
    ///
    /// Rounded up rather than to nearest, so the smallest run that earned
    /// anything at all still earns it - a raise that rounded a single coin back
    /// down to none would be a pay cut for exactly the player it was for.
    static func boosted(_ coins: Int) -> Int {
        guard coins > 0 else { return 0 }
        return (coins * payoutBoost.times + payoutBoost.over - 1) / payoutBoost.over
    }

    /// A run's coins before the week's ceiling is applied.
    static func coinsFor(_ game: MiniGame, score: Int) -> Int {
        boosted(min(max(score, 0) / game.coinsPerPoint, game.coinCap))
    }
}
