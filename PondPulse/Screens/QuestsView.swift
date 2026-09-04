//
//  QuestsView.swift
//  PondPulse
//
//  Quests, in two halves and two screens.
//
//  **Today** is three quests drawn from the date - one gentle, one middling,
//  one hard, of three different kinds - and a bonus for clearing all three.
//  They are the half of the economy that never runs out: the ladders below them
//  and the whole campaign together are worth about a fifth of the shop, and the
//  other four fifths are bought a few hundred coins at a time, by turning up.
//
//  Unlike everything else on this screen, a quest's coins are *banked* rather
//  than derived - a day that has ended cannot be recomputed - so a finished one
//  is paid the moment it lands and written down for the day. See `Quests`.
//
//  **The shelf** is nine rows, one per family, and each row is one live bar:
//  the goal you are working on, how far up it you are, and what it pays. It used
//  to be twenty-four rows of four-rung families all open at once, which is a
//  screen you scroll rather than read - and with the ladders now eleven rungs
//  deep it would have been seventy-one.
//
//  **A ladder** is what a row opens into: every rung of one family in order,
//  the ones behind you ticked, the one you are on lit, and every step still to
//  come laid out with its price in ponds and its payout in coins. That last part
//  is the reason the screen exists at all - "what is left" is the question a
//  badge shelf is for, and a bar can only ever answer "not this".
//
//  There is no Claim button and no collect step: the coins are part of the
//  balance the moment a bar fills, because they are recomputed from progress
//  rather than banked. The intro line says so in as many words, since a shelf of
//  rewards with nothing to tap on reads as broken until somebody explains that
//  it is not.
//

import SwiftUI

struct QuestsView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        let snapshot = vm.achievements
        let earned = Achievements.earnedCount(snapshot)
        let paid = Achievements.coins(snapshot)

        VStack(spacing: 0) {
            ScreenHeader(title: strings["ach_title"], onBack: { vm.back() }) {
                CoinChip(coins: vm.coins) { vm.navigate(.shop) }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    TodayBoard(vm: vm)

                    Text(strings["quests_milestones"])
                        .font(.game(16, .bold))
                        .foregroundStyle(palette.textPrimary)
                        .padding(.top, 18)

                    Text(strings["ach_subtitle", earned, Achievements.totalRungs])
                        .font(.game(13))
                        .foregroundStyle(palette.textSecondary)
                    Text(strings["ach_intro"])
                        .font(.game(13))
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        CoinIcon(size: 14)
                        Text(strings["ach_coins_earned", paid, Achievements.totalCoins])
                            .font(.game(14, .bold))
                            .foregroundStyle(palette.accent)
                    }
                    // What is closest, so the screen opens on something to aim
                    // at rather than on nine rows to read through.
                    Text(
                        Achievements.nextUp(snapshot).flatMap { standing in
                            standing.next.map {
                                strings["ach_next_up", standing.family.goalText(strings, $0.goal)]
                            }
                        } ?? strings["ach_all_done"]
                    )
                    .font(.game(13))
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                    ForEach(Achievements.Family.allCases) { family in
                        FamilyRow(standing: Achievements.standing(family, snapshot)) {
                            vm.navigate(.questLadder(family.rawValue))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 32)
            }
        }
        .pondContentWidth()
        .background(palette.background.ignoresSafeArea())
    }
}

// MARK: - Today

/// The three quests drawn for today, and the bonus for clearing all three.
///
/// No Claim buttons: a finished quest has already paid by the time its bar
/// fills, exactly like the ladders under it. The tick is a receipt, not a
/// button, and the line under the heading says so.
private struct TodayBoard: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        let board = vm.questBoard
        let counters = vm.questCounters
        let done = board.count { $0.isDone(counters) }
        let allDone = done == board.count

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(strings["quests_today"])
                    .font(.game(16, .bold))
                    .foregroundStyle(palette.textPrimary)
                Spacer(minLength: 4)
                Text(strings["ach_desc_progress", done, board.count])
                    .font(.game(13))
                    .foregroundStyle(allDone ? palette.accent : palette.textSecondary)
            }
            Text(strings["quests_reset"])
                .font(.game(12))
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(board) { quest in
                QuestRow(quest: quest, counters: counters)
            }

            // The bonus reads as a fourth row rather than as a badge on the
            // third, because it is a fourth payout and hiding it inside the last
            // quest would make finishing the board look like it paid nothing.
            BonusRow(coins: Quests.allDoneBonus, done: allDone, of: board.count)
        }
    }
}

