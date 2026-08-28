//
//  DailyView.swift
//  PondPulse
//
//  The Daily Pond: one pond a day, the same one for everybody, played for a
//  streak rather than for stars. Port of the Android ui/DailyScreen.kt.
//
//  It deliberately never touches campaign progress. The pond it hands you is
//  drawn from ponds you may already have solved, and solving it here banks no
//  star and moves no frontier - the reward is the streak, the hints it pays,
//  and the three friends the milestones unlock. That keeps the daily from
//  becoming a second, parallel campaign to keep up with.
//

import SwiftUI

struct DailyView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    private let epochDay: Int
    @StateObject private var controller: GameController

    /// A replay after today's clear is welcome, it just does not pay again.
    @State private var attempt = 0
    @State private var payout: ProgressStore.DailyPayout?
    @State private var showCard = false

    init(vm: AppViewModel) {
        self.vm = vm
        let day = vm.today()
        self.epochDay = day
        _controller = StateObject(wrappedValue: GameController(spec: vm.dailySpec(day)) { _ in
            // The store refuses a second payout for the same day, so a replay
            // banks nothing and the card knows to stay quiet.
        })
    }

    var body: some View {
        let state = controller.state
        let spec = controller.spec
        let liveStreak = vm.dailyStreak
        let alreadyDone = vm.dailyDoneToday

        ZStack {
            VStack(spacing: 0) {
                HStack {
                    RoundIconButton(systemName: "chevron.backward") { vm.back() }
                    Spacer()
                    VStack(spacing: 1) {
                        Text(strings["daily_title"])
                            .font(.game(17, .bold))
                            .foregroundStyle(palette.accent)
                        Text(strings["game_ducks_home", state.ducksHome, spec.duckCount])
                            .font(.game(12, .semibold))
                            .foregroundStyle(palette.textSecondary)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    RoundIconButton(systemName: "arrow.counterclockwise") { controller.reset() }
                }

                StreakBar(streak: liveStreak, best: vm.dailyBestStreak, done: alreadyDone)

                DropletRow(total: spec.maxSplashes, left: state.splashesLeft)
                    .padding(.vertical, 6)

                Spacer(minLength: 0)
                PondBoardView(
                    state: state,
                    hintCell: controller.hintCell,
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

                // No hint button here on purpose: the daily is one pond, once,
                // and it pays hints rather than spending them.
                HStack(spacing: 12) {
                    GhostButton(strings["undo"]) { controller.undo() }
                    GhostButton(strings["restart"]) { controller.reset() }
                }
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 16)
            .pondContentWidth(560)

            if state.won {
                WinCelebration(skinId: vm.skinId)
                    .transition(.opacity)
            }
            if state.won && showCard {
                DailyWinCard(
                    payout: payout,
                    streak: liveStreak,
                    totalDays: vm.dailyTotal,
                    bestStreak: vm.dailyBestStreak,
                    nextMilestone: ProgressStore.streakMilestones.first { $0 > vm.dailyBestStreak },
                    equippedSkinId: vm.skinId,
                    onEquipSkin: { vm.selectSkin($0) },
                    onReplay: {
                        showCard = false
                        attempt += 1
                        controller.reset()
                    },
                    onDone: { vm.back() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.won)
        .animation(.easeInOut(duration: 0.25), value: showCard)
        .task(id: state.won) {
            if state.won {
                // Banked here rather than in the controller's win callback so
                // the payout lands in view state the card can read.
                payout = vm.recordDailyWin(epochDay)
                try? await Task.sleep(for: .seconds(1.1))
                showCard = true
            } else {
                showCard = false
                payout = nil
            }
        }
    }
}

/// The streak, its personal best, and whether today is already banked.
private struct StreakBar: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let streak: Int
    let best: Int
    let done: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(streak > 0 ? palette.accent : palette.textSecondary.opacity(0.5))
            VStack(alignment: .leading, spacing: 1) {
                Text(strings["daily_streak_days", streak])
                    .font(.game(15, .bold))
                    .foregroundStyle(palette.textPrimary)
                Text(strings.plural("daily_streak_best", best))
                    .font(.game(12, .semibold))
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(palette.accent)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(done ? palette.accent.opacity(0.7) : .clear, lineWidth: 2)
        )
        .padding(.top, 4)
    }
}

/// What the clear was worth. A replay of a day already banked shows the same
/// card without a payout line, so it never implies a second reward.
private struct DailyWinCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let payout: ProgressStore.DailyPayout?
    let streak: Int
    let totalDays: Int
    let bestStreak: Int
    let nextMilestone: Int?
    let equippedSkinId: String
    let onEquipSkin: (String) -> Void
    let onReplay: () -> Void
    let onDone: () -> Void

    var body: some View {
        // A milestone that this very clear reached gets the full banner.
        let earned = payout == nil ? nil : Catalog.skins.first { $0.unlock.rewardStreak == streak }

        return OverlayCard {
            SectionTitle(strings["daily_win_title"])
            Text(payout != nil
                ? strings.plural("daily_win_streak", streak)
                : strings["daily_win_already"])
                .font(.game(14))
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)

            if let payout {
                Text(strings["daily_win_hints", payout.hints])
                    .font(.game(14))
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                Text(strings.plural("daily_win_total", totalDays))
                    .font(.game(12, .semibold))
                    .foregroundStyle(palette.textSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            if let earned {
                RewardUnlockBanner(
                    name: strings[earned.nameKey],
                    equipped: equippedSkinId == earned.id,
                    onEquip: { onEquipSkin(earned.id) }
                ) { SkinPreview(skinId: earned.id).frame(width: 52, height: 52) }
            } else if let nextMilestone {
                Text(strings.plural("daily_next_milestone", nextMilestone - bestStreak))
                    .font(.game(12, .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(strings["daily_done"], action: onDone)
            GhostButton(strings["daily_replay"], action: onReplay)
        }
    }
}
