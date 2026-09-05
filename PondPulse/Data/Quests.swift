//
//  Quests.swift
//  PondPulse
//
//  Three things to do today, drawn fresh every morning.
//
//  ### Why the shelf needed a second half
//
//  Everything else the game pays runs out. There are 450 ponds, 30 golden ones,
//  70 ladder rungs, and once they are behind you the shop stops moving - which
//  is a problem, because the shop is the reason to keep playing and it is
//  deliberately far bigger than anything progress alone can buy. Progress tops
//  out at about a fifth of it.
//
//  The other four fifths are bought here, a couple of hundred coins at a time,
//  by turning up. A day is worth roughly a thousandth of the shop: nothing on
//  its own, and most of the catalogue over a year of mornings.
//
//  ### The board is the same for everybody
//
//  A day's three quests are drawn from the date and nothing else, so two players
//  on the same date get the same board and nobody can shake the app until it
//  offers something easier. The draw takes one easy, one middling and one hard
//  quest of three different kinds, so a day is always finishable in a sitting
//  and never three marathons at once.
//
//  ### Counters, not events
//
//  A quest asks a question of a handful of counters that reset at midnight -
//  ponds cleared today, points scored today - rather than listening for events.
//  Same reason the ladders read a `Snapshot`: a rule that can only be checked at
//  the exact moment something happens is a rule that silently misses whenever
//  the app was killed between the doing and the checking.
//
//  The coins, unlike everything else in the economy, *are* banked - a day cannot
//  be recomputed once it is over - so a finished quest is paid once and written
//  down in `claimed`, which is scoped to the day and thrown away with it.
//

import Foundation

enum Quests {

    /// How many are on the board at once.
    ///
    /// Three is enough that a board rarely reads as "none of these are for me",
    /// and few enough that finishing all three is a normal evening rather than
    /// an ambition.
    static let perDay = 3

    /// On top of the three, for clearing the whole board.
    static let allDoneBonus = 70

    /// What one quest pays, by how much work it is.
    ///
    /// Halved on 2026-09-04, along with every ladder rung, and rounded to a
    /// round ten. A day used to be worth 500 coins, which meant a fortnight of
    /// mornings bought the dearest thing on the shelf and the campaign was
    /// pocket change beside it; a day is 240 now. The shop is deliberately
    /// bigger than progress alone can buy, and it stops being a shop the moment
    /// turning up covers it.
    enum Tier: Int, CaseIterable {
        case easy = 0, middling = 1, hard = 2

        var coins: Int {
            switch self {
            case .easy: return 30
            case .middling: return 50
            case .hard: return 90
            }
        }
    }

    /// One of today's counters. Raw values are the storage keys' suffixes.
    ///
    /// `CaseIterable` so that "every counter" - clearing yesterday's board, or
    /// wiping one on a reset - is the list itself rather than a copy of it kept
    /// in step by hand.
    enum Counter: String, CaseIterable {
        case ponds, stars, three, daily, golden
        case rushBest = "rush_best", rushRuns = "rush_runs"
        case miniPoints = "mini_points", miniRuns = "mini_runs"
        case splashes, pondTaps = "pond_taps"
    }

    /// Everything today's board is allowed to look at.
    struct Counters: Equatable {
        var ponds = 0
        var stars = 0
        var three = 0
        var daily = 0
        var golden = 0
        /// The best single Splash Rush score today, not the total: "score 70 in
        /// one run" is a different ask from "score 70 across four".
        var rushBest = 0
        var rushRuns = 0
        var miniPoints = 0
        var miniRuns = 0
        var splashes = 0
        var pondTaps = 0
        /// Which of the pond's games have been played today, for the one quest
        /// that asks for variety rather than volume.
        var miniGames: Set<String> = []

        subscript(_ counter: Counter) -> Int {
            switch counter {
            case .ponds: return ponds
            case .stars: return stars
            case .three: return three
            case .daily: return daily
            case .golden: return golden
            case .rushBest: return rushBest
            case .rushRuns: return rushRuns
            case .miniPoints: return miniPoints
            case .miniRuns: return miniRuns
            case .splashes: return splashes
            case .pondTaps: return pondTaps
            }
        }
    }

    /// The twelve things a quest can ask for.
    ///
    /// Each carries three goals, one per tier, so a kind can turn up as a gentle
    /// morning job or as the evening's hard one. The two that cannot be scaled -
    /// a Daily Pond is one pond and a golden pond is one golden pond - repeat
    /// their goal and simply pay more when they are drawn as the hard slot,
    /// which is honest: on a day you have not touched the daily yet, it *is* the
    /// hard one.
    ///
    /// The raw values are the storage ids, and they are written out rather than
    /// left to the case names: a camel-cased `rushScore` builds the string key
    /// `quest_rushScore`, which does not exist - Android's is `quest_rush_score`
    /// - so half of every day's board drew its own key instead of a sentence.
    /// They are also what a paid quest is written down under, so they match
    /// Android's `Kind.id` character for character.
    enum Kind: String, CaseIterable, Identifiable {
        case ponds, stars, three, daily, golden
        case rushScore = "rush_score"
        case rushRuns = "rush_runs"
        case miniPoints = "mini_points"
        case miniRuns = "mini_runs"
        case miniVariety = "mini_variety"
        case splashes
        case pondTaps = "pond_taps"

