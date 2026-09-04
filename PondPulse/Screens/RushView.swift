//
//  RushView.swift
//  PondPulse
//
//  Splash Rush: a timed dash through random ponds, easy to hard. Solving a
//  pond banks its stars as points; the best score per duration lives on the
//  device. Rush never touches campaign progress - it is its own little pond.
//  Port of the Android ui/RushScreen.kt.
//

import SwiftUI

private enum RushPhase { case setup, playing, results }

struct RushView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    @State private var phase = RushPhase.setup
    @State private var durationSec = 60
    @State private var timeLeft = 0
    @State private var score = 0
    @State private var solved = 0
    @State private var newBest = false
    @State private var sequence: [LevelSpec] = []
    @State private var levelIndex = 0
    @State private var runKey = 0

    var body: some View {
        switch phase {
        case .setup:
            RushSetup(bests: vm.rushBests, onBack: { vm.back() }, onStart: { start($0) })
        case .playing:
            RushPlay(
                vm: vm,
                spec: sequence[levelIndex % sequence.count],
                timeLeft: timeLeft,
                score: score,
                onQuit: { phase = .setup },
                onSkip: { levelIndex += 1 },
                onSolved: { stars in
                    score += stars
                    solved += 1
                    levelIndex += 1
                }
            )
            .id("\(runKey)-\(levelIndex)")
            // The countdown; banks the score when the water settles.
            .task(id: runKey) {
                while timeLeft > 0 {
                    try? await Task.sleep(for: .seconds(1))
                    if Task.isCancelled { return }
                    timeLeft -= 1
                }
                newBest = score > (vm.rushBests[durationSec] ?? 0)
                vm.recordRushScore(durationSec: durationSec, score: score)
                phase = .results
            }
        case .results:
            RushResults(
                score: score,
                solved: solved,
                best: vm.rushBests[durationSec] ?? score,
                newBest: newBest,
                onPlayAgain: { start(durationSec) },
                onChangeTime: { phase = .setup },
                onDone: { vm.back() }
            )
        }
    }

    private func start(_ seconds: Int) {
        durationSec = seconds
        timeLeft = seconds
        score = 0
        solved = 0
        newBest = false
        sequence = vm.rushSequence()
        levelIndex = 0
        runKey += 1
        phase = .playing
    }
}

private struct RushSetup: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let bests: [Int: Int]
    let onBack: () -> Void
    let onStart: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: strings["rush_title"], onBack: onBack)
            ScrollView {
                VStack(spacing: 0) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(palette.accent)
                        .padding(.top, 12)
                        .symbolEffect(.pulse)
                    Text(strings["rush_desc"])
                        .font(.game(14))
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    Spacer().frame(height: 28)

                    ForEach([(60, "rush_mode_1"), (180, "rush_mode_3"), (300, "rush_mode_5")], id: \.0) { seconds, labelKey in
                        let best = bests[seconds]
                        Button {
                            onStart(seconds)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "timer")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(palette.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(strings[labelKey])
                                        .font(.game(16, .bold))
                                        .foregroundStyle(palette.textPrimary)
                                    Text(best.map { strings["rush_best", $0] } ?? strings["rush_best_none"])
                                        .font(.game(12))
                                        .foregroundStyle(best != nil ? palette.accent : palette.textSecondary)
                                }
                                Spacer()
                                Text(formatTime(seconds))
                                    .font(.game(22, .heavy))
                                    .foregroundStyle(palette.textSecondary)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(SquishyButtonStyle())
                        .padding(.vertical, 6)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .pondContentWidth()
    }
}

private struct RushPlay: View {
    @ObservedObject var vm: AppViewModel
    let spec: LevelSpec
    let timeLeft: Int
    let score: Int
    let onQuit: () -> Void
    let onSkip: () -> Void
    let onSolved: (Int) -> Void

    @StateObject private var controller: GameController
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    init(
        vm: AppViewModel, spec: LevelSpec, timeLeft: Int, score: Int,
        onQuit: @escaping () -> Void, onSkip: @escaping () -> Void, onSolved: @escaping (Int) -> Void
    ) {
        self.vm = vm
        self.spec = spec
        self.timeLeft = timeLeft
        self.score = score
        self.onQuit = onQuit
        self.onSkip = onSkip
        self.onSolved = onSolved
        _controller = StateObject(wrappedValue: GameController(spec: spec) { _, _ in })
    }

    var body: some View {
        let state = controller.state

        ZStack {
            VStack(spacing: 0) {
                HStack {
                    RoundIconButton(systemName: "chevron.backward") { onQuit() }
                    Spacer()
                    Text(formatTime(timeLeft))
                        .font(.game(28, .heavy))
                        .foregroundStyle(timeLeft <= 10 ? palette.danger : palette.textPrimary)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.default, value: timeLeft)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(palette.star)
                        Text("\(score)")
                            .font(.game(17, .bold))
                            .foregroundStyle(palette.accent)
                            .contentTransition(.numericText())
                    }
                }

                DropletRow(total: spec.maxSplashes, left: state.splashesLeft)
                    .padding(.vertical, 8)

                Spacer(minLength: 0)
                PondBoardView(
                    state: state,
                    hintCell: nil,
                    skinId: vm.skinId,
                    padId: vm.padId,
                    onTap: { pos in
                        let accepted = controller.tap(pos)
                        if accepted { Haptics.splash(enabled: vm.haptics) }
                        return accepted
                    }
                )
                .frame(maxWidth: .infinity)
                Spacer(minLength: 0)

                Text(state.stuck || controller.deadEnd ? strings["rush_stuck"] : " ")
                    .font(.game(14))
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)

                HStack(spacing: 12) {
                    GhostButton(strings["undo"]) { controller.undo() }
                    GhostButton(strings["rush_skip"]) { onSkip() }
                }
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 16)
            .pondContentWidth(560)

            if state.won {
                WinCelebration(skinId: vm.skinId)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.won)
        // A win banks the stars and rolls to the next pond after a short cheer.
        .task(id: state.won) {
            if state.won {
                try? await Task.sleep(for: .seconds(0.7))
                if !Task.isCancelled { onSolved(controller.stars()) }
            }
        }
        // A dead end just resets the same pond - the clock is punishment enough.
        .task(id: state.stuck || controller.deadEnd) {
            if state.stuck || controller.deadEnd {
                try? await Task.sleep(for: .seconds(0.7))
                if !Task.isCancelled { controller.reset() }
            }
        }
    }
}

private struct RushResults: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let score: Int
    let solved: Int
    let best: Int
    let newBest: Bool
    let onPlayAgain: () -> Void
    let onChangeTime: () -> Void
    let onDone: () -> Void

    var body: some View {
        OverlayCard {
            SectionTitle(strings["rush_time_up"])
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(palette.star)
                Text("\(score)")
                    .font(.game(44, .heavy))
                    .foregroundStyle(palette.textPrimary)
            }
            Text(strings["rush_solved", solved])
                .font(.game(14))
                .foregroundStyle(palette.textSecondary)
            Text(newBest ? strings["rush_new_best"] : strings["rush_best", best])
                .font(.game(15, .bold))
                .foregroundStyle(palette.accent)
            PrimaryButton(strings["rush_play_again"], action: onPlayAgain)
            HStack(spacing: 10) {
                GhostButton(strings["rush_change_time"], action: onChangeTime)
                GhostButton(strings["rush_done"], action: onDone)
            }
        }
    }
}

private func formatTime(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}
