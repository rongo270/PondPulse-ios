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
        Decor("reeds", "decor_reeds", 60, .water, CGPoint(x: 0.13, y: 0.28), 0.22, bonusCount: 2),
        Decor("toadstools", "decor_toadstools", 80, .shore, CGPoint(x: 0.52, y: 0.94), 0.13, bonusCount: 6),
        Decor("buoy", "decor_buoy", 90, .water, CGPoint(x: 0.86, y: 0.68), 0.11, bonusCount: 11),
        Decor("flowers", "decor_flowers", 100, .water, CGPoint(x: 0.55, y: 0.72), 0.16, bonusCount: 14),
        Decor("birdhouse", "decor_birdhouse", 120, .shore, CGPoint(x: 0.84, y: 0.06), 0.14, bonusCount: 17),
        Decor("lilies", "decor_lilies", 130, .water, CGPoint(x: 0.72, y: 0.30), 0.21, bonusCount: 21),
        Decor("log", "decor_log", 150, .water, CGPoint(x: 0.26, y: 0.62), 0.28, bonusCount: 24),
        Decor("bench", "decor_bench", 160, .shore, CGPoint(x: 0.22, y: 0.93), 0.21, bonusCount: 27),
        Decor("rock", "decor_rock", 170, .water, CGPoint(x: 0.87, y: 0.46), 0.17, bonusCount: 30),
        Decor("stones", "decor_stones", 190, .water, CGPoint(x: 0.62, y: 0.55), 0.26),
        Decor("fence", "decor_fence", 200, .shore, CGPoint(x: 0.17, y: 0.055), 0.27),
        Decor("lantern", "decor_lantern", 220, .water, CGPoint(x: 0.40, y: 0.40), 0.13),
        Decor("dock", "decor_dock", 250, .shore, CGPoint(x: 0.33, y: 0.075), 0.30),
        Decor("spring", "decor_spring", 280, .water, CGPoint(x: 0.50, y: 0.26), 0.18),
        Decor("boat", "decor_boat", 320, .water, CGPoint(x: 0.30, y: 0.44), 0.27),
        Decor("willow", "decor_willow", 380, .shore, CGPoint(x: 0.82, y: 0.90), 0.33),
    ]

    /// Day is free and is what a new pond looks like; the rest are bought. The
    /// order is the order they appear in the pond's shop.
    static let weathers: [Weather] = [
        Weather("day", "weather_day", 0),
        Weather("sunset", "weather_sunset", 150),
        Weather("fog", "weather_fog", 160),
        Weather("night", "weather_night", 180),
        Weather("rain", "weather_rain", 200),
        Weather("snow", "weather_snow", 220),
    ]

    /// Product id prefixes, so a bought decoration lands in the same owned set.
    static func decorProductId(_ id: String) -> String { "decor_\(id)" }
    static func weatherProductId(_ id: String) -> String { "weather_\(id)" }

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

    /// A run's coins before the week's ceiling is applied.
    static func coinsFor(_ game: MiniGame, score: Int) -> Int {
        min(max(score, 0) / game.coinsPerPoint, game.coinCap)
    }
}
