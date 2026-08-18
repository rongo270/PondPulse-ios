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
    private let onWin: (_ stars: Int) -> Void

    @Published private(set) var state: GameState

    /// The last splash, kept so the board can animate the ripple and the drifts.
    @Published private(set) var lastOutcome: SplashOutcome?

    @Published private(set) var hintCell: Pos?
    @Published private(set) var hintState: HintState = .idle

    /// The pond is known to be unwinnable from here. Because ducklings settle for
    /// good, a pond can reach a dead end long before the splashes run out; rather
    /// than let the player splash on for nothing, the board says so and offers an
    /// undo. Every check behind this is a proof, so it never fires on a pond that
    /// could still be finished.
    @Published private(set) var deadEnd = false

    private var deadEndCheck: Task<Void, Never>?

    private var history: [GameState] = []

    /// The rest of the solved line, kept after one solver run: as long as the
    /// player keeps tapping the glowing cell, the glow walks the line step by
    /// step without solving again.
    private var solutionLine: [Pos] = []

    /// Bumps on every user-visible state change so a stale solver result is dropped.
    private var generation = 0

    init(spec: LevelSpec, onWin: @escaping (_ stars: Int) -> Void) {
        self.spec = spec
        self.onWin = onWin
        self.state = Engine.initial(spec)
    }

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
        if state.won { onWin(stars()) }
        return true
    }

    func undo() {
        guard let previous = history.popLast() else { return }
        clearHint()
        lastOutcome = nil
        state = previous
        generation += 1
        recheckDeadEnd()
    }

    func reset() {
        clearHint()
        history.removeAll()
        lastOutcome = nil
        state = Engine.initial(spec)
        generation += 1
        recheckDeadEnd()
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
        let depth = spec.maxSplashes
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
}
