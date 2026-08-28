//
//  DecorateView.swift
//  PondPulse
//
//  Decorate: the pond as a thing you arrange. Port of the Android
//  ui/DecorateScreen.kt.
//
//  Three ideas, and everything on the screen serves one of them.
//
//  **You see it before you pay.** Tapping something you do not own puts it on
//  the water as a ghost, exactly where and exactly the size it will be. You can
//  drag the ghost around first. Buying is the last step, not the first - the old
//  shop panel asked for 380 coins for a willow the player had never seen.
//
//  **You put it where you want it.** Every decoration remembers where it was
//  dragged to (`PondCatalog.Decor.at` is only where it starts), and My Pond
//  draws it there. Two ponds with the same seven things in them should not look
//  the same.
//
//  **It cannot be put somewhere silly.** A dock in open water and a lily on the
//  grass both read as bugs, so a shore item dragged over the water slides to the
//  nearer bank and a water item dragged onto grass slides back in. The rule is
//  enforced while the finger is still down, so it teaches itself.
//
//  The pond drawn here is the same basin My Pond draws, in the same fractions,
//  so a thing placed on this screen is in that place on that one. It is a
//  shorter box than My Pond's, which squashes the picture a little; everything
//  is placed in fractions of the box, so nothing lands anywhere unexpected.
//

import SwiftUI

private enum DecorTab: Hashable {
    case decor, sky
}

/// How far onto the grass a shore item's middle must sit.
private let shoreMargin: CGFloat = 0.018

/// True if `at` lands on `item` drawn at `spot`, both in pond fractions.
private func hits(_ item: PondCatalog.Decor, spot: CGPoint, at: CGPoint, aspect: CGFloat) -> Bool {
    let halfX = item.scale * 0.55
    let halfY = item.scale * 0.55 / aspect
    return abs(at.x - spot.x) <= halfX && abs(at.y - spot.y) <= halfY
}

/// Pulls `at` back to somewhere `item` is allowed to be.
///
/// Done while the finger is down rather than on release so the rule shows
/// itself: a dock dragged out over the water follows the finger sideways but
/// stays glued to the bank, which says "not there" far better than a message
/// would.
private func clampToZone(_ item: PondCatalog.Decor, _ at: CGPoint, _ aspect: CGFloat) -> CGPoint {
    let halfY = item.scale * 0.5 / aspect
    let x = min(max(at.x, 0.05), 0.95)
    let top = shoreTopAt(x)
    let bottom = shoreBottomAt(x)
    let y: CGFloat
    switch item.zone {
    case .water:
        let inset = min(halfY, (bottom - top) * 0.45)
        y = min(max(at.y, top + inset), bottom - inset)
    case .shore:
        let nearTop = max(top - shoreMargin, halfY * 0.45)
        let nearBottom = min(bottom + shoreMargin, 1 - halfY * 0.45)
        if at.y <= top - shoreMargin {
            y = max(at.y, halfY * 0.45)
        } else if at.y >= bottom + shoreMargin {
            y = min(at.y, 1 - halfY * 0.45)
        } else if at.y - top < bottom - at.y {
            y = nearTop
        } else {
            y = nearBottom
        }
    }
    return CGPoint(x: x, y: y)
}

/// One clock for the whole scene, and the canvas size the gestures need - the
/// draw closure is the only place either is known.
private final class DecorMotion {
    var time: CGFloat = 0
    var lastTick: Date?
    var lastSize: CGSize = .zero

    func step(to now: Date) {
        let dt = min(CGFloat(now.timeIntervalSince(lastTick ?? now)), 0.05)
        lastTick = now
        time += dt
    }
}

// MARK: - The screen

