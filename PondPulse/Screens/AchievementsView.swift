//
//  AchievementsView.swift
//  PondPulse
//
//  The badge shelf - the iOS face of the Android ui/AchievementsScreen.kt.
//
//  Six families, four badges each, and every one of them says three things:
//  what it wants, how far along you are, and what it pays. There is no Claim
//  button and no "collect" step - the coins are part of the balance the moment
//  the bar fills, because they are recomputed from progress rather than banked.
//  The intro line says so in as many words, since a shelf of rewards with
//  nothing to tap on reads as broken until somebody explains that it is not.
//
//  Earned badges are not moved to the bottom or hidden. A family reads as a
//  ladder - four rungs in order, the ones behind you filled in - and reordering
//  it would take away the only thing that shows how far up it you are.
//

import SwiftUI

struct AchievementsView: View {
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
                    Text(strings["ach_subtitle", earned, Achievements.all.count])
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
                    // at rather than on twenty-four rows to read through.
                    Text(
                        Achievements.nextUp(snapshot).map {
                            strings["ach_next_up", strings[$0.nameKey]]
                        } ?? strings["ach_all_done"]
                    )
                    .font(.game(13))
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                    ForEach(Achievements.byFamily, id: \.0) { family, badges in
                        FamilyHeader(
                            family: family,
                            done: badges.count { $0.isEarned(snapshot) },
                            total: badges.count
                        )
                        ForEach(badges) { badge in
                            BadgeRow(badge: badge, snapshot: snapshot)
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

private struct FamilyHeader: View {
    let family: Achievements.Family
    let done: Int
    let total: Int
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: family.symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(palette.textSecondary)
            Text(strings[family.titleKey])
                .font(.game(14, .bold))
                .foregroundStyle(palette.textSecondary)
            Spacer(minLength: 8)
            Text(strings["shop_count", done, total])
                .font(.game(12))
                .foregroundStyle(done == total ? palette.accent : palette.textSecondary)
        }
        .padding(.top, 12)
    }
}

/// One badge: name, what it wants, a bar, and its coins.
///
/// The bar is drawn even when the badge is done - filled and in the accent -
/// rather than being swapped for a tick on its own. The row keeps exactly the
/// same shape and height either way, so a family does not jump about as badges
/// land, which matters because several of them land at once on a good day.
private struct BadgeRow: View {
    let badge: Achievements.Badge
    let snapshot: Achievements.Snapshot
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        let done = badge.isEarned(snapshot)
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(done ? palette.accent.opacity(0.22) : palette.background)
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(palette.accent)
                } else {
                    Text("\(badge.goal)")
                        .font(.game(11, .bold))
                        .foregroundStyle(palette.textSecondary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .padding(.horizontal, 3)
                }
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(strings[badge.nameKey])
                    .font(.game(14, .bold))
                    .foregroundStyle(done ? palette.textPrimary : palette.textSecondary)
                Text(strings[badge.descKey, badge.goal])
                    .font(.game(12))
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressBar(fraction: badge.fraction(snapshot), done: done)
                Text(
                    done
                        ? strings["ach_earned"]
                        : strings["ach_desc_progress", badge.progress(snapshot), badge.goal]
                )
                .font(.game(11))
                .foregroundStyle(done ? palette.accent : palette.textSecondary.opacity(0.85))
            }

            Spacer(minLength: 6)

            HStack(spacing: 4) {
                CoinIcon(size: 13)
                Text(strings["ach_reward", badge.coins])
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
