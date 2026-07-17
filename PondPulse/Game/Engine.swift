//
//  Engine.swift
//  PondPulse
//
//  The pure rules of PondPulse, ported 1:1 from the Android engine
//  (engine/Model.kt, Engine.kt, Solver.kt). A splash at an empty water cell
//  pushes every floater one cell directly away from the splash
//  (8-directional, by the sign of the offset). Floaters farther from the
//  splash move first, so rafts drift apart cleanly. A push is blocked by
//  banks, rocks and other floaters. After the pushes, every floater standing
//  on a current tile slides one cell along the arrow.
//
//  Everything here is `nonisolated` so the solver can run off the main actor.
//

import Foundation

/// A cell of the pond grid.
nonisolated struct Pos: Hashable, Sendable {
    var x: Int
    var y: Int
}

/// What the ground is at a cell. Floaters may only ever occupy `.water`.
nonisolated enum Terrain: Sendable { case water, rock, bank }

/// Colors a duckling (and its lily pad) can have.
nonisolated enum DuckColor: Int, CaseIterable, Sendable { case red, green, blue }

nonisolated enum FloaterKind: Int, Sendable { case duck, turtle }

/// Anything that floats and is pushed by ripples. Ducks with `color == nil` are
/// plain yellow ducklings and may dock on any pad; colored ducks need a matching
/// pad. Turtles never dock - they are drifting obstacles.
nonisolated struct Floater: Hashable, Sendable {
    let id: Int
    let kind: FloaterKind
    var color: DuckColor?
    var pos: Pos
}

/// Direction a current tile carries floaters after every splash.
nonisolated enum Dir: Sendable {
    case up, down, left, right

    var dx: Int {
        switch self {
        case .left: -1
        case .right: 1
        default: 0
        }
    }

    var dy: Int {
        switch self {
        case .up: -1
        case .down: 1
        default: 0
        }
    }
}

/// A fully parsed level. Pads with a `nil` color accept any duckling; colored
/// pads accept only ducklings of the same color. `par` is the solver-proven
/// optimum and `maxSplashes` the hard limit (par plus some slack).
nonisolated struct LevelSpec: Sendable {
    let id: String
    let cols: Int
    let rows: Int
    let terrain: [Terrain]
    let pads: [Pos: DuckColor?]
    let currents: [Pos: Dir]
    let floaters: [Floater]
    let par: Int
    let maxSplashes: Int
    let tip: String?

    func terrainAt(_ pos: Pos) -> Terrain {
        guard (0..<cols).contains(pos.x), (0..<rows).contains(pos.y) else { return .bank }
        return terrain[pos.y * cols + pos.x]
    }

    /// Whether a duck of `color` counts as docked on the pad at `pos` (if any).
    func padAccepts(_ pos: Pos, _ color: DuckColor?) -> Bool {
        guard let padColor = pads[pos] else { return false }
        return padColor == nil || padColor == color
    }

    var duckCount: Int { floaters.count { $0.kind == .duck } }
}

nonisolated struct GameState: Sendable {
    let spec: LevelSpec
    var floaters: [Floater]
    var splashesUsed: Int

    var splashesLeft: Int { spec.maxSplashes - splashesUsed }

    var ducksHome: Int {
        floaters.count { $0.kind == .duck && spec.padAccepts($0.pos, $0.color) }
    }

    var won: Bool { ducksHome == spec.duckCount }

    /// Out of splashes with ducklings still adrift.
    var stuck: Bool { !won && splashesLeft <= 0 }
}

/// One floater's movement during a splash, kept for animation. from == to means blocked.
nonisolated struct MoveTrace: Sendable {
    let id: Int
    let from: Pos
    let to: Pos
}

/// Result of one splash: the new state, the ripple pushes, and the current
/// slides (applied after the pushes), in the order they were resolved.
nonisolated struct SplashOutcome: Sendable {
    let state: GameState
    let pushes: [MoveTrace]
    let slides: [MoveTrace]
}