struct DecorateView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    @State private var tab: DecorTab = .decor
    @State private var selected: String?
    /// The string key of whatever the tray is currently saying, if anything.
    @State private var notice: String?
    @State private var motion = DecorMotion()

    /// Where the thing under the finger is right now. Held here rather than
    /// written to storage every frame: a drag is sixty writes a second, and the
    /// pond only needs to know where the finger let go.
    @State private var dragId: String?
    @State private var dragAt: CGPoint = .zero

    /// Where an unowned preview sits. Cleared when the selection changes, so a
    /// ghost never outlives the thing it was previewing.
    @State private var ghostAt: CGPoint?

    /// Where a drag left something, kept here as well as written to storage.
    /// The write is a store round trip, and for the frame or two it takes, the
    /// decoration would otherwise snap back to where it used to be.
    @State private var justPlaced: [String: CGPoint] = [:]

    /// Everything actually drawn on the pond right now, back to front.
    private var onPond: [PondCatalog.Decor] {
        PondCatalog.decor.filter { vm.isDecorOwned($0) && !vm.decorStored.contains($0.id) }
    }

    private func spotOf(_ item: PondCatalog.Decor) -> CGPoint {
        if item.id == dragId { return dragAt }
        if !vm.isDecorOwned(item) { return ghostAt ?? item.at }
        return justPlaced[item.id] ?? vm.decorSpots[item.id] ?? item.at
    }

    /// The selected item, if it is one the player does not own yet - the ghost.
    private var ghostItem: PondCatalog.Decor? {
        guard let selected, let item = PondCatalog.decorById(selected) else { return nil }
        return vm.isDecorOwned(item) ? nil : item
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                RoundIconButton(systemName: "chevron.backward") { vm.back() }
                Text(strings["pond_decorate"])
                    .font(.game(22, .bold))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                CoinChip(coins: vm.coins) { vm.navigate(.shop) }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            pondCanvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) {
                    if let notice {
                        Text(strings[notice])
                            .font(.game(14, .bold))
                            .foregroundStyle(palette.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(palette.background.opacity(0.72), in: Capsule())
                            .padding(.top, 10)
                            .transition(.opacity)
                    }
                }

            tray
        }
        .background(palette.background)
        .animation(.easeInOut(duration: 0.18), value: notice)
        .onChange(of: selected) { ghostAt = nil }
        .task(id: notice) {
            guard notice != nil else { return }
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            notice = nil
        }
    }

    // MARK: The water

    private var pondCanvas: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                motion.lastSize = size
                motion.step(to: timeline.date)
                let time = motion.time
                let w = size.width
                let h = size.height

                drawPondBasin(&ctx, weatherId: vm.pondWeather, size: size, palette: palette, time: time)

                for item in onPond {
                    let at = spotOf(item)
                    let side = w * item.scale
                    // Only what floats bobs.
                    let bob = item.zone == .water ? sin(time * 0.9 + at.x * 6) * h * 0.004 : 0
                    drawDecor(
                        &ctx, id: item.id,
                        rect: CGRect(x: w * at.x - side / 2, y: h * at.y - side / 2 + bob,
                                     width: side, height: side),
                        palette: palette, phase: time
                    )
                }

                // The ghost: the same drawing, half there, over its own patch of
                // shade so it reads as "not yet" rather than as a faded bug.
                if let ghost = ghostItem {
                    let at = spotOf(ghost)
                    let side = w * ghost.scale
                    let box = CGRect(x: w * at.x - side / 2, y: h * at.y - side / 2,
                                     width: side, height: side)
                    let center = CGPoint(x: box.midX, y: box.midY)
                    ctx.fill(circle(center, side * 0.62), with: .color(palette.accent.opacity(0.14)))
                    ctx.drawLayer { layer in
                        layer.opacity = 0.55
                        drawDecor(&layer, id: ghost.id, rect: box, palette: palette, phase: time)
                    }
                    ctx.stroke(
                        circle(center, side * 0.62),
                        with: .color(palette.accent.opacity(0.75)),
                        style: stroke(w * 0.006)
                    )
                }

                // A ring on whatever is selected and owned, so "this is the one
                // you are moving" survives letting go of it.
                if let id = selected, let pick = PondCatalog.decorById(id),
                   vm.isDecorOwned(pick), !vm.decorStored.contains(pick.id) {
                    let at = spotOf(pick)
                    ctx.stroke(
                        circle(CGPoint(x: w * at.x, y: h * at.y), w * pick.scale * 0.62),
                        with: .color(palette.accent.opacity(0.85)),
                        style: stroke(w * 0.006)
                    )
                }

                drawWeather(&ctx, id: vm.pondWeather, size: size, palette: palette, time: time)
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { point in
            guard let at = fraction(point) else { return }
            let aspect = motion.lastSize.height / motion.lastSize.width
            if let hit = onPond.last(where: { hits($0, spot: spotOf($0), at: at, aspect: aspect) }) {
                selected = hit.id
                Haptics.tick(enabled: vm.haptics)
            }
        }
        // Slop before a drag starts, so a tap that means "select this" is never
        // read as a tap that means "put this here".
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    let aspect = motion.lastSize.height / motion.lastSize.width
                    if dragId == nil {
                        guard let start = fraction(value.startLocation) else { return }
                        // The ghost is grabbable too, which is the only way
                        // "see it where you want it" can be true before any
                        // coins have changed hands.
                        let candidates = onPond + [ghostItem].compactMap { $0 }
                        guard let hit = candidates.last(where: {
                            hits($0, spot: spotOf($0), at: start, aspect: aspect)
                        }) else { return }
                        dragAt = spotOf(hit)
                        dragId = hit.id
                        selected = hit.id
                        Haptics.splash(enabled: vm.haptics)
                    }
                    guard let id = dragId, let item = PondCatalog.decorById(id),
                          let at = fraction(value.location) else { return }
                    dragAt = clampToZone(item, at, aspect)
                }
                .onEnded { _ in
                    guard let id = dragId else { return }
                    if let item = PondCatalog.decorById(id), vm.isDecorOwned(item) {
                        justPlaced[id] = dragAt
                        vm.setDecorSpot(id: id, at: dragAt)
                    } else {
                        ghostAt = dragAt
                    }
                    dragId = nil
                }
        )
    }

    /// A point in the canvas, as fractions of it - or nil before it is laid out.
    private func fraction(_ point: CGPoint) -> CGPoint? {
        let size = motion.lastSize
        guard size.width > 0, size.height > 0 else { return nil }
        return CGPoint(x: point.x / size.width, y: point.y / size.height)
    }

    // MARK: The tray

    private var tray: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TrayTab(text: strings["pond_section_decor"], selected: tab == .decor) {
                    tab = .decor
                    selected = nil
                }
                TrayTab(text: strings["pond_section_sky"], selected: tab == .sky) {
                    tab = .sky
                    selected = nil
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            switch tab {
            case .decor:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PondCatalog.decor) { item in
                            DecorChip(
                                item: item,
                                owned: vm.isDecorOwned(item),
                                out: vm.decorStored.contains(item.id),
                                selected: selected == item.id,
                                affordable: vm.canAfford(item.price)
                            ) {
                                selected = selected == item.id ? nil : item.id
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                }
                decorActions

            case .sky:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PondCatalog.weathers) { sky in
                            let isOwned = vm.isWeatherOwned(sky)
                            SkyChip(
                                sky: sky,
                                owned: isOwned,
                                selected: isOwned && sky.id == vm.pondWeather,
                                affordable: vm.canAfford(sky.price)
                            ) {
                                if isOwned {
                                    vm.setPondWeather(sky.id)
                                } else if vm.canAfford(sky.price) {
                                    let productId = PondCatalog.weatherProductId(sky.id)
                                    if vm.buyWithCoins(price: sky.price, productId: productId) {
                                        vm.setPondWeather(sky.id)
                                    }
                                } else {
                                    notice = "decorate_short"
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
        }
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(
            palette.surfaceHigh,
            in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22, style: .continuous)
        )
    }

    /// What you can do with whatever is selected: buy it, or put it in and out.
    @ViewBuilder
    private var decorActions: some View {
        let item = selected.flatMap { PondCatalog.decorById($0) }
        Group {
            if let item {
                let isOwned = vm.isDecorOwned(item)
                let isOut = vm.decorStored.contains(item.id)
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(strings[item.nameKey])
                            .font(.game(15, .bold))
                            .foregroundStyle(palette.textPrimary)
                        Text(strings[hintKey(item, owned: isOwned, out: isOut)])
                            .font(.game(12))
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if isOwned {
                        Button {
                            vm.setDecorStored(id: item.id, stored: !isOut)
                        } label: {
                            Text(strings[isOut ? "decorate_put_in" : "decorate_take_out"])
                                .font(.game(15, .bold))
                                .foregroundStyle(palette.accent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(SquishyButtonStyle())
                    } else {
                        let affordable = vm.canAfford(item.price)
                        Button { buy(item, affordable: affordable) } label: {
                            Group {
                                // The price is still there; free mode simply is
                                // not charging it - see `FreeMode`.
                                if FreeMode.enabled {
                                    Text(strings["shop_free_tag"]).font(.game(15, .bold))
                                } else {
                                    HStack(spacing: 6) {
                                        CoinIcon(size: 15)
                                        Text("\(item.price)").font(.game(15, .bold))
                                    }
                                }
                            }
                            .foregroundStyle(affordable ? PondPalette.onAccent : palette.textSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(
                                affordable ? palette.accent : palette.surface,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
            } else {
                Text(strings["decorate_pick"])
                    .font(.game(12))
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 62)
        .padding(.horizontal, 16)
    }

    private func hintKey(_ item: PondCatalog.Decor, owned: Bool, out: Bool) -> String {
        if !owned { return "decorate_drag_ghost" }
        if out { return "decorate_is_out" }
        return item.zone == .shore ? "decorate_zone_shore" : "decorate_zone_water"
    }

    private func buy(_ item: PondCatalog.Decor, affordable: Bool) {
        guard affordable else {
            notice = "decorate_short"
            return
        }
        // Buy it where the ghost was standing, not where the catalogue would
        // have put it.
        let where_ = ghostAt
        if let where_ { justPlaced[item.id] = where_ }
        if vm.buyWithCoins(price: item.price, productId: PondCatalog.decorProductId(item.id)) {
            if let where_ { vm.setDecorSpot(id: item.id, at: where_) }
            vm.setDecorStored(id: item.id, stored: false)
        }
        notice = "decorate_placed"
    }
}

// MARK: - Tray parts

private struct TrayTab: View {
    @Environment(\.palette) private var palette
    let text: String
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.game(14, .bold))
                .foregroundStyle(selected ? PondPalette.onAccent : palette.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(selected ? palette.accent : palette.surface, in: Capsule())
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

private struct DecorChip: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let item: PondCatalog.Decor
    let owned: Bool
    let out: Bool
    let selected: Bool
    let affordable: Bool
    let onTap: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        Button(action: onTap) {
            VStack(spacing: 3) {
                Canvas { ctx, size in
                    // Drawn on a patch of the pond's own water so a green thing
                    // on a green tile is still a thing you can see.
                    drawRoundRectPatch(&ctx, size: size, palette: palette)
                    let side = min(size.width, size.height) * 0.82
                    drawDecor(
                        &ctx, id: item.id,
                        rect: CGRect(x: (size.width - side) / 2, y: (size.height - side) / 2,
                                     width: side, height: side),
                        palette: palette, phase: 0.7
                    )
                }
                .frame(width: 80, height: 80)
                .overlay(alignment: .topTrailing) {
                    if owned && !out {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(palette.accent)
                            .padding(2)
                    }
                }

                Text(strings[item.nameKey])
                    .font(.game(11))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if owned {
                    Text(strings[out ? "decorate_stored" : "decorate_in_pond"])
                        .font(.game(11))
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                } else if FreeMode.enabled {
                    Text(strings["shop_free_tag"])
                        .font(.game(11, .bold))
                        .foregroundStyle(palette.accent)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 3) {
                        CoinIcon(size: 11)
                        Text("\(item.price)")
                            .font(.game(11, .bold))
                            .foregroundStyle(affordable ? palette.textPrimary : palette.textSecondary)
                    }
                }
            }
            .padding(6)
            .frame(width: 92)
            .background(palette.surface, in: shape)
            .overlay(shape.strokeBorder(selected ? palette.accent : .clear, lineWidth: 2))
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

private struct SkyChip: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let sky: PondCatalog.Weather
    let owned: Bool
    let selected: Bool
    let affordable: Bool
    let onTap: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        Button(action: onTap) {
            VStack(spacing: 3) {
                Canvas { ctx, size in
                    drawPondWater(&ctx, weatherId: sky.id, size: size, palette: palette, time: 0.5)
                    drawWeather(&ctx, id: sky.id, size: size, palette: palette, time: 0.5)
                }
                .frame(height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(strings[sky.nameKey])
                    .font(.game(11))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if selected {
                    Text(strings["shop_selected"])
                        .font(.game(11, .bold))
                        .foregroundStyle(palette.accent)
                } else if owned {
                    Text(strings["shop_select"])
                        .font(.game(11))
                        .foregroundStyle(palette.textSecondary)
                } else if FreeMode.enabled {
                    Text(strings["shop_free_tag"])
                        .font(.game(11, .bold))
                        .foregroundStyle(palette.accent)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 3) {
                        CoinIcon(size: 11)
                        Text("\(sky.price)")
                            .font(.game(11, .bold))
                            .foregroundStyle(affordable ? palette.textPrimary : palette.textSecondary)
                    }
                }
            }
            .padding(6)
            .frame(width: 104)
            .background(palette.surface, in: shape)
            .overlay(shape.strokeBorder(selected ? palette.accent : .clear, lineWidth: 2))
        }
        .buttonStyle(SquishyButtonStyle())
    }
}
