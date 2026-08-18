//
//  PacksView.swift
//  PondPulse
//
//  The pond, one plain card per pack, two to a row. Nine cards laid out in a
//  grid is barely a scroll - the ponds themselves live one tap deeper, on
//  PackLevelsView - and a card carries only what a player weighs before diving
//  in: which levels it holds, how hard it bites, and how far through it they
//  already are. Port of the Android ui/PacksScreen.kt.
//

import SwiftUI

private let packColumns = 2

struct PacksView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    /// Whether the pack the player is on has scrolled out of sight, so the
    /// "back to your pond" pill can offer to take them there.
    @State private var currentOffScreen = false

    var body: some View {
        let currentPackId = vm.currentPack().id
        let firstPremiumIndex = Levels.packs.firstIndex { vm.isPackPremiumLocked($0) }

        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ScreenHeader(title: strings["packs_title"], onBack: { vm.back() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(palette.star)
                        Text("\(vm.totalStars)")
                            .font(.game(16, .bold))
                            .foregroundStyle(palette.accent)
                            .contentTransition(.numericText())
                    }
                }

                PondProgressHeader(solved: vm.solvedLevels(), total: Levels.all.count)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: 10),
                                count: packColumns
                            ),
                            spacing: 10
                        ) {
                            ForEach(Array(Levels.packs.enumerated()), id: \.element.id) { index, pack in
                                let premiumLocked = vm.isPackPremiumLocked(pack)
                                if premiumLocked, index == firstPremiumIndex {
                                    PremiumUpsellBanner(
                                        levelCount: vm.premiumLevelCount(),
                                        price: vm.price(Catalog.premiumId, fallback: Catalog.premiumPrice)
                                    ) {
                                        vm.navigate(.shop)
                                    }
                                    .gridCellColumns(packColumns)
                                }
                                let solved = vm.packSolved(pack)
                                PackCard(
                                    pack: pack,
                                    solved: solved,
                                    stars: vm.packStars(pack),
                                    state: {
                                        if premiumLocked { return .premium }
                                        if !vm.isPackUnlocked(pack) { return .locked }
                                        if pack.id == currentPackId { return .current }
                                        if solved == pack.levels.count { return .cleared }
                                        return .open
                                    }()
                                ) {
                                    if premiumLocked {
                                        vm.navigate(.shop)
                                    } else {
                                        vm.navigate(.packLevels(packId: pack.id))
                                    }
                                }
                                // Identity is the pack, not a row index: the grid
                                // must never reuse one pack's card for another's.
                                .id(pack.id)
                                .onAppear { if pack.id == currentPackId { currentOffScreen = false } }
                                .onDisappear { if pack.id == currentPackId { currentOffScreen = true } }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                    .onAppear {
                        if currentPackId != Levels.packs[0].id {
                            proxy.scrollTo(currentPackId, anchor: .center)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        // The whole point of landing on your own pack: if browsing
                        // carries you away from it, one tap brings you back instead
                        // of a screenful of scrolling.
                        if currentOffScreen {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    proxy.scrollTo(currentPackId, anchor: .center)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "scope")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(strings["packs_jump_back"])
                                        .font(.game(14, .bold))
                                }
                                .foregroundStyle(PondPalette.onAccent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(palette.accent, in: Capsule())
                            }
                            .buttonStyle(SquishyButtonStyle())
                            .padding(.bottom, 18)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: currentOffScreen)
                }
            }
        }
        .pondContentWidth()
    }
}

/// Where the player stands in the whole pond, above the grid. It doesn't name
/// which pack they are on: the grid shows every pack at once with their own card
/// ringed, so a line repeating it was a line to read past.
private struct PondProgressHeader: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let solved: Int
    let total: Int

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(strings["packs_progress_label"])
                    .font(.game(12))
                    .foregroundStyle(palette.textSecondary)
                Spacer()
                Text(strings["packs_progress_value", solved, total])
                    .font(.game(13, .bold))
                    .foregroundStyle(palette.accent)
            }
            ProgressTrack(
                fraction: Double(solved) / Double(total),
                color: palette.accent,
                track: palette.surface,
                height: 6
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}

enum PackState { case current, cleared, open, locked, premium }