        var id: String { rawValue }

        /// A format string taking the goal, except on the two that do not
        /// scale, whose sentences name the one thing they want.
        var titleKey: String { "quest_\(rawValue)" }

        /// True when `titleKey` takes the goal as an argument. A Daily Pond is
        /// one pond and a golden pond is one golden pond, so those two sentences
        /// have no number in them to fill.
        var takesCount: Bool { self != .daily && self != .golden }

        var symbol: String {
            switch self {
            case .ponds: return "drop.fill"
            case .stars: return "star.fill"
            case .three: return "sparkles"
            case .daily: return "sun.max.fill"
            case .golden: return "crown.fill"
            case .rushScore, .rushRuns: return "bolt.fill"
            case .miniPoints, .miniRuns, .miniVariety: return "gamecontroller.fill"
            case .splashes: return "circle.circle"
            case .pondTaps: return "hand.tap.fill"
            }
        }

        /// The counter this kind reads, and how a goal is measured against it.
        var counter: Counter {
            switch self {
            case .ponds: return .ponds
            case .stars: return .stars
            case .three: return .three
            case .daily: return .daily
            case .golden: return .golden
            case .rushScore: return .rushBest
            case .rushRuns: return .rushRuns
            case .miniPoints: return .miniPoints
            case .miniRuns, .miniVariety: return .miniRuns
            case .splashes: return .splashes
            case .pondTaps: return .pondTaps
            }
        }

        var goals: [Int] {
            switch self {
            case .ponds: return [3, 5, 8]
            case .stars: return [6, 10, 16]
            case .three: return [2, 3, 5]
            case .daily: return [1, 1, 1]
            case .golden: return [1, 1, 1]
            case .rushScore: return [40, 70, 110]
            case .rushRuns: return [2, 3, 4]
            case .miniPoints: return [30, 60, 100]
            case .miniRuns: return [2, 3, 5]
            case .miniVariety: return [2, 3, 4]
            case .splashes: return [40, 80, 140]
            case .pondTaps: return [10, 20, 35]
            }
        }

        func progress(_ of: Counters) -> Int {
            // The one kind that counts a set rather than a number.
            self == .miniVariety ? of.miniGames.count : of[counter]
        }
    }

    /// One quest on today's board.
    struct Quest: Identifiable, Hashable {
        let kind: Kind
        let goal: Int
        let coins: Int

        /// Stable across a day and unique on the board, so the paid set can name
        /// it. The date is not in it: the set is thrown away with the day.
        var id: String { "\(kind.rawValue)-\(goal)" }

        func progress(_ of: Counters) -> Int { min(kind.progress(of), goal) }
        func isDone(_ of: Counters) -> Bool { kind.progress(of) >= goal }
        func fraction(_ of: Counters) -> Double {
            goal <= 0 ? 1 : Double(progress(of)) / Double(goal)
        }
    }

    /// Today's board.
    ///
    /// Drawn from the date alone, one quest per tier, three different kinds -
    /// and the same three for everybody, which is what makes it a *daily* rather
    /// than a slot machine you can re-roll by force-quitting.
    static func board(day: Int) -> [Quest] {
        var pool = Kind.allCases
        var out: [Quest] = []
        for (slot, tier) in Tier.allCases.enumerated() {
            guard !pool.isEmpty else { break }
            let pick = pool.remove(at: scramble(day, slot) % pool.count)
            out.append(Quest(
                kind: pick,
                goal: pick.goals[min(tier.rawValue, pick.goals.count - 1)],
                coins: tier.coins
            ))
        }
        return out
    }

    /// What a whole finished board is worth, for the day's header line.
    static func dayValue(day: Int) -> Int {
        board(day: day).reduce(allDoneBonus) { $0 + $1.coins }
    }

    /// A cheap, stable integer hash: the same date always draws the same board,
    /// on every device, with no stored seed to go missing.
    private static func scramble(_ day: Int, _ salt: Int) -> Int {
        var v = UInt64(bitPattern: Int64(day &* 0x1000_0001 &+ salt &* 0x9E37))
        v = v &+ 0x9E37_79B9_7F4A_7C15
        v = (v ^ (v >> 30)) &* 0xBF58_476D_1CE4_E5B9
        v = (v ^ (v >> 27)) &* 0x94D0_49BB_1331_11EB
        v = v ^ (v >> 31)
        return Int(v & 0x7FFF_FFFF)
    }
}