nonisolated enum Engine {

    static func initial(_ spec: LevelSpec) -> GameState {
        GameState(spec: spec, floaters: spec.floaters, splashesUsed: 0)
    }

    /// Splashes are only allowed on open water - not on banks, rocks or floaters.
    static func canSplash(_ state: GameState, at: Pos) -> Bool {
        !state.won && !state.stuck &&
            state.spec.terrainAt(at) == .water &&
            !state.floaters.contains { $0.pos == at }
    }

    static func splash(_ state: GameState, at: Pos) -> SplashOutcome {
        precondition(canSplash(state, at: at), "illegal splash at \(at)")
        let spec = state.spec

        var occupied = [Pos: Floater](uniqueKeysWithValues: state.floaters.map { ($0.pos, $0) })
        var moved = [Int: Floater](uniqueKeysWithValues: state.floaters.map { ($0.id, $0) })

        // Ripple phase: farthest floaters move first (ties broken by row, then
        // column so the outcome never depends on list order).
        let pushOrder = state.floaters.sorted { a, b in
            let da = chebyshev(a.pos, at), db = chebyshev(b.pos, at)
            if da != db { return da > db }
            if a.pos.y != b.pos.y { return a.pos.y < b.pos.y }
            return a.pos.x < b.pos.x
        }
        var pushes: [MoveTrace] = []
        for floater in pushOrder {
            let current = moved[floater.id]!
            let dir = Pos(
                x: (current.pos.x - at.x).signum(),
                y: (current.pos.y - at.y).signum()
            )
            let target = Pos(x: current.pos.x + dir.x, y: current.pos.y + dir.y)
            let free = spec.terrainAt(target) == .water && occupied[target] == nil
            pushes.append(MoveTrace(id: floater.id, from: current.pos, to: free ? target : current.pos))
            if free {
                occupied.removeValue(forKey: current.pos)
                var next = current
                next.pos = target
                occupied[target] = next
                moved[floater.id] = next
            }
        }

        // Current phase: one slide per floater standing on an arrow, in grid order.
        var slides: [MoveTrace] = []
        let slideOrder = moved.values.sorted { a, b in
            if a.pos.y != b.pos.y { return a.pos.y < b.pos.y }
            return a.pos.x < b.pos.x
        }
        for floater in slideOrder {
            guard let dir = spec.currents[floater.pos] else { continue }
            let target = Pos(x: floater.pos.x + dir.dx, y: floater.pos.y + dir.dy)
            let free = spec.terrainAt(target) == .water && occupied[target] == nil
            slides.append(MoveTrace(id: floater.id, from: floater.pos, to: free ? target : floater.pos))
            if free {
                occupied.removeValue(forKey: floater.pos)
                var next = floater
                next.pos = target
                occupied[target] = next
                moved[floater.id] = next
            }
        }

        var next = state
        next.floaters = state.floaters.map { moved[$0.id]! }
        next.splashesUsed = state.splashesUsed + 1
        return SplashOutcome(state: next, pushes: pushes, slides: slides)
    }

    static func chebyshev(_ a: Pos, _ b: Pos) -> Int {
        max(abs(a.x - b.x), abs(a.y - b.y))
    }
}

/// Breadth-first search over floater layouts. Floaters of the same kind and
/// color are interchangeable, so states are canonicalized by sorting - this
/// keeps the frontier small enough for every hand-made level.
nonisolated enum Solver {

    static let defaultStateCap = 400_000

    /// Shortest list of splash positions that wins from `state`, or nil if no
    /// solution exists within `maxDepth` splashes (or the search exceeds `stateCap`).
    static func solve(
        _ state: GameState,
        maxDepth: Int? = nil,
        stateCap: Int = defaultStateCap
    ) -> [Pos]? {
        if state.won { return [] }
        let depthLimit = maxDepth ?? state.splashesLeft
        if depthLimit <= 0 { return nil }

        let spec = state.spec
        let taps = tapCandidates(spec)

        struct NodeKey: Hashable {
            let layout: [Int]
        }

        func keyOf(_ floaters: [Floater]) -> NodeKey {
            // (kind, color, y, x) packed into one comparable Int per floater.
            let packed = floaters.map { f in
                (((f.kind.rawValue &* 8 &+ (f.color.map { $0.rawValue + 1 } ?? 0)) &* 1024
                    &+ f.pos.y) &* 1024) &+ f.pos.x
            }.sorted()
            return NodeKey(layout: packed)
        }

        var start = state
        start.splashesUsed = 0
        var seen = Set<NodeKey>()
        seen.insert(keyOf(start.floaters))
        // Each queue entry carries the taps that led to it, so reconstructing
        // the winning line is free; paths are short so the memory cost is tiny.
        var frontier: [(GameState, [Pos])] = [(start, [])]

        for _ in 1...depthLimit {
            var next: [(GameState, [Pos])] = []
            for (current, path) in frontier {
                for tap in taps {
                    if current.floaters.contains(where: { $0.pos == tap }) { continue }
                    let outcome = Engine.splash(current, at: tap)
                    let key = keyOf(outcome.state.floaters)
                    if !seen.insert(key).inserted { continue }
                    if outcome.state.won { return path + [tap] }
                    if seen.count > stateCap { return nil }
                    var reset = outcome.state
                    reset.splashesUsed = 0
                    next.append((reset, path + [tap]))
                }
            }
            if next.isEmpty { return nil }
            frontier = next
        }
        return nil
    }

    private static func tapCandidates(_ spec: LevelSpec) -> [Pos] {
        var taps: [Pos] = []
        for y in 0..<spec.rows {
            for x in 0..<spec.cols {
                let pos = Pos(x: x, y: y)
                if spec.terrainAt(pos) == .water { taps.append(pos) }
            }
        }
        return taps
    }
}