/// One pack, on a half-width card: which levels it holds, how hard it bites, and
/// how far through it the player already is. The badge rides the title row rather
/// than a trailing column, because half a screen has no room to spare.
private struct PackCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let pack: Pack
    let solved: Int
    let stars: Int
    let state: PackState
    let onTap: () -> Void

    var body: some View {
        let locked = state == .locked || state == .premium
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text(strings["pack_number", pack.number])
                        .font(.game(17, .bold))
                        .foregroundStyle(locked ? palette.textSecondary : palette.textPrimary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    PackBadge(state: state)
                }
                Text(strings["pack_range", pack.firstLevelNumber, pack.lastLevelNumber])
                    .font(.game(12))
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
                    .padding(.top, 3)
                DifficultyChip(difficulty: pack.difficulty)
                    .opacity(locked ? 0.6 : 1)
                    .padding(.top, 8)

                if state == .locked {
                    Text(strings["pack_locked_reach", pack.firstLevelNumber])
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                        .padding(.top, 9)
                } else {
                    ProgressTrack(
                        fraction: Double(solved) / Double(pack.levels.count),
                        color: palette.accent,
                        track: palette.background.opacity(0.45),
                        height: 5
                    )
                    .padding(.top, 9)
                    Text(strings["pack_stars", stars, pack.levels.count * 3])
                        .font(.game(12, .bold))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            // The pack you are on sits a shade higher than the rest; a locked one
            // fades back, so a run of unreachable cards never shouts louder than
            // the one you can actually play.
            .background(
                state == .current ? palette.surfaceHigh
                    : locked ? palette.surface.opacity(0.6)
                    : palette.surface,
                in: shape
            )
            .overlay {
                if state == .current { shape.strokeBorder(palette.accent, lineWidth: 2) }
            }
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// The round marker on a card's title row: what this pack wants from you.
private struct PackBadge: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let state: PackState

    var body: some View {
        let icon: String
        let tint: Color
        let fill: Color?
        switch state {
        case .current: icon = "play.fill"; tint = PondPalette.onAccent; fill = palette.accent
        case .cleared: icon = "checkmark"; tint = palette.accent; fill = nil
        case .open: icon = "chevron.forward"; tint = palette.textSecondary; fill = nil
        case .locked: icon = "lock.fill"; tint = palette.textSecondary.opacity(0.7); fill = nil
        case .premium: icon = "crown.fill"; tint = PondPalette.onAccent; fill = palette.accent
        }
        let label: String = switch state {
        case .current: strings["pack_continue"]
        case .cleared: strings["pack_cleared"]
        case .open: strings["pack_play"]
        case .locked: strings["level_locked"]
        case .premium: strings["level_locked_premium"]
        }

        return Image(systemName: icon)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: 30, height: 30)
            // Only the two badges that ask for a tap are filled; the rest sit on
            // the card's own ground so they read as markers, not buttons.
            .background(fill ?? palette.background.opacity(0.35), in: Circle())
            .accessibilityLabel(label)
    }
}

/// What the ponds in this stage actually contain - read off the maps, not declared.
struct MechanicIcons: View {
    let mechanics: Set<Mechanic>
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Mechanic.allCases, id: \.self) { mechanic in
                if mechanics.contains(mechanic) {
                    Image(systemName: symbol(mechanic))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(tint)
                }
            }
        }
    }

    private func symbol(_ mechanic: Mechanic) -> String {
        switch mechanic {
        case .rocks: "mountain.2.fill"
        case .turtles: "tortoise.fill"
        case .colors: "paintpalette.fill"
        case .currents: "water.waves"
        }
    }
}
struct DifficultyChip: View {
    @Environment(\.strings) private var strings
    let difficulty: Difficulty

    var body: some View {
        let color: Color = switch difficulty {
        case .easy: Color(hex: 0x5FBF6E)
        case .medium: Color(hex: 0xE3B93D)
        case .hard: Color(hex: 0xEF6155)
        case .veryHard: Color(hex: 0xC0201E)
        }
        let label: String = switch difficulty {
        case .easy: strings["difficulty_easy"]
        case .medium: strings["difficulty_medium"]
        case .hard: strings["difficulty_hard"]
        case .veryHard: strings["difficulty_very_hard"]
        }
        Text(label)
            .font(.game(10, .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
    }
}

/// Sits right above the first premium pack for players who don't own it yet.
struct PremiumUpsellBanner: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let levelCount: Int
    let price: String
    let onOpenShop: () -> Void

    var body: some View {
        Button(action: onOpenShop) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(palette.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(strings["packs_premium_banner_title", levelCount])
                        .font(.game(15, .bold))
                        .foregroundStyle(palette.textPrimary)
                    Text(strings["packs_premium_banner_body"])
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
                Text(price)
                    .font(.game(15, .bold))
                    .foregroundStyle(palette.accent)
            }
            .padding(14)
            .background(palette.surfaceHigh, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(palette.accent.opacity(0.8), lineWidth: 2)
            )
        }
        .buttonStyle(SquishyButtonStyle())
        .padding(.top, 20)
    }
}