private struct QuestRow: View {
    let quest: Quests.Quest
    let counters: Quests.Counters
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        let done = quest.isDone(counters)
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(done ? palette.accent.opacity(0.22) : palette.background)
                Image(systemName: done ? "checkmark" : quest.kind.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(done ? palette.accent : palette.textSecondary)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(strings[quest.kind.titleKey, quest.goal])
                    .font(.game(14, .bold))
                    .foregroundStyle(done ? palette.textPrimary : palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressBar(fraction: quest.fraction(counters), done: done)
                Text(
                    done
                        ? strings["ach_earned"]
                        : strings["ach_desc_progress", quest.progress(counters), quest.goal]
                )
                .font(.game(11))
                .foregroundStyle(done ? palette.accent : palette.textSecondary.opacity(0.85))
            }

            Spacer(minLength: 6)

            HStack(spacing: 4) {
                CoinIcon(size: 13)
                Text(strings["ach_reward", quest.coins])
                    .font(.game(14, .bold))
                    .foregroundStyle(done ? palette.accent : palette.textSecondary)
            }
            .fixedSize()
        }
        .padding(12)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(done ? palette.accent.opacity(0.7) : .clear, lineWidth: 1.5)
        )
    }
}

private struct BonusRow: View {
    let coins: Int
    let done: Bool
    let of: Int
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: done ? "gift.fill" : "gift")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(done ? palette.accent : palette.textSecondary)
                .frame(width: 34)
            Text(strings["quests_bonus", of])
                .font(.game(13, .bold))
                .foregroundStyle(done ? palette.textPrimary : palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 6)
            HStack(spacing: 4) {
                CoinIcon(size: 13)
                Text(strings["ach_reward", coins])
                    .font(.game(14, .bold))
                    .foregroundStyle(done ? palette.accent : palette.textSecondary)
            }
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(done ? palette.accent.opacity(0.14) : palette.surface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.accent.opacity(done ? 0.7 : 0.25), lineWidth: 1.5)
        )
    }
}

// MARK: - The shelf

