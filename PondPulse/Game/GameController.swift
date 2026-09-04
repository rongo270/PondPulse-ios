//
//  GameController.swift
//  PondPulse
//
//  Holds one level's play session: state, undo history, hints and star
//  scoring. Ported from the Android ui/GameController.kt; the solver runs on
//  a background task so the pond never hitches.
//

import Combine
import SwiftUI

enum HintState { case idle, thinking, shown, noneFound }

@MainActor
final class GameController: ObservableObject {

    let spec: LevelSpec

    /// A teaching pond that shows the way. The ring that a hint would draw is
    /// drawn from the start and re-solved after every splash, so a first-time
    /// player is never looking at a board they cannot read. It costs no hint -
    /// it is the lesson, not a purchase.
    private let guided: Bool

    private let onWin: (_ stars: Int, _ splashes: Int) -> Void

    @Published private(set) var state: GameState

    /// The last splash, kept so the board can animate the ripple and the drifts.
    @Published private(set) var lastOutcome: SplashOutcome?

    @Published private(set) var hintCell: Pos?

    /// The guided tutorial's ring. Kept apart from `hintCell` so the tip line
    /// still reads as the lesson rather than as hint feedback: a guided pond is
    /// always pointing somewhere, and "Try the glowing spot" said on every
    /// single splash would drown the rule the pond is there to teach.
    @Published private(set) var guideCell: Pos?

    /// The cell to ring on the board: a hint the player asked for, else the guide.
    var ringCell: Pos? { hintCell ?? guideCell }

    @Published private(set) var hintState: HintState = .idle

    /// The pond is known to be unwinnable from here. Because ducklings settle for
    /// good, a pond can reach a dead end long before the splashes run out; rather
    /// than let the player splash on for nothing, the board says so and offers an
    /// undo. Every check behind this is a proof, so it never fires on a pond that
    /// could still be finished.
    @Published private(set) var deadEnd = false

    private var deadEndCheck: Task<Void, Never>?
    private var guideCheck: Task<Void, Never>?

    private var history: [GameState] = []

    /// The rest of the solved line, kept after one solver run: as long as the
    /// player keeps tapping the glowing cell, the glow walks the line step by
    /// step without solving again.
    private var solutionLine: [Pos] = []

    /// Bumps on every user-visible state change so a stale solver result is dropped.
    private var generation = 0

    init(spec: LevelSpec, guided: Bool = false, onWin: @escaping (_ stars: Int, _ splashes: Int) -> Void) {
        self.spec = spec
        self.guided = guided
        self.onWin = onWin
        self.state = Engine.initial(spec)
        refreshGuide()
    }

    /// How deep a hint search goes: a little past par rather than the whole
    /// (roomy) budget. Every extra ply multiplies the frontier, and a line
    /// longer than this is not a hint anybody wants to follow anyway - on a
    /// guided pond, whose budget is 24 over par, it is the difference between
    /// an answer and a hang.
    private var searchDepth: Int { min(spec.maxSplashes, spec.par + 3) }

    var canUndo: Bool { !history.isEmpty }

    func stars() -> Int {
        switch state.splashesUsed {
        case ...spec.par: 3
        case ...(spec.par + 2): 2
        default: 1
        }
    }

    @discardableResult
    func tap(_ pos: Pos) -> Bool {
        if deadEnd { return false } // nothing left to find here; only undo helps
        guard Engine.canSplash(state, at: pos) else { return false }
        let followedHint = solutionLine.first == pos
        history.append(state)
        let outcome = Engine.splash(state, at: pos)
        lastOutcome = outcome
        state = outcome.state
        generation += 1
        if followedHint {
            solutionLine.removeFirst()
            hintCell = solutionLine.first
            hintState = hintCell == nil ? .idle : .shown
        } else {
            clearHint()
        }
        recheckDeadEnd()
        if state.won { onWin(stars(), state.splashesUsed) }
        refreshGuide()
        return true
    }

    func undo() {
        guard let previous = history.popLast() else { return }
        clearHint()
        lastOutcome = nil
        state = previous
        generation += 1
        recheckDeadEnd()
        refreshGuide()
    }

    func reset() {
        clearHint()
        history.removeAll()
        lastOutcome = nil
        state = Engine.initial(spec)
        generation += 1
        recheckDeadEnd()
        refreshGuide()
    }

