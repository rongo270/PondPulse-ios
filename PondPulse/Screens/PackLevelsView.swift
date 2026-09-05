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

/// How wide a level tile wants to be, and the fewest it will settle for.
///
/// A tile carries the pad the player has equipped, and at a fifth of a phone's
/// width that picture is a smudge - the whole point of it is being able to tell
/// one pond from the next. So a phone gets four, which is also what spends the
/// empty half-screen a stage of fifteen used to leave under itself.
///
/// Anything wider gets more of them rather than four enormous ones: fixed at
/// four, a landscape iPad drew tiles a hand's width across.
private let tileWidth: CGFloat = 96
private let minColumns = 4
private let maxColumns = 8

/// How far onto the page the banks at the top and bottom reach.
///
/// Named here rather than inside the drawing because the content has to clear
/// it: the first row of pads starts below this, or it sits half-buried in the
/// grass.
private let bankDepth: CGFloat = 26

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
        // Above the water, with the tabs. It describes the stage the way they
        // do, and on the bank it was unreadable - a green chip on green grass.
        VStack(spacing: 0) {
            StageMeta(stage: stage, solved: vm.stageSolved(stage), stars: vm.stageStars(stage))
                .padding(.horizontal, 16)

            GeometryReader { outer in
                // Tall accessibility fonts can still outgrow a stage; the page
                // scrolls rather than clipping its last row.
                ScrollView {
                    // The stage is laid out *on* a pond, and the pond is as tall
                    // as whatever it has to hold - at least a screenful, so a
                    // stage that does not fill one is water rather than a hole,
                    // and taller than that when it has to be. Pinned to the
                    // viewport instead, the bank stayed at the bottom of the
                    // screen and the last row of pads scrolled underneath it.
                    stageWater(
                        pack: pack,
                        stage: stage,
                        currentLevelId: currentLevelId,
                        width: outer.size.width
                    )
                    .frame(minHeight: outer.size.height, alignment: .top)
                    .background {
                        Canvas { ctx, size in
                            drawStagePond(
                                &ctx,
                                size: size,
                                palette: palette,
                                seed: stage.firstLevelNumber,
                                bank: bankDepth
                            )
                        }
                        .accessibilityHidden(true)
                    }
                }
            }
        }
    }

    /// One stage's ponds, its golden pond and the pack stepper, on the water.
    private func stageWater(
        pack: Pack,
        stage: PackStage,
        currentLevelId: String,
        width: CGFloat
    ) -> some View {
        // Four on a phone, more on anything wider - and never so many that a
        // pad shrinks back into the smudge the grid was redrawn to avoid.
        let columns = min(max(Int((width - 32) / tileWidth), minColumns), maxColumns)
        return VStack(spacing: 0) {
                Spacer().frame(height: bankDepth + 14)

                let rows = stride(from: 0, to: stage.levels.count, by: columns).map {
                    Array(stage.levels[$0..<min($0 + columns, stage.levels.count)])
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { _, rowLevels in
                    HStack(spacing: 10) {
                        ForEach(rowLevels, id: \.id) { level in
                            let premiumLocked = vm.isPremiumLevel(level.id) && !vm.isPremium
                            let number = vm.globalLevelNumber(level.id)
                            LevelPad(
                                number: number,
                                padId: vm.padId,
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
                    .padding(.bottom, 14)
                }

                // The golden pond this stage closes - one per stage, so it reads
                // as this page's reward rather than a pile at the end of a
                // seventy-level pack.
                // The rung this golden pond sits on, and so the prize it pays.
                let rung = (Levels.bonusPonds.firstIndex { $0.id == stage.bonus.level.id } ?? -1) + 1
                let prizes = Catalog.bonusPrizesAt(rung)
                BonusPondRow(
                    stars: vm.stars[stage.bonus.level.id] ?? 0,
                    unlocked: vm.isBonusUnlocked(pack, stage.bonus),
                    prizes: prizes,
                    // Earned only when *all* of them are. The last golden pond
                    // pays three things, and a tick against a row where two of
                    // the three had arrived would be a lie about the third.
                    prizeEarned: !prizes.isEmpty && prizes.allSatisfy {
                        vm.isOwned(Catalog.unlockOf($0), productId: Catalog.productIdOf($0))
                    },
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

                Spacer().frame(height: bankDepth + 16)
        }
        .padding(.horizontal, 16)
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
    let prizes: [Catalog.Reward]
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

            // Every prize on the rung, one line each. Most pay one; the
            // thirtieth pays three, and a finale showing only the first of them
            // would hand two over in silence.
            ForEach(Array(prizes.enumerated()), id: \.offset) { _, prize in
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

/// One pond as a lily pad: the pad the player has equipped, in full colour once
/// cleared, lying back in the water while it waits, barely there when locked,
/// and ringed in accent for the pond they are up to.
///
/// It used to be a plain rounded tile. Drawing the real pad is what makes the
/// level select their pond rather than a grid of buttons - and the pad they
/// bought is one they should see somewhere other than the puzzle itself.
private struct LevelPad: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let number: Int
    /// The lily pad the player has equipped. Their pond, their level select.
    let padId: String
    let stars: Int
    let unlocked: Bool
    let premiumLocked: Bool
    let current: Bool
    let onTap: () -> Void

    var body: some View {
        let solved = stars > 0
        let open = unlocked || premiumLocked
        let lockedLabel: String? = premiumLocked ? strings["level_locked_premium"]
            : !unlocked ? strings["level_locked"]
            : nil

        Button(action: onTap) {
            VStack(spacing: 3) {
                ZStack {
                    Canvas { ctx, size in
                        // The pad wears the accent as its ring on the pond you
                        // are up to - the same ring a coloured pad wears in a
                        // puzzle, so the screen has one idea of what a ring
                        // around a pad means.
                        drawPadStyle(
                            &ctx,
                            padId: padId,
                            rect: CGRect(origin: .zero, size: size),
                            palette: palette,
                            ring: current ? palette.accent : nil
                        )
                    }
                    if let lockedLabel {
                        Image(systemName: premiumLocked ? "crown.fill" : "lock.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(premiumLocked ? palette.accent : Color.white.opacity(0.85))
                            .accessibilityLabel(lockedLabel)
                    } else {
                        // On the pad, so it takes the pad's own contrast rather
                        // than the water's. Never wraps: a pond number is at
                        // most 450.
                        Text("\(number)")
                            .font(.game(17, .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                // Every pad is the same green, so brightness is what says how
                // far you have got: a cleared pond sits up in full colour, one
                // you have not played yet lies back in the water, and a locked
                // one is barely there. Without this the only difference between
                // the first pond and the fortieth was three small stars, and a
                // grid you have to read rather than scan is a grid that has
                // stopped telling you anything.
                //
                // The pond you are on is where the eye should land first. Left
                // on the unplayed dim it wore its accent ring at 62%, which made
                // the one thing the screen is pointing at the second faintest
                // thing on it.
                .opacity(!open ? 0.35 : (solved || current) ? 1 : 0.62)

                // Three fixed-size stars under the pad, floating on the water.
                // Nothing in this row grows with the font scale, so it cannot
                // wrap or collide however large the player has set their type.
                HStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(
                                index < stars ? palette.star
                                    : palette.ripple.opacity(open ? 0.35 : 0.18)
                            )
                    }
                }
            }
        }
        .buttonStyle(SquishyButtonStyle())
        .disabled(!open)
    }
}
