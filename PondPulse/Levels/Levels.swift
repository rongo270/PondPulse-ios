//
//  Levels.swift
//  PondPulse
//
//  Assembles the 30 stages from the generated level maps (LevelMaps1/2/3.swift)
//  and groups them into the nine packs the player browses, mirroring the Android
//  Levels.kt play order exactly. Level ids don't follow play order - they are
//  stable save keys that stay with their maps.
//

import Foundation

/// How tough a pack's ponds are, as shown on its chip. Raw-value order is the
/// ramp: easy sorts before very hard. Read off measured `bluff@2`, never off par
/// or board size - see `Levels.difficultyOf`.
enum Difficulty: Int, Comparable, Sendable {
    case easy, medium, hard, veryHard

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A rule a pack's ponds actually contain, shown as a chip on its card.
enum Mechanic: Int, CaseIterable, Sendable {
    case rocks, turtles, colors, currents
}

/// A golden pond inside a pack, with the point in the pack that opens it:
/// `opensAfter` is how many of the pack's ponds have to be starred first. A pack
/// absorbs three or four authored stages, and each of them keeps the golden pond
/// it used to close, so the rewards still land every fifteen-odd levels instead
/// of all at once at the end.
struct BonusPond: Identifiable, Sendable {
    let level: LevelSpec
    let opensAfter: Int

    var id: String { level.id }
}

/// One authored slice of a pack, and the unit the player actually browses: ten
/// to twenty ponds shown as a single page, closed by one golden pond. A stage is
/// small enough to read without scrolling, which is the whole reason the tier
/// exists - a 73-level pack laid out flat was two screens of thumb work.
struct PackStage: Identifiable, Sendable {
    let id: String
    /// 1-based position inside its pack, for the tab strip.
    let number: Int
    let levels: [LevelSpec]
    let difficulty: Difficulty
    /// What these ponds actually hold, measured from the maps, never declared.
    let mechanics: Set<Mechanic>
    /// The golden pond this stage closes. It sits outside `levels`, so it never
    /// shifts a level number and never blocks the way forward.
    let bonus: BonusPond
    /// Global number of this stage's first pond, so a tab can name its range.
    let firstLevelNumber: Int

    /// Global number of this stage's last pond.
    var lastLevelNumber: Int { firstLevelNumber + levels.count - 1 }
}

/// A stretch of the pond as the player browses it: a number, a span of levels
/// and however many ponds it was given. Packs are cut out of `Levels.all` and
/// vary in length; the fixed 15-level unit the difficulty ladder is built on is
/// a stage, which is a separate thing on purpose.
struct Pack: Identifiable, Sendable {
    let id: String
    /// 1-based position in `Levels.packs` - the pack's whole name is this.
    let number: Int
    let levels: [LevelSpec]
    /// The pages this pack is read in, in play order - three or four of them,
    /// tiling `levels` exactly. Only one is on screen at a time.
    let stages: [PackStage]
    let difficulty: Difficulty
    /// What these ponds actually hold, measured from the maps, never declared.
    let mechanics: Set<Mechanic>
    /// Global number of this pack's first pond, so cards can name their range.
    let firstLevelNumber: Int

    /// The golden ponds inside this pack, in play order - one per stage.
    var bonuses: [BonusPond] { stages.map(\.bonus) }

    /// Global number of this pack's last pond.
    var lastLevelNumber: Int { firstLevelNumber + levels.count - 1 }
}

/// A raw hand-drawn level before par is looked up (same shape as Android's Draft).
struct LevelDraft {
    let id: String
    let slack: Int
    let rows: [String]
    let tip: String?

    init(_ id: String, _ slack: Int, _ rows: [String], tip: String? = nil) {
        self.id = id
        self.slack = slack
        self.rows = rows
        self.tip = tip
    }

    func build(pars: [String: Int]) -> LevelSpec {
        guard let par = pars[id] else { fatalError("no par recorded for level \(id)") }
        return LevelParser.parse(
            id: id, rows: rows, par: par,
            maxSplashes: LevelParser.budget(par, slack), tip: tip
        )
    }
}

/// A golden pond before par is looked up. They all share one generous slack.
struct BonusDraft {
    let id: String
    let rows: [String]

    init(_ id: String, _ rows: [String]) {
        self.id = id
        self.rows = rows
    }

    func build() -> LevelSpec {
        guard let par = LevelMaps.bonusPars[id] else {
            fatalError("no par recorded for bonus pond \(id)")
        }
        return LevelParser.parse(
            id: id, rows: rows, par: par,
            maxSplashes: LevelParser.budget(par, LevelMaps.bonusSlack), isBonus: true
        )
    }
}

/// Namespace the generated files extend with `parsN`, `packN`, `toughness`,
/// `bonus` and `bonusPars`.
enum LevelMaps {
    /// Solver-proven optimal splash counts, copied from Android where they are
    /// verified by LevelsTest / LevelDoctorTest.
    static let pars: [String: Int] = pars1
        .merging(pars2) { a, _ in a }
        .merging(pars3) { a, _ in a }
}

enum Levels {

