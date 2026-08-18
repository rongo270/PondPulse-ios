//
//  LevelParser.swift
//  PondPulse
//
//  Levels are drawn as ASCII maps (identical to Android's LevelParser.kt):
//
//  `~` or space  bank (outside the pond)      `#`  rock
//  `.`  open water                            `O`  lily pad (any duck)
//  `r g b`  colored pads                      `D`  yellow duckling
//  `R G B`  colored ducklings                 `d`  duckling starting on a pad
//  `T`  turtle                                `t`  turtle squatting on a pad
//  `^ v < >`  current tiles
//

import Foundation

nonisolated enum LevelParser {

    /// How many splashes a level hands out: par plus the map's `slack`, with a
    /// floor of three.
    ///
    /// Numbered levels all use exactly three, which lines the budget up with the
    /// star bands - three stars at par, two for a splash or two over, one for
    /// scraping home on the last drop, and then you are out of water. A pond you
    /// can flail at for nine extra splashes isn't asking you anything, and since
    /// a docked duckling now stays docked, a roomy budget let you feel your way
    /// to the answer one splash at a time instead of reading the pond. Bonus
    /// ponds pass a much bigger slack on purpose - they are a reward, not a test.
    static func budget(_ par: Int, _ slack: Int) -> Int { par + max(slack, 3) }

    static func parse(
        id: String,
        rows: [String],
        par: Int,
        maxSplashes: Int,
        tip: String? = nil,
        isBonus: Bool = false
    ) -> LevelSpec {
        let grid = rows.map(Array.init)
        let cols = grid.map(\.count).max() ?? 0
        var terrain = [Terrain](repeating: .bank, count: rows.count * cols)
        var pads: [Pos: DuckColor?] = [:]
        var currents: [Pos: Dir] = [:]
        var floaters: [Floater] = []

        func addFloater(_ kind: FloaterKind, _ color: DuckColor?, _ pos: Pos) {
            floaters.append(Floater(id: floaters.count, kind: kind, color: color, pos: pos))
        }

        for y in grid.indices {
            for x in grid[y].indices {
                let pos = Pos(x: x, y: y)
                let c = grid[y][x]
                if c == "~" || c == " " { continue }
                terrain[y * cols + x] = c == "#" ? .rock : .water
                switch c {
                case ".", "#": break
                case "O": pads[pos] = DuckColor?.none
                case "r": pads[pos] = .red
                case "g": pads[pos] = .green
                case "b": pads[pos] = .blue
                case "D": addFloater(.duck, nil, pos)
                case "R": addFloater(.duck, .red, pos)
                case "G": addFloater(.duck, .green, pos)
                case "B": addFloater(.duck, .blue, pos)
                case "d": pads[pos] = DuckColor?.none; addFloater(.duck, nil, pos)
                case "T": addFloater(.turtle, nil, pos)
                case "t": pads[pos] = DuckColor?.none; addFloater(.turtle, nil, pos)
                case "^": currents[pos] = .up
                case "v": currents[pos] = .down
                case "<": currents[pos] = .left
                case ">": currents[pos] = .right
                default: fatalError("level \(id): unknown tile '\(c)' at \(x),\(y)")
                }
            }
        }

        return LevelSpec(
            id: id,
            cols: cols,
            rows: rows.count,
            terrain: terrain,
            pads: pads,
            currents: currents,
            floaters: floaters,
            par: par,
            maxSplashes: maxSplashes,
            tip: tip,
            isBonus: isBonus
        )
    }
}