    /// Re-answers "can this still be won?" for the position just reached. The two
    /// cheap proofs run right away; the exhaustive one runs off the main actor on
    /// a snapshot, and is thrown away if the player has moved on meanwhile.
    private func recheckDeadEnd() {
        deadEndCheck?.cancel()
        deadEnd = state.stranded || Engine.hasUnreachablePad(state)
        if deadEnd || state.won { return }
        let snapshot = state
        let mark = generation
        deadEndCheck = Task { [weak self] in
            let lost = await Task.detached(priority: .utility) {
                Solver.isProvablyLost(snapshot, maxDepth: 6, stateCap: 1_500)
            }.value
            guard !Task.isCancelled, let self, self.generation == mark else { return }
            self.deadEnd = lost
        }
    }

    /// `onShown` fires only when a hint is actually found and displayed.
    func requestHint(onShown: @escaping () -> Void = {}) {
        if hintState == .thinking || hintState == .shown { return }
        hintState = .thinking
        let snapshot = state
        let requestGeneration = generation
        let depth = searchDepth
        Task {
            let solution = await Task.detached(priority: .userInitiated) {
                Solver.solve(snapshot, maxDepth: depth)
            }.value
            guard generation == requestGeneration else { return } // player moved on meanwhile
            if let solution, !solution.isEmpty {
                solutionLine = solution
                hintCell = solution.first
                hintState = .shown
                onShown()
            } else {
                hintState = .noneFound
            }
        }
    }

    private func clearHint() {
        solutionLine = []
        hintCell = nil
        hintState = .idle
    }

    // MARK: - The guided tutorial

    /// Re-points the tutorial ring at the next splash of a winning line.
    ///
    /// It re-solves rather than walking a line it solved once, because the point
    /// of a guided pond is that a *wrong* tap is still recoverable: after one the
    /// old line is meaningless, and a ring left on it would teach the wrong
    /// lesson. When nothing wins from here the ring simply goes out, and the
    /// highlighted Reset in `GameView` takes over.
    private func refreshGuide() {
        guard guided else { return }
        guideCheck?.cancel()
        if state.won || state.stuck {
            guideCell = nil
            return
        }
        let snapshot = state
        let mark = generation
        let spec = spec
        let depth = searchDepth
        guideCheck = Task { [weak self] in
            let cell = await Task.detached(priority: .userInitiated) {
                GameController.guidingTap(from: snapshot, spec: spec, depth: depth)
            }.value
            guard !Task.isCancelled, let self, self.generation == mark else { return }
            self.guideCell = cell
        }
    }

    /// The tap to ring: a *readable* first splash of a shortest line, not merely
    /// the first one the search happens to return.
    ///
    /// The two differ, and on a teaching pond the difference is the lesson.
    /// Level 1 says "every duckling drifts one step away from your splash" and
    /// the solver's own answer was a corner tap that shoved the duckling
    /// diagonally - a true two-move win that demonstrates the wrong rule three
    /// ponds early. So every legal tap that still wins in the same number of
    /// splashes is collected, and the one lined up straight behind a duckling
    /// and close to it is preferred. Where only a diagonal wins - the pond that
    /// teaches diagonals - nothing straight qualifies and the diagonal is rung,
    /// which is exactly right.
    nonisolated private static func guidingTap(from: GameState, spec: LevelSpec, depth: Int) -> Pos? {
        guard let firstLine = Solver.solve(from, maxDepth: depth), let fallback = firstLine.first
        else { return nil }
        let remaining = firstLine.count - 1
        let adrift = from.floaters.filter { $0.kind == .duck && !spec.isSettled($0) }
        var best = fallback
        var bestScore = Int.max
        for y in 0..<spec.rows {
            for x in 0..<spec.cols {
                let tap = Pos(x: x, y: y)
                guard Engine.canSplash(from, at: tap) else { continue }
                let next = Engine.splash(from, at: tap).state
                let wins = remaining == 0 ? next.won : Solver.solve(next, maxDepth: remaining) != nil
                guard wins else { continue }
                // Straight behind a duckling beats a corner, and near beats far.
                let straight = adrift.contains { $0.pos.x == x || $0.pos.y == y } ? 0 : 1
                let near = adrift.map { max(abs($0.pos.x - x), abs($0.pos.y - y)) }.min() ?? 0
                let score = straight * 100 + near
                if score < bestScore {
                    bestScore = score
                    best = tap
                }
            }
        }
        return best
    }
}