    private static func build(_ drafts: [LevelDraft]) -> [LevelSpec] {
        drafts.map { $0.build(pars: LevelMaps.pars) }
    }

    /// Measured `bluff@2` for a pond, or nil if it has never been measured.
    static func toughnessOf(_ levelId: String) -> Double? { LevelMaps.toughness[levelId] }

    /// Play order inside one stage: tips first, then by par, with measured
    /// toughness breaking ties so the sharpest pond of a given length is always
    /// the last one you meet. A stage with no measurements keeps plain par order
    /// rather than inventing one.
    private static func ramped(_ levels: [LevelSpec]) -> [LevelSpec] {
        let measured = levels.allSatisfy { LevelMaps.toughness[$0.id] != nil }
        return levels.enumerated().sorted { a, b in
            let (ia, x) = a, (ib, y) = b
            // `tip == nil` sorts after a tip level, matching Kotlin's compareBy
            // over the boolean.
            if (x.tip == nil) != (y.tip == nil) { return y.tip == nil }
            if x.par != y.par { return x.par < y.par }
            if measured {
                let tx = LevelMaps.toughness[x.id]!, ty = LevelMaps.toughness[y.id]!
                if tx != ty { return -tx < -ty }
            }
            // Kotlin's sortedWith is stable; keep the original order on full ties.
            return ia < ib
        }.map(\.element)
    }

    /// The 30 stages in play order - 20 free (levels 1-300), 10 premium (levels
    /// 301-450). The order is a single unbroken ramp on measured `bluff@2`.
    /// Level ids don't follow play order: they are stable save keys that stay
    /// with their maps.
    private static let stages: [[LevelSpec]] = [
        // Stages 1-4 · the teaching ponds: one new mechanic each, all easy.
        ramped(build(LevelMaps.pack1)),
        ramped(build(LevelMaps.pack2)),
        ramped(build(LevelMaps.pack22)),
        ramped(build(LevelMaps.pack4)),
        // Stages 5-8 · easy practice, no new rules.
        ramped(build(LevelMaps.pack24)),
        ramped(build(LevelMaps.pack27)),
        ramped(build(LevelMaps.pack26)),
        ramped(build(LevelMaps.pack11)),
        // Stages 9-17 · medium.
        ramped(build(LevelMaps.pack5)),
        ramped(build(LevelMaps.pack15)),
        ramped(build(LevelMaps.pack12)),
        ramped(build(LevelMaps.pack28)),
        ramped(build(LevelMaps.pack21)),
        ramped(build(LevelMaps.pack13)),
        ramped(build(LevelMaps.pack30)),
        ramped(build(LevelMaps.pack6)),
        ramped(build(LevelMaps.pack23)),
        // Stages 18-20 · hard, still inside the free 300.
        ramped(build(LevelMaps.pack7)),
        ramped(build(LevelMaps.pack16)),
        ramped(build(LevelMaps.pack14)),
        // Stages 21-30 · levels 301-450, behind the premium upgrade.
        ramped(build(LevelMaps.pack8)),
        ramped(build(LevelMaps.pack17)),
        ramped(build(LevelMaps.pack3)),
        ramped(build(LevelMaps.pack9)),
        ramped(build(LevelMaps.pack18)),
        ramped(build(LevelMaps.pack25)),
        ramped(build(LevelMaps.pack20)),
        ramped(build(LevelMaps.pack29)),
        ramped(build(LevelMaps.pack10)),
        ramped(build(LevelMaps.pack19)),
    ]

    /// The numbered levels, in play order. Bonus ponds are deliberately absent.
    static let all: [LevelSpec] = stages.flatMap { $0 }

    /// How the 30 authored slices of content are grouped into the nine packs the
    /// player browses: one row per pack, holding the lengths of the three or four
    /// slices it absorbs. Splitting the row from its total is what keeps the
    /// golden ponds where they were - each slice still ends in one, so a pack of
    /// four hands out four rewards on the way through rather than one at the end.
    ///
    /// Three rules the numbers have to keep:
    ///  - they sum to 450, so every pond belongs to exactly one pack;
    ///  - no pack's golden ponds use a mechanic the pack has not reached yet;
    ///  - a pack boundary falls on level 300, where the premium upgrade starts.
    private static let packSlices: [[Int]] = [
        // Free · levels 1-300.
        [15, 15, 15],     // 1 · levels   1- 45
        [12, 12, 13],     // 2 · levels  46- 82
        [13, 14, 10],     // 3 · levels  83-119
        [15, 15, 16],     // 4 · levels 120-165
        [16, 12, 17, 17], // 5 · levels 166-227
        [18, 18, 18, 19], // 6 · levels 228-300
        // Premium · levels 301-450. The first premium pack is short on purpose:
        // a quick win the moment the upgrade lands.
        [12, 13, 14],     // 7 · levels 301-339
        [15, 16, 17],     // 8 · levels 340-387
        [18, 12, 13, 20], // 9 · levels 388-450
    ]

