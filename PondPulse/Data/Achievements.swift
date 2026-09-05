//
//  Achievements.swift
//  PondPulse
//
//  The badge shelf: nine ladders, seventy-one rungs. A rung is a number and a
//  payout - clear 150 ponds, earn 800 stars - and a family is that ladder in
//  order, so there is exactly one thing to be working on at a time.
//
//  ### Why ladders rather than badges
//
//  It used to be six families of four, which meant four payouts spread over 450
//  ponds: the second rung of the campaign ladder wanted sixty ponds and the
//  third wanted two hundred, and between them lay a hundred and forty ponds
//  that paid nothing but their own five coins. The shelf was a list of things
//  that were a long way off.
//
//  The rungs are close together now and they get bigger as they go. The same
//  coins arrive, more of them arrive early, and the screen has one live bar per
//  family that moves every few ponds instead of four bars that move twice a
//  month.
//
//  ### They are derived, exactly like every other coin
//
//  Nothing here is claimed, banked or stored. Every rung is a question asked of
//  a `Snapshot` of progress, and every one of those numbers can only ever go up:
//  ponds cleared, stars earned, golden ponds finished, dailies, the best streak,
//  the best Splash Rush score, the four mini-game bests, how many friends and
//  decorations are owned. A rung is earned when its number reaches its goal, and
//  its coins fold into `CoinBank.derived` - recomputed from scratch on every
//  read, like the rest.
//
//  That is the whole reason there is no "Claim" button. A claim needs a claimed
//  set to write to, and a second stored ledger is exactly the thing the coin
//  economy was built to avoid: it can drift, it can be replayed, and it needs a
//  repair path. Recomputing cannot.
//
//  ### Why friends and decorations count
//
//  Two of the ladders read what the player *owns*, and owning things costs
//  coins, so a purchase can push a rung over its line and pay a little back.
//  That is a rebate, not a loop: a rung pays once, forever, and always less than
//  the item that crossed it cost. It is here because a collection game whose
//  badges ignore the collection is a badge shelf about something else. They are
//  also the two shortest and cheapest ladders on the shelf, for the same reason.
//

import Foundation

enum Achievements {

    /// One step of a ladder: what it wants, and what it pays.
    struct Rung: Identifiable, Hashable {
        let goal: Int
        let coins: Int
        var id: Int { goal }
    }

    /// The nine things a player can be getting better at.
    ///
    /// One number each, deliberately. The old Daily family measured clears on
    /// two of its rungs and the streak on the other two, which is fine as four
    /// separate badges and nonsense as a ladder - a bar cannot fill towards two
    /// different numbers - so turning up and turning up *every day* are two
    /// families now.
    enum Family: String, CaseIterable, Identifiable, Hashable {
        case ponds, stars, golden, daily, streak, rush, games, friends, decor

        var id: String { rawValue }

        var titleKey: String {
            switch self {
            case .ponds: return "ach_family_ponds"
            case .stars: return "ach_family_stars"
            case .golden: return "ach_family_golden"
            case .daily: return "ach_family_daily"
            case .streak: return "ach_family_streak"
            case .rush: return "ach_family_rush"
            case .games: return "ach_family_games"
            case .friends: return "ach_family_friends"
            case .decor: return "ach_family_decor"
            }
        }

        /// What one rung reads as - `goalKey` filled in with its goal, except on
        /// the two ladders that start at one, where a count-of-one sentence
        /// would say "Clear 1 golden ponds" on the first row every new player
        /// ever sees. Their first rung has a sentence of its own instead, which
        /// is both correct and better than a plural rule would be: "your first
        /// golden pond" is what that rung is actually about.
        func goalText(_ strings: Strings, _ goal: Int) -> String {
            if goal == 1, self == .golden || self == .daily {
                return strings[self == .golden ? "ach_desc_golden_one" : "ach_desc_daily_one"]
            }
            return strings[goalKey, goal]
        }

        /// A format string taking one rung's goal - "Clear %1$d ponds". The
        /// rungs have no names of their own: at four a family they were worth
        /// writing, and at eleven a name on every step would bury the number
        /// that is the actual point of the row.
        var goalKey: String {
            switch self {
            case .ponds: return "ach_desc_ponds"
            case .stars: return "ach_desc_stars"
            case .golden: return "ach_desc_golden"
            case .daily: return "ach_desc_daily"
            case .streak: return "ach_desc_streak"
            case .rush: return "ach_desc_rush"
            case .games: return "ach_desc_games_score"
            case .friends: return "ach_desc_friends"
            case .decor: return "ach_desc_decor"
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
            case .daily: return "sun.max.fill"
            case .streak: return "flame.fill"
            case .rush: return "bolt.fill"
            case .games: return "gamecontroller.fill"
            case .friends: return "pawprint.fill"
            case .decor: return "leaf.fill"
            }
        }

        /// The number this family watches.
        func progress(_ of: Snapshot) -> Int {
            switch self {
            case .ponds: return of.pondsCleared
            case .stars: return of.stars
            case .golden: return of.goldenCleared
            case .daily: return of.dailyClears
            case .streak: return of.bestStreak
            case .rush: return of.bestRush
            case .games: return of.gamesTotal
            case .friends: return of.friendsOwned
            case .decor: return of.decorOwned
            }
        }

