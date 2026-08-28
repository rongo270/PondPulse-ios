//
//  PackLevelsView.swift
//  PondPulse
//
//  One pack's ponds, a stage at a time. A pack runs to seventy levels, which
//  laid out flat was two screens of thumb work before you could see what you
//  had left; so only the stage you are on is on screen, its ten to twenty ponds
//  fitting whole, and the tabs above swipe you to its neighbours. Locked stages
//  stay browsable - seeing what is coming reads as a promise, where a wall of
//  padlocks with no context reads as a stop sign.
//
//  Port of the Android ui/PackLevelsScreen.kt.
//

import SwiftUI

private let columns = 5

struct PackLevelsView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    let packId: String

    /// The pond to open the pager on, when the player is backing out of one.
    /// Without it, leaving level 5 returns to whichever page the player's
    /// progress has since reached rather than to the page level 5 is on.
    var focusLevelId: String?

    /// Open on the stage the player is actually up to. Set once on appear:
    /// re-seeking mid-browse would yank the pager out from under them.
    @State private var page = 0
    @State private var seeded = false

    var body: some View {
        let pack = Levels.packById(packId)
        let currentLevelId = vm.continueLevelId()

        VStack(spacing: 0) {
            ScreenHeader(title: strings["pack_number", pack.number], onBack: { vm.back() }) {
                // pack_stars already ends in a star glyph - don't set another
                // one beside it.
                Text(strings["pack_stars", vm.packStars(pack), pack.levels.count * 3])
                    .font(.game(15, .bold))
                    .foregroundStyle(palette.accent)
            }

            StageTabs(stages: pack.stages, selected: page, vm: vm) { page = $0 }

            TabView(selection: $page) {
                ForEach(Array(pack.stages.enumerated()), id: \.element.id) { index, stage in
                    stagePage(pack: pack, stage: stage, currentLevelId: currentLevelId)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .pondContentWidth()
        .onAppear {
            guard !seeded else { return }
            seeded = true
            page = vm.currentStageIndex(pack, focusLevelId: focusLevelId)
        }
    }

    private func stagePage(pack: Pack, stage: PackStage, currentLevelId: String) -> some View {
        // Tall accessibility fonts can still outgrow a stage; the page scrolls
        // rather than clipping its last row.
        ScrollView {
            VStack(spacing: 0) {
                StageMeta(stage: stage, solved: vm.stageSolved(stage), stars: vm.stageStars(stage))

                let rows = stride(from: 0, to: stage.levels.count, by: columns).map {
                    Array(stage.levels[$0..<min($0 + columns, stage.levels.count)])
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { _, rowLevels in
                    HStack(spacing: 8) {
                        ForEach(rowLevels, id: \.id) { level in
                            let premiumLocked = vm.isPremiumLevel(level.id) && !vm.isPremium
                            let number = vm.globalLevelNumber(level.id)
                            LevelTile(
                                number: number,
                                paysPrize: Catalog.rewardLevels.contains(number),
                                stars: vm.stars[level.id] ?? 0,
                                unlocked: vm.isUnlocked(level.id),
                                premiumLocked: premiumLocked,
                                current: level.id == currentLevelId
                            ) {
                                if premiumLocked {
                                    vm.navigate(.shop)
                                } else {
                                    vm.replaceTop(.packLevels(packId: packId, focusLevelId: level.id))
                                    vm.navigate(.game(levelId: level.id))
                                }
                            }
                        }
                        ForEach(0..<(columns - rowLevels.count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .padding(.bottom, 8)
                }

                // The golden pond this stage closes - one per stage, so it reads
                // as this page's reward rather than a pile at the end of a
                // seventy-level pack.
                // The rung this golden pond sits on, and so the prize it pays.
                let rung = (Levels.bonusPonds.firstIndex { $0.id == stage.bonus.level.id } ?? -1) + 1
                let prize = Catalog.bonusPrizeAt(rung)
                BonusPondRow(
                    stars: vm.stars[stage.bonus.level.id] ?? 0,
                    unlocked: vm.isBonusUnlocked(pack, stage.bonus),
                    prize: prize,
                    prizeEarned: prize.map {
                        vm.isOwned(Catalog.unlockOf($0), productId: Catalog.productIdOf($0))
                    } ?? false,
                    firstLevel: stage.firstLevelNumber,
                    opensAt: stage.lastLevelNumber
                ) {
                    vm.replaceTop(.packLevels(packId: packId, focusLevelId: stage.bonus.level.id))
                    vm.navigate(.game(levelId: stage.bonus.level.id))
                }

                // Rides under the page rather than the screen: pinned to the
                // bottom it sat marooned below a stage's worth of empty water.
                PackStepper(
                    previous: pack.number >= 2 ? Levels.packs[pack.number - 2] : nil,
                    next: pack.number < Levels.packs.count ? Levels.packs[pack.number] : nil
                ) {
                    vm.replaceTop(.packLevels(packId: $0.id))
                    seeded = false
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

/// The pack's stages as one row of tabs, named by the levels they hold - a range
/// says more than "Stage 2" ever could, and being pure digits it needs no
/// translating. Screen readers get the spelled-out range instead.
private struct StageTabs: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let stages: [PackStage]
    let selected: Int
    let vm: AppViewModel
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                let isSelected = index == selected
                let unlocked = vm.isStageUnlocked(stage)
                let solved = vm.stageSolved(stage)
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { onSelect(index) }
                } label: {
                    VStack(spacing: 3) {
                        Text(strings["stage_range", stage.firstLevelNumber, stage.lastLevelNumber])
                            .font(.game(12, isSelected ? .bold : .regular))
                            .foregroundStyle(
                                isSelected ? palette.textPrimary
                                    : unlocked ? palette.textSecondary
                                    : palette.textSecondary.opacity(0.55)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        ProgressTrack(
                            fraction: Double(solved) / Double(stage.levels.count),
                            color: isSelected ? palette.accent : palette.accent.opacity(0.55),
                            track: palette.background.opacity(0.5),
                            height: 3
                        )
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected ? palette.surfaceHigh : palette.surface.opacity(0.6),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel(strings["pack_range", stage.firstLevelNumber, stage.lastLevelNumber])
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

/// What this stage holds, on one line above its ponds.
private struct StageMeta: View {
    @Environment(\.palette) private var palette
    let stage: PackStage
    let solved: Int
    let stars: Int

    var body: some View {
        HStack(spacing: 8) {
            DifficultyChip(difficulty: stage.difficulty)
            MechanicIcons(mechanics: stage.mechanics, tint: palette.textSecondary)
            Spacer()
            // Digits and a slash: nothing here to translate, in any locale.
            Text("\(solved)/\(stage.levels.count)")
                .font(.game(12))
                .foregroundStyle(palette.textSecondary)
            Image(systemName: "star.fill")
                .font(.system(size: 11))
                .foregroundStyle(palette.star)
            Text("\(stars)")
                .font(.game(12, .bold))
                .foregroundStyle(palette.textPrimary)
        }
        .padding(.top, 4)
        .padding(.bottom, 10)
    }
}

/// A golden pond. Locked until every pond up to `opensAt` has a star; clearing
/// it pays out hints and counts toward the golden cosmetics.
private struct BonusPondRow: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let stars: Int
    let unlocked: Bool
    /// What this golden pond hands over. Drawn whether it is open or not - a
    /// locked pond that will not say what it pays is a locked pond nobody has a
    /// reason to unlock, and hints, which is what these used to give, were never
    /// worth showing off.
    let prize: Catalog.Reward?
    /// Already in the player's hands, so the box records it rather than sells it.
    let prizeEarned: Bool
    let firstLevel: Int
    let opensAt: Int
    let onPlay: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        Button(action: onPlay) {
            VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: unlocked ? "trophy.fill" : "lock.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(unlocked ? palette.star : palette.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(strings["bonus_title"])
                            .font(.game(14, .bold))
                            .foregroundStyle(unlocked ? palette.textPrimary : palette.textSecondary)
                        Text(strings["pack_range", firstLevel, opensAt])
                            .font(.game(11))
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(1)
                    }
                    Text(unlocked ? strings["bonus_row_open"] : strings["bonus_row_locked", opensAt])
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if unlocked { StarsRow(stars: stars, size: 14) }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)

            if let prize {
                PrizeLine(prize: prize, unlocked: unlocked, earned: prizeEarned)
            }
            }
            .background(unlocked ? palette.star.opacity(0.14) : palette.surface, in: shape)
            .overlay {
                if unlocked { shape.strokeBorder(palette.star.opacity(0.5), lineWidth: 1) }
            }
        }
        .buttonStyle(SquishyButtonStyle())
        .disabled(!unlocked)
        .padding(.top, 2)
    }
}

/// Step to the water on either side without going back to the gallery.
private struct PackStepper: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let previous: Pack?
    let next: Pack?
    let onOpen: (Pack) -> Void

    var body: some View {
        HStack(spacing: 10) {
            StepperButton(pack: previous, forward: false, onOpen: onOpen)
            StepperButton(pack: next, forward: true, onOpen: onOpen)
        }
    }
}

private struct StepperButton: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let pack: Pack?
    let forward: Bool
    let onOpen: (Pack) -> Void

    var body: some View {
        Group {
            if let pack {
                Button { onOpen(pack) } label: {
                    HStack(spacing: 6) {
                        if !forward {
                            Image(systemName: "chevron.backward").font(.system(size: 12, weight: .bold))
                        }
                        Text(strings["pack_number", pack.number])
                            .font(.game(13, .semibold))
                            .lineLimit(1)
                        if forward {
                            Image(systemName: "chevron.forward").font(.system(size: 12, weight: .bold))
                        }
                    }
                    .foregroundStyle(palette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(SquishyButtonStyle())
            } else {
                Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
            }
        }
    }
}

/// The prize a golden pond pays, with its own artwork.
private struct PrizeLine: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let prize: Catalog.Reward
    let unlocked: Bool
    let earned: Bool

    var body: some View {
        // Dimmed while the pond is shut, so it reads as something to come rather
        // than something on offer, without hiding what it is.
        let fade: CGFloat = (unlocked || earned) ? 1 : 0.55
        HStack(spacing: 8) {
            Group {
                switch prize {
                case .skin(let item): SkinPreview(skinId: item.id)
                case .pad(let item): PadPreview(padId: item.id)
                case .theme(let item): ThemePreview(palette: item.palette)
                case .decor(let item): DecorPreview(item: item)
                }
            }
            .frame(width: 34, height: 34)
            .opacity(fade)

            Text(strings[earned ? "bonus_prize_earned" : "bonus_prize_pays", strings[prize.nameKey]])
                .font(.game(13, .medium))
                .foregroundStyle(earned ? palette.star : palette.textSecondary.opacity(fade))
                .lineLimit(1)
                .truncationMode(.tail)

            if earned {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(palette.star)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 46)
        .padding(.trailing, 14)
        .padding(.bottom, 11)
    }
}

/// One pond as a plain rounded tile: pad-green once solved, pale while waiting,
/// faded when locked, ringed in accent for the pond you are up to. It used to be
/// a hand-drawn lily leaf, which was lovely and cost a square cell - five of
/// these fit where four leaves did, and a stage that ran three screens now runs
/// none.
private struct LevelTile: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let number: Int
    /// This pond hands over a friend, a sky or a lily pad. Marked on the tile so
    /// a prize is something you can see coming while you climb, rather than a
    /// surprise on the way out of a pond you happened to pick.
    let paysPrize: Bool
    let stars: Int
    let unlocked: Bool
    let premiumLocked: Bool
    let current: Bool
    let onTap: () -> Void

    var body: some View {
        let solved = stars > 0
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let fill: Color = solved
            ? palette.pad
            : (unlocked || premiumLocked) ? palette.surfaceHigh : palette.surface.opacity(0.5)

        Button(action: onTap) {
            ZStack {
                if premiumLocked {
                    VStack(spacing: 1) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(palette.accent.opacity(0.9))
                            .accessibilityLabel(strings["level_locked_premium"])
                        Text("\(number)")
                            .font(.game(11, .semibold))
                            .foregroundStyle(palette.textSecondary.opacity(0.8))
                    }
                } else if !unlocked {
                    VStack(spacing: 1) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(palette.textSecondary.opacity(0.55))
                            .accessibilityLabel(strings["level_locked"])
                        Text("\(number)")
                            .font(.game(11, .semibold))
                            .foregroundStyle(palette.textSecondary.opacity(0.55))
                    }
                } else {
                    VStack(spacing: 2) {
                        Text("\(number)")
                            .font(.game(17, .bold))
                            .foregroundStyle(solved ? .white : palette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        HStack(spacing: 1) {
                            ForEach(0..<3, id: \.self) { index in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(
                                        index < stars ? palette.star
                                            : solved ? Color.white.opacity(0.35)
                                            : palette.textSecondary.opacity(0.25)
                                    )
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(fill, in: shape)
            .overlay(alignment: .topTrailing) {
                // Only while it is still worth chasing: once the pond is solved
                // the prize is banked and the marker is just clutter on a
                // finished tile.
                if paysPrize && !solved && !premiumLocked {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(palette.accent)
                        .padding(3)
                        .accessibilityLabel(strings["level_pays_reward"])
                }
            }
            .overlay {
                if current { shape.strokeBorder(palette.accent, lineWidth: 2) }
            }
        }
        .buttonStyle(SquishyButtonStyle())
        .disabled(!(unlocked || premiumLocked))
    }
}