/// One family, as one row: the goal being worked on and the bar towards it.
///
/// The row shows the *next* rung, never the last one earned. A shelf that told
/// you what you had already done would be a receipt; the only useful thing it
/// can say is what the next one wants and what it pays.
private struct FamilyRow: View {
    let standing: Achievements.Standing
    let open: () -> Void
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        Button(action: open) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(standing.isComplete ? palette.accent.opacity(0.22) : palette.background)
                    Image(systemName: standing.family.symbol)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(standing.isComplete ? palette.accent : palette.textSecondary)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(strings[standing.family.titleKey])
                            .font(.game(15, .bold))
                            .foregroundStyle(palette.textPrimary)
                        Spacer(minLength: 4)
                        Text(strings["ach_desc_progress", standing.done, standing.total])
                            .font(.game(12))
                            .foregroundStyle(standing.isComplete ? palette.accent : palette.textSecondary)
                    }
                    if let next = standing.next {
                        Text(standing.family.goalText(strings, next.goal))
                            .font(.game(12))
                            .foregroundStyle(palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(strings["ach_family_full"])
                            .font(.game(12))
                            .foregroundStyle(palette.accent)
                    }
                    ProgressBar(fraction: standing.fraction, done: standing.isComplete)
                    HStack(spacing: 6) {
                        Text(strings["ach_desc_progress", standing.value, standing.next?.goal ?? standing.value])
                            .font(.game(11))
                            .foregroundStyle(palette.textSecondary.opacity(0.85))
                        Spacer(minLength: 4)
                        if let next = standing.next {
                            CoinIcon(size: 12)
                            Text(strings["ach_reward", next.coins])
                                .font(.game(13, .bold))
                                .foregroundStyle(palette.accent)
                        }
                    }
                }

                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(palette.textSecondary.opacity(0.7))
            }
            .padding(12)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(standing.isComplete ? palette.accent.opacity(0.7) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - One ladder

/// Every rung of one family, in order.
struct QuestLadderView: View {
    @ObservedObject var vm: AppViewModel
    let family: Achievements.Family
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        let standing = Achievements.standing(family, vm.achievements)
        let pot = standing.rungs.reduce(0) { $0 + $1.coins }

        VStack(spacing: 0) {
            ScreenHeader(title: strings[family.titleKey], onBack: { vm.back() }) {
                CoinChip(coins: vm.coins) { vm.navigate(.shop) }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(strings["ach_subtitle", standing.done, standing.total])
                        .font(.game(13))
                        .foregroundStyle(palette.textSecondary)
                    HStack(spacing: 6) {
                        CoinIcon(size: 14)
                        Text(strings["ach_coins_earned", standing.coins, pot])
                            .font(.game(14, .bold))
                            .foregroundStyle(palette.accent)
                    }

                    ForEach(Array(standing.rungs.enumerated()), id: \.element.id) { index, rung in
                        RungRow(
                            family: family,
                            rung: rung,
                            // The rung below is where this one's bar starts, so
                            // a step reads as the stretch of play it actually
                            // is rather than as everything since the beginning.
                            floor: index > 0 ? standing.rungs[index - 1].goal : 0,
                            value: standing.value,
                            state: index < standing.done ? .earned
                                : index == standing.done ? .current : .locked
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 32)
            }
        }
        .pondContentWidth()
        .background(palette.background.ignoresSafeArea())
    }
}

private enum RungState { case earned, current, locked }

/// One rung: its goal, its payout, and - only on the one you are actually on -
/// a bar.
///
/// A locked rung draws no bar on purpose. Eleven empty tracks stacked up read as
/// eleven things you have failed at; a plain list of numbers with prices reads
/// as a route, which is what it is.
private struct RungRow: View {
    let family: Achievements.Family
    let rung: Achievements.Rung
    let floor: Int
    let value: Int
    let state: RungState
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle().fill(fill)
                switch state {
                case .earned:
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(palette.accent)
                case .current:
                    Image(systemName: family.symbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(palette.accent)
                case .locked:
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(palette.textSecondary.opacity(0.6))
                }
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(family.goalText(strings, rung.goal))
                    .font(.game(14, state == .locked ? .regular : .bold))
                    .foregroundStyle(state == .locked ? palette.textSecondary : palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if state == .current {
                    ProgressBar(fraction: fraction, done: false)
                    Text(strings["ach_desc_progress", value, rung.goal])
                        .font(.game(11))
                        .foregroundStyle(palette.textSecondary.opacity(0.85))
                } else if state == .earned {
                    Text(strings["ach_earned"])
                        .font(.game(11))
                        .foregroundStyle(palette.accent)
                }
            }

            Spacer(minLength: 6)

            HStack(spacing: 4) {
                CoinIcon(size: 13)
                Text(strings["ach_reward", rung.coins])
                    .font(.game(14, .bold))
                    .foregroundStyle(state == .locked ? palette.textSecondary : palette.accent)
            }
            .fixedSize()
        }
        .padding(12)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(state == .current ? palette.accent.opacity(0.7) : .clear, lineWidth: 1.5)
        )
        .opacity(state == .locked ? 0.72 : 1)
    }

    private var fill: Color {
        switch state {
        case .earned, .current: return palette.accent.opacity(0.22)
        case .locked: return palette.background
        }
    }

    private var fraction: Double {
        let span = rung.goal - floor
        guard span > 0 else { return 1 }
        return min(max(Double(value - floor) / Double(span), 0), 1)
    }
}

/// A track with a fill.
private struct ProgressBar: View {
    let fraction: Double
    let done: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(palette.background)
                Capsule()
                    .fill(done ? palette.accent : palette.waterRim)
                    .frame(width: geo.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 6)
    }
}
