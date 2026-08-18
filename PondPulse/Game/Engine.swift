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
    /// Bonus ponds sit outside the level count: a golden reward stage per pack.
    var isBonus: Bool = false

    func terrainAt(_ pos: Pos) -> Terrain {
        guard (0..<cols).contains(pos.x), (0..<rows).contains(pos.y) else { return .bank }
        return terrain[pos.y * cols + pos.x]
    }

    /// Whether a duck of `color` counts as docked on the pad at `pos` (if any).
    func padAccepts(_ pos: Pos, _ color: DuckColor?) -> Bool {
        guard let padColor = pads[pos] else { return false }
        return padColor == nil || padColor == color
    }

    /// A duckling that has climbed onto a pad it accepts. Settled ducklings are
    /// home for good: ripples and currents no longer move them, so progress can
    /// never be washed away. They still take up their cell, so they block other
    /// floaters like any obstacle.
    func isSettled(_ floater: Floater) -> Bool {
        floater.kind == .duck && padAccepts(floater.pos, floater.color)
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

    /// No arrangement of the ducklings still adrift can fill the pads still free
    /// - settled ducklings never move, so a pad they took is gone for good, and
    /// plain pads accept every color. Exactly Hall's condition over the four
    /// duckling groups, so it never cries wolf: when this is true the pond truly
    /// cannot be finished and the player is offered an undo instead.
    var stranded: Bool {
        if won { return false }
        let takenPads = Set(floaters.filter { spec.isSettled($0) }.map(\.pos))
        let freePads = spec.pads.filter { !takenPads.contains($0.key) }
        let plainPads = freePads.values.count { $0 == nil }
        var padsByColor: [DuckColor: Int] = [:]
        for case let color? in freePads.values { padsByColor[color, default: 0] += 1 }

        let adrift = floaters.filter { $0.kind == .duck && !spec.isSettled($0) }
        var adriftByColor: [DuckColor: Int] = [:]
        for case let color? in adrift.map(\.color) { adriftByColor[color, default: 0] += 1 }
        let needPlainPad = adrift.count { $0.color == nil }
            + adriftByColor.reduce(0) { $0 + max(0, $1.value - (padsByColor[$1.key] ?? 0)) }
        return needPlainPad > plainPads
    }
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
    /// Deliberately does not consult `GameState.stranded`: that is a UI-level
    /// courtesy, and keeping it out of here leaves the search loop allocation-free.
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
            if spec.isSettled(current) {
                pushes.append(MoveTrace(id: floater.id, from: current.pos, to: current.pos))
                continue
            }
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
        // Ducklings that just settled ignore the arrow under them.
        var slides: [MoveTrace] = []
        let slideOrder = moved.values.sorted { a, b in
            if a.pos.y != b.pos.y { return a.pos.y < b.pos.y }
            return a.pos.x < b.pos.x
        }
        for floater in slideOrder {
            if spec.isSettled(floater) { continue }
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

    /// Whether some duckling still adrift can no longer reach any pad that would
    /// take it, no matter how the rest of the pond is played.
    ///
    /// The walk deliberately pretends the pond is empty of other floaters, so the
    /// set of cells it finds is larger than what is truly reachable. That makes a
    /// "no" here a proof: if a duckling cannot reach a pad even with the water to
    /// itself, it certainly cannot with traffic in the way. It catches the classic
    /// trap of a duckling pinned against a bank - a splash can only push a floater
    /// *away* from it, so a duckling in the leftmost column can never be moved
    /// right, and is stuck in that column forever.
    static func hasUnreachablePad(_ state: GameState) -> Bool {
        let spec = state.spec
        return state.floaters.contains { floater in
            floater.kind == .duck && !spec.isSettled(floater) && !canReachAPad(spec, floater)
        }
    }

    private static func canReachAPad(_ spec: LevelSpec, _ duck: Floater) -> Bool {
        var seen: Set<Pos> = [duck.pos]
        var queue: [Pos] = [duck.pos]
        var head = 0
        while head < queue.count {
            let at = queue[head]
            head += 1
            if spec.padAccepts(at, duck.color) { return true } // settles here, done
            // A splash whose push is blocked still counts as a splash, and the
            // current under the duckling fires afterwards regardless. That is the
            // one way off a bank-pinned cell, so leaving it out told players a
            // pond was dead when the water was about to carry them out of it.
            if let dir = spec.currents[at] {
                let slid = Pos(x: at.x + dir.dx, y: at.y + dir.dy)
                if spec.terrainAt(slid) == .water, seen.insert(slid).inserted { queue.append(slid) }
            }
            for dx in -1...1 {
                for dy in -1...1 {
                    if dx == 0 && dy == 0 { continue }
                    if !canBePushed(spec, at, dx, dy) { continue }
                    let pushed = Pos(x: at.x + dx, y: at.y + dy)
                    if spec.terrainAt(pushed) != .water { continue }
                    if seen.insert(pushed).inserted { queue.append(pushed) }
                    // The current under the landing cell may carry it one further,
                    // or may be blocked by traffic: both endings stay possible.
                    guard let dir = spec.currents[pushed] else { continue }
                    let slid = Pos(x: pushed.x + dir.dx, y: pushed.y + dir.dy)
                    if spec.terrainAt(slid) == .water, seen.insert(slid).inserted { queue.append(slid) }
                }
            }
        }
        return false
    }

    /// Whether any splashable cell would push a floater at `at` along (`dx`, `dy`).
    /// The push direction is the sign of the offset from the splash, so this asks
    /// whether the pond has water on the opposite side.
    private static func canBePushed(_ spec: LevelSpec, _ at: Pos, _ dx: Int, _ dy: Int) -> Bool {
        for y in 0..<spec.rows {
            for x in 0..<spec.cols {
                if x == at.x && y == at.y { continue }
                if spec.terrainAt(Pos(x: x, y: y)) != .water { continue }
                if (at.x - x).signum() == dx && (at.y - y).signum() == dy { return true }
            }
        }
        return false
    }
}

/// Breadth-first search over floater layouts. Floaters of the same kind and
/// color are interchangeable, so states are canonicalized by sorting - this
/// keeps the frontier small enough for every hand-made level.
nonisolated enum Solver {

    /// A position, independent of which floater is which: (kind, color, y, x)
    /// packed into one Int per floater, sorted. Two states with the same key are
    /// the same puzzle position.
    fileprivate struct NodeKey: Hashable {
        let layout: [Int]

        init(_ floaters: [Floater]) {
            layout = floaters.map { f in
                (((f.kind.rawValue &* 8 &+ (f.color.map { $0.rawValue + 1 } ?? 0)) &* 1024
                    &+ f.pos.y) &* 1024) &+ f.pos.x
            }.sorted()
        }
    }

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

        var start = state
        start.splashesUsed = 0
        var seen = Set<NodeKey>()
        seen.insert(NodeKey(start.floaters))
        // Each queue entry carries the taps that led to it, so reconstructing
        // the winning line is free; paths are short so the memory cost is tiny.
        var frontier: [(GameState, [Pos])] = [(start, [])]

        for _ in 1...depthLimit {
            var next: [(GameState, [Pos])] = []
            for (current, path) in frontier {
                for tap in taps {
                    if current.floaters.contains(where: { $0.pos == tap }) { continue }
                    let outcome = Engine.splash(current, at: tap)
                    let key = NodeKey(outcome.state.floaters)
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

    /// Whether the pond is provably lost from `state`: the search visited every
    /// position reachable from here and none of them wins.
    ///
    /// Only ever answers true on that proof. Running out of depth or hitting
    /// `stateCap` answers false - "don't know" has to read as hope, or the game
    /// would tell a player their winnable pond is dead. Since settled ducklings
    /// stop moving, the reachable set shrinks as a level is played, which is
    /// exactly when this can finish.
    static func isProvablyLost(
        _ state: GameState,
        maxDepth: Int = 12,
        stateCap: Int = defaultStateCap
    ) -> Bool {
        if state.won { return false }
        if state.stranded { return true } // the pads alone already settle it

        let taps = tapCandidates(state.spec)
        var seen: Set<NodeKey> = [NodeKey(state.floaters)]
        var start = state
        start.splashesUsed = 0
        var frontier = [start]

        for _ in 0..<maxDepth {
            var next: [GameState] = []
            for current in frontier {
                for tap in taps {
                    if current.floaters.contains(where: { $0.pos == tap }) { continue }
                    let outcome = Engine.splash(current, at: tap)
                    if !seen.insert(NodeKey(outcome.state.floaters)).inserted { continue }
                    if outcome.state.won { return false }
                    if seen.count > stateCap { return false } // gave up, so: unknown
                    var reset = outcome.state
                    reset.splashesUsed = 0
                    next.append(reset)
                }
            }
            // Nothing new to try anywhere: the whole reachable set is a dead end.
            if next.isEmpty { return true }
            frontier = next
        }
        return false
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