    /// The packs the player browses, cut out of `all` in play order. A pack has
    /// no name of its own beyond its number: the ponds are the content.
    static let packs: [Pack] = {
        let bonusPonds = LevelMaps.bonus.map { $0.build() }
        var out: [Pack] = []
        var start = 0
        var slice = 0
        for (index, sizes) in packSlices.enumerated() {
            let size = sizes.reduce(0, +)
            let levels = Array(all[start..<(start + size)])
            // Each slice becomes one browsable stage, keeping the golden pond
            // that used to close it - opened by starring the ponds up to that
            // point in the pack, so `BonusPond.opensAfter` stays pack-relative.
            var reached = 0
            var stages: [PackStage] = []
            for (position, length) in sizes.enumerated() {
                let slices = Array(levels[reached..<(reached + length)])
                let firstNumber = start + reached + 1
                reached += length
                stages.append(PackStage(
                    id: "pack\(index + 1)s\(position + 1)",
                    number: position + 1,
                    levels: slices,
                    difficulty: difficultyOf(slices),
                    mechanics: mechanicsOf(slices),
                    bonus: BonusPond(level: bonusPonds[slice], opensAfter: reached),
                    firstLevelNumber: firstNumber
                ))
                slice += 1
            }
            start += size
            out.append(Pack(
                id: "pack\(index + 1)",
                number: index + 1,
                levels: levels,
                stages: stages,
                difficulty: difficultyOf(levels),
                mechanics: mechanicsOf(levels),
                firstLevelNumber: start - size + 1
            ))
        }
        return out
    }()

    /// Difficulty from the median measured toughness, never from par or size.
    private static func difficultyOf(_ levels: [LevelSpec]) -> Difficulty {
        let scores = levels.compactMap { LevelMaps.toughness[$0.id] }.sorted()
        guard !scores.isEmpty else { return .medium }
        switch scores[scores.count / 2] {
        case 0.18...1.0: return .easy
        case 0.06..<0.18: return .medium
        case 0.02..<0.06: return .hard
        default: return .veryHard
        }
    }

    /// What a player will actually meet in these ponds, for the pack's chips.
    private static func mechanicsOf(_ levels: [LevelSpec]) -> Set<Mechanic> {
        var out: Set<Mechanic> = []
        for level in levels {
            if level.terrain.contains(.rock) { out.insert(.rocks) }
            if level.floaters.contains(where: { $0.kind == .turtle }) { out.insert(.turtles) }
            if level.floaters.contains(where: { $0.color != nil }) { out.insert(.colors) }
            if !level.currents.isEmpty { out.insert(.currents) }
        }
        return out
    }

    /// The golden ponds, in play order - one per stage, three or four per pack.
    static let bonusPonds: [LevelSpec] = packs.flatMap { $0.bonuses.map(\.level) }

    private static let indexById: [String: Int] =
        Dictionary(uniqueKeysWithValues: all.enumerated().map { ($1.id, $0) })

    private static let byIdMap: [String: LevelSpec] =
        Dictionary(uniqueKeysWithValues: (all + bonusPonds).map { ($0.id, $0) })

    static func byId(_ id: String) -> LevelSpec { byIdMap[id]! }

    /// Zero-based position in `all`; -1 for unknown ids and every bonus pond.
    static func indexOf(_ levelId: String) -> Int { indexById[levelId] ?? -1 }

    static func packOf(_ levelId: String) -> Pack {
        packs.first { pack in
            pack.levels.contains { $0.id == levelId }
                || pack.bonuses.contains { $0.level.id == levelId }
        }!
    }

    static func packById(_ packId: String) -> Pack { packs.first { $0.id == packId }! }

    /// What "Next" leads to. From a numbered level that is simply the level after
    /// it; from a golden pond it is the pond the player was about to reach when
    /// the golden one opened - the one right after the ponds that unlocked it.
    static func next(_ levelId: String) -> LevelSpec? {
        if isBonus(levelId) {
            let pack = packOf(levelId)
            let bonus = pack.bonuses.first { $0.level.id == levelId }!
            if bonus.opensAfter < pack.levels.count { return pack.levels[bonus.opensAfter] }
            let nextPack = pack.number // packs are 1-based, so this is the next index
            return nextPack < packs.count ? packs[nextPack].levels.first : nil
        }
        let i = indexOf(levelId) + 1
        return i > 0 && i < all.count ? all[i] : nil
    }

    static func isBonus(_ levelId: String) -> Bool {
        packs.contains { pack in pack.bonuses.contains { $0.level.id == levelId } }
    }
}