/// One level drawn as a lily leaf floating on the list: green once solved,
/// pale while waiting, faded when locked. The notch rotates per level so a
/// row reads like real scattered leaves.
struct LevelLeaf: View {
    @Environment(\.palette) private var palette
    let stars: Int
    let unlocked: Bool
    let premiumLocked: Bool
    let number: Int
    /// The pond the player is up to, ringed so it is findable at a glance.
    var current = false
    let onTap: () -> Void

    var body: some View {
        let leaf: Color
        let leafShadow: Color?
        switch (stars > 0, unlocked || premiumLocked) {
        case (true, _):
            leaf = palette.pad
            leafShadow = palette.padDark
        case (false, true):
            leaf = palette.surfaceHigh
            leafShadow = palette.surface
        case (false, false):
            leaf = palette.surface.opacity(0.45)
            leafShadow = nil
        }

        return Button(action: onTap) {
            ZStack {
                Canvas { ctx, size in
                    let cell = min(size.width, size.height)
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = cell * 0.46
                    func disc(_ at: CGPoint) -> Path {
                        Path(ellipseIn: CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2))
                    }
                    if let leafShadow {
                        ctx.fill(disc(CGPoint(x: center.x, y: center.y + cell * 0.025)), with: .color(leafShadow))
                    }
                    ctx.fill(disc(center), with: .color(leaf))
                    // The notch, cut at a per-level angle so leaves feel scattered.
                    var rc = ctx
                    rc.translateBy(x: center.x, y: center.y)
                    rc.rotate(by: .degrees(Double((number * 47) % 360)))
                    rc.translateBy(x: -center.x, y: -center.y)
                    var notch = Path()
                    notch.move(to: center)
                    notch.addLine(to: CGPoint(x: center.x + radius * 1.15, y: center.y - radius * 0.62))
                    notch.addLine(to: CGPoint(x: center.x + radius * 0.62, y: center.y - radius * 1.15))
                    notch.closeSubpath()
                    rc.fill(notch, with: .color(palette.background))
                    // Veins.
                    let vein = (stars > 0 ? palette.padDark : palette.outline).opacity(0.5)
                    let veinR = radius * 0.62
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: center.x - veinR, y: center.y - veinR, width: veinR * 2, height: veinR * 2)),
                        with: .color(vein),
                        style: StrokeStyle(lineWidth: cell * 0.018)
                    )
                    // Dew highlight.
                    let dewR = cell * 0.045
                    let dewAt = CGPoint(x: center.x - radius * 0.42, y: center.y - radius * 0.42)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: dewAt.x - dewR, y: dewAt.y - dewR, width: dewR * 2, height: dewR * 2)),
                        with: .color(.white.opacity(stars > 0 ? 0.30 : 0.12))
                    )
                }

                if premiumLocked {
                    VStack(spacing: 2) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(palette.accent.opacity(0.85))
                        Text("\(number)")
                            .font(.game(10, .semibold))
                            .foregroundStyle(palette.textSecondary.opacity(0.8))
                    }
                } else if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.textSecondary.opacity(0.5))
                } else {
                    VStack(spacing: 1) {
                        Text("\(number)")
                            .font(.game(16, .bold))
                            .foregroundStyle(stars > 0 ? .white : palette.textPrimary)
                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { index in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(
                                        index < stars ? palette.star
                                            : stars > 0 ? .white.opacity(0.35)
                                            : palette.textSecondary.opacity(0.25)
                                    )
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if current {
                    Circle().strokeBorder(palette.accent, lineWidth: 2).padding(2)
                }
            }
        }
        .buttonStyle(SquishyButtonStyle())
        .disabled(!(unlocked || premiumLocked))
    }
}
