//
//  Achievements.swift
//  PondPulse
//
//  The badge shelf: twenty-four milestones, six families of four. A 1:1 port of
//  the Android data/Achievements.kt.
//
//  ### They are derived, exactly like every other coin
//
//  Nothing here is claimed, banked or stored. Every badge is a question asked of
//  a `Snapshot` of progress, and every one of those numbers can only ever go up:
//  ponds cleared, stars earned, golden ponds finished, dailies, the best streak,
//  the best Splash Rush score, how many friends and decorations are owned. A
//  badge is earned when its number reaches its goal, and its coins fold into
//  `CoinBank.derived` - recomputed from scratch on every read, like the rest.
//
//  That is the whole reason there is no "Claim" button. A claim needs a claimed
//  set to write to, and a second stored ledger is exactly the thing the coin
//  economy was built to avoid: it can drift, it can be replayed, and it needs a
//  repair path. Recomputing cannot.
//
//  ### Why friends and decorations count
//
//  Two of the badges read what the player *owns*, and owning things costs coins,
//  so a purchase can push a badge over its line and pay a little back. That is a
//  rebate, not a loop: the badge pays once, forever, and always less than the
//  item cost. It is here because a collection game whose badges ignore the
//  collection is a badge shelf about something else.
//

import Foundation

enum Achievements {

    /// The six things a player can be getting better at.
    enum Family: String, CaseIterable {
        case ponds, stars, golden, daily, rush, pond

        var titleKey: String {
            switch self {
            case .ponds: return "ach_family_ponds"
            case .stars: return "ach_family_stars"
            case .golden: return "ach_family_golden"
            case .daily: return "ach_family_daily"
            case .rush: return "ach_family_rush"
            case .pond: return "ach_family_pond"
            }
        }

        /// The SF Symbol the row wears. Android has no equivalent - this is the
        /// one place the iOS build reads differently on purpose, because a
        /// family header without a symbol looks unfinished next to the rest of
        /// the app's toolbars.
        var symbol: String {
            switch self {
            case .ponds: return "drop.fill"
            case .stars: return "star.fill"
            case .golden: return "crown.fill"
            case .daily: return "flame.fill"
            case .rush: return "bolt.fill"
            case .pond: return "pawprint.fill"
            }
        }
    }

    /// Everything the badges are allowed to look at.
    ///
    /// Deliberately a flat handful of counters rather than the star map and the
    /// owned set: a badge that could ask an arbitrary question of the whole save
    /// is a badge nobody can reason about.
    struct Snapshot: Equatable {
        var pondsCleared = 0
        var stars = 0
        var goldenCleared = 0
        var dailyClears = 0
        var bestStreak = 0
        var bestRush = 0
        var friendsOwned = 0
        var decorOwned = 0
    }

    /// One badge.
    ///
    /// `descKey` is a format string taking `goal`, so the six families need
    /// eight sentences between them rather than twenty-four - the flavour is in
    /// `nameKey`, which is the part worth writing out.
    struct Badge: Identifiable {
        let id: String
        let family: Family
        let nameKey: String
        let descKey: String
        let goal: Int
        let coins: Int
        let progressOf: @Sendable (Snapshot) -> Int

        func progress(_ of: Snapshot) -> Int { min(max(progressOf(of), 0), goal) }
        func isEarned(_ of: Snapshot) -> Bool { progressOf(of) >= goal }
        /// How far along, 0...1, for the bar.
        func fraction(_ of: Snapshot) -> Double {
            goal <= 0 ? 1 : Double(progress(of)) / Double(goal)
        }
    }

    /// What each tier of a family pays.
    ///
    /// Rising, but not steeply: the fourth badge in a family is the work of the
    /// whole game, and it should feel like a milestone rather than like the only
    /// one that counted.
    private static let tiers = [15, 30, 60, 120]

    private static func badge(
        _ id: String, _ family: Family, _ nameKey: String, _ descKey: String,
        _ goal: Int, _ tier: Int, _ progressOf: @escaping @Sendable (Snapshot) -> Int
    ) -> Badge {
        Badge(id: id, family: family, nameKey: nameKey, descKey: descKey,
              goal: goal, coins: tiers[tier], progressOf: progressOf)
    }

