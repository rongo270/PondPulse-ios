//
//  Levels.swift
//  PondPulse
//
//  Assembles the 30 stages from the generated level maps (LevelMaps1/2/3.swift),
//  mirroring the Android Levels.kt play order exactly. Level ids don't follow
//  play order - they are stable save keys that stay with their maps.
//

import Foundation

/// How tough a stage's 15 levels are, as shown on its header chip. Raw-value
/// order is the ramp: easy sorts before very hard.
enum Difficulty: Int, Comparable {
    case easy, medium, hard, veryHard

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct Pack: Identifiable {
    let id: String
    let nameKey: String
    let descKey: String
    let levels: [LevelSpec]
    let difficulty: Difficulty
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
        return LevelParser.parse(id: id, rows: rows, par: par, maxSplashes: par + slack, tip: tip)
    }
}

/// Namespace the generated files extend with `parsN` and `packN` arrays.
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

    /// The 30 stages of the pond in play order - 20 free (levels 1–300), 10
    /// premium (levels 301–450). Levels open one after another as you solve
    /// them; there is no star-count gate. Same order as Android's Levels.kt.
    static let packs: [Pack] = [
        // Stages 1–10 · levels 1–150.
        Pack(id: "splashes", nameKey: "pack1_name", descKey: "pack1_desc", levels: build(LevelMaps.pack1), difficulty: .easy),
        Pack(id: "shallows", nameKey: "pack2_name", descKey: "pack2_desc", levels: build(LevelMaps.pack2), difficulty: .easy),
        Pack(id: "turtlebay", nameKey: "pack5_name", descKey: "pack5_desc", levels: build(LevelMaps.pack5), difficulty: .medium),
        Pack(id: "currents", nameKey: "pack4_name", descKey: "pack4_desc", levels: build(LevelMaps.pack4), difficulty: .medium),
        Pack(id: "whitewater", nameKey: "pack21_name", descKey: "pack21_desc", levels: build(LevelMaps.pack21), difficulty: .hard),
        Pack(id: "rainbowripples", nameKey: "pack22_name", descKey: "pack22_desc", levels: build(LevelMaps.pack22), difficulty: .easy),
        Pack(id: "deepwaters", nameKey: "pack6_name", descKey: "pack6_desc", levels: build(LevelMaps.pack6), difficulty: .medium),
        Pack(id: "paintbox", nameKey: "pack23_name", descKey: "pack23_desc", levels: build(LevelMaps.pack23), difficulty: .medium),
        Pack(id: "coves", nameKey: "pack3_name", descKey: "pack3_desc", levels: build(LevelMaps.pack3), difficulty: .hard),
        Pack(id: "deepend", nameKey: "pack10_name", descKey: "pack10_desc", levels: build(LevelMaps.pack10), difficulty: .veryHard),
        // Stages 11–20 · levels 151–300.
        Pack(id: "morningmist", nameKey: "pack11_name", descKey: "pack11_desc", levels: build(LevelMaps.pack11), difficulty: .easy),
        Pack(id: "twinstreams", nameKey: "pack12_name", descKey: "pack12_desc", levels: build(LevelMaps.pack12), difficulty: .medium),
        Pack(id: "sleepyshallows", nameKey: "pack24_name", descKey: "pack24_desc", levels: build(LevelMaps.pack24), difficulty: .easy),
        Pack(id: "pebblegarden", nameKey: "pack13_name", descKey: "pack13_desc", levels: build(LevelMaps.pack13), difficulty: .medium),
        Pack(id: "rapids", nameKey: "pack8_name", descKey: "pack8_desc", levels: build(LevelMaps.pack8), difficulty: .hard),
        Pack(id: "rainbow", nameKey: "pack7_name", descKey: "pack7_desc", levels: build(LevelMaps.pack7), difficulty: .hard),
        Pack(id: "thunderbasin", nameKey: "pack25_name", descKey: "pack25_desc", levels: build(LevelMaps.pack25), difficulty: .veryHard),
        Pack(id: "snappingshoals", nameKey: "pack15_name", descKey: "pack15_desc", levels: build(LevelMaps.pack15), difficulty: .medium),
        Pack(id: "nighttides", nameKey: "pack9_name", descKey: "pack9_desc", levels: build(LevelMaps.pack9), difficulty: .hard),
        Pack(id: "midnightsurge", nameKey: "pack19_name", descKey: "pack19_desc", levels: build(LevelMaps.pack19), difficulty: .veryHard),
        // Stages 21–30 · levels 301–450, behind the premium upgrade.
        Pack(id: "goldendawn", nameKey: "pack26_name", descKey: "pack26_desc", levels: build(LevelMaps.pack26), difficulty: .easy),
        Pack(id: "driftingmeadow", nameKey: "pack27_name", descKey: "pack27_desc", levels: build(LevelMaps.pack27), difficulty: .easy),
        Pack(id: "crosswinds", nameKey: "pack16_name", descKey: "pack16_desc", levels: build(LevelMaps.pack16), difficulty: .medium),
        Pack(id: "willowbend", nameKey: "pack28_name", descKey: "pack28_desc", levels: build(LevelMaps.pack28), difficulty: .medium),
        Pack(id: "prismfalls", nameKey: "pack17_name", descKey: "pack17_desc", levels: build(LevelMaps.pack17), difficulty: .hard),
        Pack(id: "maelstromdeep", nameKey: "pack29_name", descKey: "pack29_desc", levels: build(LevelMaps.pack29), difficulty: .veryHard),
        Pack(id: "paintedpools", nameKey: "pack14_name", descKey: "pack14_desc", levels: build(LevelMaps.pack14), difficulty: .medium),
        Pack(id: "heronharbor", nameKey: "pack30_name", descKey: "pack30_desc", levels: build(LevelMaps.pack30), difficulty: .medium),
        Pack(id: "bouldermaze", nameKey: "pack18_name", descKey: "pack18_desc", levels: build(LevelMaps.pack18), difficulty: .hard),
        Pack(id: "legendlagoon", nameKey: "pack20_name", descKey: "pack20_desc", levels: build(LevelMaps.pack20), difficulty: .veryHard),
    ]

    static let all: [LevelSpec] = packs.flatMap(\.levels)

    private static let indexById: [String: Int] =
        Dictionary(uniqueKeysWithValues: all.enumerated().map { ($1.id, $0) })

    static func byId(_ id: String) -> LevelSpec { all[indexById[id]!] }

    /// Zero-based position in `all`; -1 for unknown ids.
    static func indexOf(_ levelId: String) -> Int { indexById[levelId] ?? -1 }

    static func packOf(_ levelId: String) -> Pack {
        packs.first { pack in pack.levels.contains { $0.id == levelId } }!
    }

    static func next(_ levelId: String) -> LevelSpec? {
        let i = indexOf(levelId) + 1
        return i < all.count ? all[i] : nil
    }
}
