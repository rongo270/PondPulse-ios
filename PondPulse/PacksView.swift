//
//  PacksView.swift
//  PondPulse
//
//  The Pond: all 30 stages as collapsible headers with lily-leaf level
//  buttons. Only the stage the player is working through starts open, so even
//  level 260 is a tap away. Port of the Android ui/PacksScreen.kt.
//

import SwiftUI

struct PacksView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    @State private var expandedIds: Set<String>
    private let currentPackId: String

    init(vm: AppViewModel) {
        self.vm = vm
        let packId = Levels.packOf(vm.continueLevelId()).id
        currentPackId = packId
        _expandedIds = State(initialValue: [packId])
    }

    var body: some View {
        let firstPremiumIndex = Levels.packs.firstIndex { vm.isPremiumLevel($0.levels[0].id) }

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

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(Levels.packs.enumerated()), id: \.element.id) { packIndex, pack in
                            let packIsPremium = vm.isPremiumLevel(pack.levels[0].id)
                            if !vm.isPremium, packIsPremium, packIndex == firstPremiumIndex {
                                PremiumUpsellBanner(
                                    levelCount: vm.premiumLevelCount(),
                                    price: vm.price(Catalog.premiumId, fallback: Catalog.premiumPrice)
                                ) {
                                    vm.navigate(.shop)
                                }
                            }
                            let expanded = expandedIds.contains(pack.id)
                            PackHeader(
                                pack: pack,
                                earned: pack.levels.reduce(0) { $0 + (vm.stars[$1.id] ?? 0) },
                                premiumBadge: packIsPremium,
                                expanded: expanded
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    if expanded { expandedIds.remove(pack.id) } else { expandedIds.insert(pack.id) }
                                }
                            }
                            .id(pack.id)
                            if expanded {
                                levelGrid(pack)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .onAppear {
                    if currentPackId != Levels.packs[0].id {
                        proxy.scrollTo(currentPackId, anchor: .top)
                    }
                }
            }
        }
    }

    private func levelGrid(_ pack: Pack) -> some View {
        let rows = stride(from: 0, to: pack.levels.count, by: 4).map {
            Array(pack.levels[$0..<min($0 + 4, pack.levels.count)])
        }
        return ForEach(Array(rows.enumerated()), id: \.offset) { _, rowLevels in
            HStack(spacing: 10) {
                ForEach(rowLevels, id: \.id) { level in
                    let premiumLocked = vm.isPremiumLevel(level.id) && !vm.isPremium
                    LevelLeaf(
                        stars: vm.stars[level.id] ?? 0,
                        unlocked: vm.isUnlocked(level.id),
                        premiumLocked: premiumLocked,
                        number: vm.globalLevelNumber(level.id)
                    ) {
                        if premiumLocked {
                            vm.navigate(.shop)
                        } else {
                            vm.navigate(.game(levelId: level.id))
                        }
                    }
                }
                ForEach(0..<(4 - rowLevels.count), id: \.self) { _ in
                    Color.clear.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }
}

private struct PackHeader: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let pack: Pack
    let earned: Int
    let premiumBadge: Bool
    let expanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(strings[pack.nameKey])
                        .font(.game(16, .bold))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                    if premiumBadge {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(palette.accent)
                    }
                    DifficultyChip(difficulty: pack.difficulty)
                    Spacer()
                    Text(strings["pack_stars", earned, pack.levels.count * 3])
                        .font(.game(13, .semibold))
                        .foregroundStyle(palette.accent)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(palette.textSecondary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                // Star progress across the pack, at a glance.
                GeometryReader { geo in
                    let fraction = min(max(CGFloat(earned) / CGFloat(pack.levels.count * 3), 0), 1)
                    ZStack(alignment: .leading) {
                        Capsule().fill(palette.background.opacity(0.6))
                        if fraction > 0 {
                            Capsule().fill(palette.accent).frame(width: geo.size.width * fraction)
                        }
                    }
                }
                .frame(height: 5)
                if expanded {
                    Text(strings[pack.descKey])
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                expanded ? palette.surfaceHigh : palette.surface,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(SquishyButtonStyle())
        .padding(.top, 8)
    }
}

/// The stage's difficulty at a glance: green is easy, yellow medium, red hard
/// and deep red the very hardest ponds.
private struct DifficultyChip: View {
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
private struct PremiumUpsellBanner: View {
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
private struct LevelLeaf: View {
    @Environment(\.palette) private var palette
    let stars: Int
    let unlocked: Bool
    let premiumLocked: Bool
    let number: Int
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
        }
        .buttonStyle(SquishyButtonStyle())
        .disabled(!(unlocked || premiumLocked))
    }
}