        /// The ladder itself.
        ///
        /// Goals climb faster than the payouts do, which is what stops the last
        /// rung of the campaign from being worth more than the shop: 450 ponds
        /// is forty-five times ten ponds and pays seven times as much.
        ///
        /// The nine ladders together are worth 7,300, and everything progress
        /// can ever pay - every pond three-starred, every golden pond, the
        /// streak and Splash Rush - is a fifth or so of a shop that runs to
        /// hundreds of thousands of coins. That is the point: the rest of the
        /// shop is bought with `Quests`, a couple of hundred coins a day, by
        /// turning up.
        /// The top of each ladder is deliberately reachable - 1350 stars is
        /// every pond three-starred, 84 days is `CoinBank.streakWeekCap`, 30 is
        /// every golden pond and every decoration - so no ladder ends on a rung
        /// that exists only to be unfinished.
        var rungs: [Rung] {
            switch self {
            case .ponds:
                return zip([10, 25, 50, 100, 150, 200, 250, 300, 350, 400, 450],
                           [50, 60, 70,  90, 110, 130, 160, 190, 220, 270, 350]).map(Rung.init)
            case .stars:
                return zip([30, 60, 100, 150, 200, 275, 350, 450, 600, 800, 1000, 1350],
                           [40, 50,  60,  70,  80, 100, 120, 140, 170, 210,  250,  310]).map(Rung.init)
            case .golden:
                return zip([ 1,  3,  6, 10,  14,  18,  22,  26,  30],
                           [50, 60, 70, 90, 110, 130, 160, 200, 250]).map(Rung.init)
            case .daily:
                return zip([ 1,  5, 15, 30,  60, 100, 150],
                           [40, 50, 60, 80, 110, 140, 190]).map(Rung.init)
            case .streak:
                return zip([ 3,  7, 14,  30,  60,  84],
                           [40, 50, 70, 100, 130, 180]).map(Rung.init)
            case .rush:
                return zip([25, 75, 150, 250, 350, 500],
                           [30, 40,  50,  70, 100, 130]).map(Rung.init)
            case .games:
                return zip([20, 45, 80, 130, 190, 260],
                           [30, 40, 50,  70, 100, 130]).map(Rung.init)
            case .friends:
                return zip([ 3,  6, 10, 15, 22,  30,  45],
                           [20, 30, 40, 60, 80, 100, 140]).map(Rung.init)
            case .decor:
                return zip([ 3,  6, 10, 15, 22,  30],
                           [20, 30, 40, 60, 80, 100]).map(Rung.init)
            }
        }
    }

    /// Everything the ladders are allowed to look at.
    ///
    /// Deliberately a flat handful of counters rather than the star map and the
    /// owned set: a rung that could ask an arbitrary question of the whole save
    /// is a rung nobody can reason about.
    struct Snapshot: Equatable {
        var pondsCleared = 0
        var stars = 0
        var goldenCleared = 0
        var dailyClears = 0
        var bestStreak = 0
        var bestRush = 0
        /// The four mini-game bests added together. One number rather than four
        /// because the games score in four different currencies - buds popped,
        /// ducklings home, rounds survived, hits - and a ladder on any one of
        /// them would be a ladder about whichever game hands out the biggest
        /// numbers.
        var gamesTotal = 0
        var friendsOwned = 0
        var decorOwned = 0
    }

    /// Where one family stands right now: everything both screens need, worked
    /// out once so the row and the ladder cannot disagree about it.
    struct Standing {
        let family: Family
        /// The number the family watches, as it stands.
        let value: Int
        let rungs: [Rung]
        /// How many rungs are behind you.
        let done: Int
        /// The one being worked on, or nil once the ladder is finished.
        let next: Rung?
        /// What this family has paid so far.
        let coins: Int

        var total: Int { rungs.count }
        var isComplete: Bool { next == nil }

        /// How far up the *current* rung, 0...1 - measured from the rung below
        /// it, not from zero.
        ///
        /// From zero, a bar on the campaign ladder would sit at 96% for the last
        /// fifty ponds and never visibly move again. From the rung below, every
        /// pond cleared is worth a fiftieth of the bar, which is the whole point
        /// of there being one bar per family instead of eleven.
        var fraction: Double {
            guard let next else { return 1 }
            let floor = done > 0 ? rungs[done - 1].goal : 0
            let span = next.goal - floor
            guard span > 0 else { return 1 }
            return min(max(Double(value - floor) / Double(span), 0), 1)
        }
    }

    static func standing(_ family: Family, _ of: Snapshot) -> Standing {
        let rungs = family.rungs
        let value = family.progress(of)
        let done = rungs.prefix { value >= $0.goal }.count
        return Standing(
            family: family,
            value: value,
            rungs: rungs,
            done: done,
            next: done < rungs.count ? rungs[done] : nil,
            coins: rungs.prefix(done).reduce(0) { $0 + $1.coins }
        )
    }

    /// Every rung on the shelf, for the "n of m" line.
    static let totalRungs: Int = Family.allCases.reduce(0) { $0 + $1.rungs.count }

    /// Everything the shelf can ever pay.
    static let totalCoins: Int = Family.allCases.reduce(0) { total, family in
        total + family.rungs.reduce(0) { $0 + $1.coins }
    }

    static func earnedCount(_ of: Snapshot) -> Int {
        Family.allCases.reduce(0) { $0 + standing($1, of).done }
    }

    /// What the ladders are worth right now - folded into `CoinBank.derived`.
    static func coins(_ of: Snapshot) -> Int {
        Family.allCases.reduce(0) { $0 + standing($1, of).coins }
    }

    /// The family closest to its next rung, or nil once every ladder is
    /// finished. The Home tile and the shelf's own header use it to say what is
    /// next, so the screen opens on something to aim at.
    static func nextUp(_ of: Snapshot) -> Standing? {
        Family.allCases
            .map { standing($0, of) }
            .filter { !$0.isComplete }
            .max { $0.fraction < $1.fraction }
    }
}