    static let all: [Badge] = [
        // --- ponds cleared -------------------------------------------------
        badge("ponds_1", .ponds, "ach_ponds_1", "ach_desc_ponds", 10, 0) { $0.pondsCleared },
        badge("ponds_2", .ponds, "ach_ponds_2", "ach_desc_ponds", 60, 1) { $0.pondsCleared },
        badge("ponds_3", .ponds, "ach_ponds_3", "ach_desc_ponds", 200, 2) { $0.pondsCleared },
        badge("ponds_4", .ponds, "ach_ponds_4", "ach_desc_ponds", 450, 3) { $0.pondsCleared },

        // --- stars ---------------------------------------------------------
        badge("stars_1", .stars, "ach_stars_1", "ach_desc_stars", 60, 0) { $0.stars },
        badge("stars_2", .stars, "ach_stars_2", "ach_desc_stars", 300, 1) { $0.stars },
        badge("stars_3", .stars, "ach_stars_3", "ach_desc_stars", 800, 2) { $0.stars },
        badge("stars_4", .stars, "ach_stars_4", "ach_desc_stars", 1350, 3) { $0.stars },

        // --- golden ponds --------------------------------------------------
        badge("gold_1", .golden, "ach_gold_1", "ach_desc_golden", 1, 0) { $0.goldenCleared },
        badge("gold_2", .golden, "ach_gold_2", "ach_desc_golden", 8, 1) { $0.goldenCleared },
        badge("gold_3", .golden, "ach_gold_3", "ach_desc_golden", 18, 2) { $0.goldenCleared },
        badge("gold_4", .golden, "ach_gold_4", "ach_desc_golden", 30, 3) { $0.goldenCleared },

        // --- the daily pond ------------------------------------------------
        // Two counters, not one: turning up is its own achievement and so is
        // turning up every day, and a family that only measured the streak
        // would pay nothing at all to somebody who plays most days.
        badge("daily_1", .daily, "ach_daily_1", "ach_desc_daily", 1, 0) { $0.dailyClears },
        badge("daily_2", .daily, "ach_daily_2", "ach_desc_daily", 10, 1) { $0.dailyClears },
        badge("daily_3", .daily, "ach_daily_3", "ach_desc_streak", 7, 2) { $0.bestStreak },
        badge("daily_4", .daily, "ach_daily_4", "ach_desc_streak", 30, 3) { $0.bestStreak },

        // --- splash rush ---------------------------------------------------
        badge("rush_1", .rush, "ach_rush_1", "ach_desc_rush", 25, 0) { $0.bestRush },
        badge("rush_2", .rush, "ach_rush_2", "ach_desc_rush", 75, 1) { $0.bestRush },
        badge("rush_3", .rush, "ach_rush_3", "ach_desc_rush", 175, 2) { $0.bestRush },
        badge("rush_4", .rush, "ach_rush_4", "ach_desc_rush", 350, 3) { $0.bestRush },

        // --- the pond you keep ---------------------------------------------
        badge("pond_1", .pond, "ach_pond_1", "ach_desc_friends", 10, 0) { $0.friendsOwned },
        badge("pond_2", .pond, "ach_pond_2", "ach_desc_friends", 25, 1) { $0.friendsOwned },
        badge("pond_3", .pond, "ach_pond_3", "ach_desc_friends", 45, 2) { $0.friendsOwned },
        badge("pond_4", .pond, "ach_pond_4", "ach_desc_decor", 15, 3) { $0.decorOwned },
    ]

    /// Badges grouped the way the screen draws them, families in order.
    static let byFamily: [(Family, [Badge])] =
        Family.allCases.map { family in (family, all.filter { $0.family == family }) }

    /// Everything the shelf can ever pay.
    static let totalCoins: Int = all.reduce(0) { $0 + $1.coins }

    static func earnedCount(_ of: Snapshot) -> Int { all.filter { $0.isEarned(of) }.count }

    /// What the badges are worth right now - folded into `CoinBank.derived`.
    static func coins(_ of: Snapshot) -> Int {
        all.filter { $0.isEarned(of) }.reduce(0) { $0 + $1.coins }
    }

    /// The badge closest to being finished among those still open, or nil once
    /// they are all earned. The Home tile uses it to say what is next.
    static func nextUp(_ of: Snapshot) -> Badge? {
        all.filter { !$0.isEarned(of) }.max { $0.fraction(of) < $1.fraction(of) }
    }
}
