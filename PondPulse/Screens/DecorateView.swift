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

/// The five things the tray can be showing.
///
/// It was one row of decorations and a Sky tab, which was fine for sixteen
/// things and is not fine for thirty plus twelve surfaces - a single scrolling
/// strip of forty-two chips is a strip nobody reaches the end of. Arranging the
/// pond is five separate decisions, so it is five tabs, each with an SF Symbol.
/// Which saved pond you are in was a sixth, and it is not here: saving and
/// switching whole ponds is My Pond's own Layouts panel, one screen up, because
/// it is a thing you do *to* the pond rather than a thing you arrange in it.
private enum DecorTab: String, Hashable, CaseIterable, Identifiable {
    case decor, water, shore, sky, friends

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .decor: return "pond_section_decor"
        case .water: return "pond_section_water"
        case .shore: return "pond_section_shore"
        case .sky: return "pond_section_sky"
        case .friends: return "pond_section_friends"
        }
    }

    var symbol: String {
        switch self {
        case .decor: return "leaf.fill"
        case .water: return "water.waves"
        case .shore: return "mountain.2.fill"
        case .sky: return "cloud.sun.fill"
        case .friends: return "pawprint.fill"
        }
    }
}

private enum LegacyDecorTab: Hashable {
    case decor, sky
}

/// What the decorations grid is showing.
///
/// Filters rather than a search box: there are thirty of them, they have
/// pictures, and typing "hammock" is slower than tapping "Shore".
private enum DecorFilter: String, Hashable, CaseIterable, Identifiable {
    case all, water, shore, owned, locked

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .all: return "decorate_filter_all"
        case .water: return "decorate_filter_water"
        case .shore: return "decorate_filter_shore"
        case .owned: return "decorate_filter_owned"
        case .locked: return "decorate_filter_locked"
        }
    }
}

/// True if `at` lands on `item` drawn at `spot`, both in pond fractions.
private func hits(_ item: PondCatalog.Decor, spot: CGPoint, at: CGPoint, aspect: CGFloat) -> Bool {
    let halfX = item.scale * 0.55
    let halfY = item.scale * 0.55 / aspect
    return abs(at.x - spot.x) <= halfX && abs(at.y - spot.y) <= halfY
}

/// Pulls `at` back to somewhere `item` is allowed to be, in a pond of this
/// shape - `decorSpot`, which My Pond draws through as well, so a thing put
/// somewhere here is somewhere it fits there too.
///
/// Applied while the finger is down rather than on release so the rule shows
/// itself: a dock dragged out over the water follows the finger sideways but
/// stays glued to the bank, which says "not there" far better than a message
/// would.
private func clampToZone(_ item: PondCatalog.Decor, _ at: CGPoint, _ size: CGSize) -> CGPoint {
    decorSpot(zone: item.zone, at: at, scale: item.scale, in: size)
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

    /// What the decorations grid is filtered to, and whether it is open taller.
    @State private var filter: DecorFilter = .all
    @State private var gridExpanded = false

    /// How wide the decoration shelf actually is, measured rather than assumed.
    ///
    /// The chips are square art with two lines under it, so a chip is as tall as
    /// a column is wide - and a column is only as wide as the screen allows. A
    /// fixed shelf height was right on the wide screens it was written on and cut
    /// the price line off the bottom of every chip on a 4.7" phone, which is the
    /// one number on the chip a player is shopping by.
    @State private var shelfWidth: CGFloat = 0

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

    /// Where `item` is drawn, ring, hit box and all.
    ///
    /// Everything goes through `clampToZone`, not just what is being dragged:
    /// the catalogue's own anchors put the pier and the hammock half off the
    /// top and bottom of a tall screen, and a decoration nobody has ever
    /// touched should not be the one that is cut in half.
    private func spotOf(_ item: PondCatalog.Decor) -> CGPoint {
        let raw: CGPoint
        if item.id == dragId {
            raw = dragAt
        } else if !vm.isDecorOwned(item) {
            raw = ghostAt ?? item.at
        } else {
            raw = justPlaced[item.id] ?? vm.decorSpots[item.id] ?? item.at
        }
        return clampToZone(item, raw, motion.lastSize)
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

                drawPondBasin(&ctx, weatherId: vm.pondWeather, size: size, palette: palette, time: time,
                              waterId: vm.pondWater, shoreId: vm.pondShore)

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
                    dragAt = clampToZone(item, at, motion.lastSize)
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

    // MARK: Water, shore and sky

    /// One strip of buyable surfaces - the water or the bank.
    ///
    /// Both are the same shape of decision (pick one of six, some of them
    /// bought) so they are one component, and each passes its own swatch.
    @ViewBuilder
    private func surfaceStrip<Swatch: View>(
        _ items: [PondCatalog.Surface],
        current: String,
        productId: @escaping (String) -> String,
        @ViewBuilder swatch: @escaping (String) -> Swatch,
        onPick: @escaping (String) -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { surface in
                    let pid = productId(surface.id)
                    let owned = vm.isSurfaceOwned(surface, productId: pid)
                    SurfaceChip(
                        nameKey: surface.nameKey,
                        price: surface.price,
                        owned: owned,
                        selected: owned && surface.id == current,
                        affordable: vm.canAfford(surface.price),
                        swatch: { swatch(surface.id) }
                    ) {
                        if owned {
                            onPick(surface.id)
                        } else if vm.canAfford(surface.price) {
                            if vm.buyWithCoins(price: surface.price, productId: pid) {
                                onPick(surface.id)
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

    // MARK: Who is swimming

    /// The cast, inside Decorate.
    ///
    /// The same rule My Pond's friends panel follows: a full pond refuses
    /// rather than swapping, because a tap that evicts somebody unnamed is the
    /// one thing a screen about arranging things must never do.
    private var castStrip: some View {
        let roster = vm.ownedSkinIds()
        let cast = vm.pondCast()
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(strings["decorate_friends_hint"])
                    .font(.game(12))
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text(strings["pond_seats", cast.count, vm.pondSlots])
                    .font(.game(12, .bold))
                    .foregroundStyle(palette.accent)
                    .fixedSize()
            }
            .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(roster, id: \.self) { id in
                        let inPond = cast.contains(id)
                        Button {
                            if inPond, cast.count > 1 {
                                vm.setPondFriends(cast.filter { $0 != id })
                            } else if inPond {
                                notice = "pond_last_friend"
                            } else if cast.count < vm.pondSlots {
                                vm.setPondFriends(cast + [id])
                            } else {
                                notice = "pond_seats_taken"
                            }
                        } label: {
                            VStack(spacing: 4) {
                                SkinPreview(skinId: id).aspectRatio(1, contentMode: .fit)
                                Text(strings[Catalog.skins.first { $0.id == id }?.nameKey ?? ""])
                                    .font(.game(11))
                                    .foregroundStyle(palette.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .padding(6)
                            .frame(width: 84)
                            .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(inPond ? palette.accent : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }

    // MARK: The tray

    private var tray: some View {
        VStack(spacing: 0) {
            // Five tabs do not fit across a small phone, so the row scrolls
            // rather than shrinking the labels to nothing.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DecorTab.allCases) { entry in
                        TrayTab(
                            text: strings[entry.titleKey],
                            symbol: entry.symbol,
                            selected: tab == entry
                        ) {
                            tab = entry
                            selected = nil
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            switch tab {
            case .decor:
                decorGrid
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

            case .water:
                surfaceStrip(PondCatalog.waters, current: vm.pondWater,
                             productId: PondCatalog.waterProductId) { id in
                    WaterSwatch(waterId: id, weatherId: vm.pondWeather)
                } onPick: { vm.setPondWater($0) }

            case .shore:
                surfaceStrip(PondCatalog.shores, current: vm.pondShore,
                             productId: PondCatalog.shoreProductId) { id in
                    ShoreSwatch(shoreId: id, waterId: vm.pondWater, weatherId: vm.pondWeather)
                } onPick: { vm.setPondShore($0) }

            case .friends:
                castStrip
            }
        }
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(
            palette.surfaceHigh,
            in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22, style: .continuous)
        )
    }

    /// The decorations, as a filtered grid that opens taller.
    ///
    /// It was one sideways strip of thirty, which is four chips seen at a time
    /// and twenty-six behind a swipe that nothing on the screen advertises.
    /// Collapsed this is one row with a sliver of the next - about as much as
    /// can sit under a pond without squashing it - and the chevron opens it to
    /// two and a half, which on most phones is the whole shelf in two flicks.
    /// The sliver is the only thing that says the grid scrolls; cutting a card
    /// in half instead reads as a clipping bug.
    @ViewBuilder
    private var decorGrid: some View {
        let ownedCount = PondCatalog.decor.count { vm.isDecorOwned($0) }
        let shown = PondCatalog.decor.filter { item in
            switch filter {
            case .all: return true
            case .water: return item.zone == .water
            case .shore: return item.zone == .shore
            case .owned: return vm.isDecorOwned(item)
            case .locked: return !vm.isDecorOwned(item)
            }
        }

        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(DecorFilter.allCases) { entry in
                        FilterChip(text: strings[entry.titleKey], selected: filter == entry) {
                            filter = entry
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
            Text(strings["decorate_owned_count", ownedCount, PondCatalog.decor.count])
                .font(.game(11))
                .foregroundStyle(palette.textSecondary)
                .fixedSize()
            Button {
                gridExpanded.toggle()
            } label: {
                Image(systemName: gridExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel(strings[gridExpanded ? "decorate_collapse" : "decorate_expand"])
        }
        .padding(.horizontal, 14)

        if shown.isEmpty {
            Text(strings["decorate_filter_empty"])
                .font(.game(12))
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else {
            let side = Self.chipSide(in: shelfWidth)
            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed(side), spacing: Self.chipSpacing),
                        count: Self.chipColumns(in: shelfWidth)
                    ),
                    spacing: Self.chipSpacing
                ) {
                    ForEach(shown) { item in
                        DecorChip(
                            item: item,
                            side: side,
                            owned: vm.isDecorOwned(item),
                            out: vm.decorStored.contains(item.id),
                            selected: selected == item.id,
                            affordable: vm.canAfford(item.price)
                        ) {
                            selected = selected == item.id ? nil : item.id
                        }
                    }
                }
                .padding(.horizontal, Self.shelfInset)
                .padding(.vertical, 6)
            }
            .frame(height: Self.shelfHeight(side: side, rows: gridExpanded ? 2 : 1))
            .background {
                GeometryReader { geo in
                    Color.clear.onAppear { shelfWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, width in shelfWidth = width }
                }
            }
            .animation(.easeInOut(duration: 0.18), value: gridExpanded)
        }
    }

    // MARK: The shelf's arithmetic
    //
    // Kept together and used by both the grid and its height, so the two can
    // never disagree about how big a chip is.

    /// Smallest a chip may be before a column is dropped.
    private static let chipMinimum: CGFloat = 84
    private static let chipSpacing: CGFloat = 8
    private static let shelfInset: CGFloat = 14

    /// Name and price under the art, plus the gaps around them. Scaled with the
    /// text it has to hold, for the same reason the shelf is measured at all.
    private static var chipCaption: CGFloat { scaledGameSize(40) }

    private static func chipColumns(in width: CGFloat) -> Int {
        let usable = max(width - shelfInset * 2, chipMinimum)
        return max(Int((usable + chipSpacing) / (chipMinimum + chipSpacing)), 1)
    }

    private static func chipSide(in width: CGFloat) -> CGFloat {
        let usable = max(width - shelfInset * 2, chipMinimum)
        let columns = CGFloat(chipColumns(in: width))
        return max((usable - chipSpacing * (columns - 1)) / columns, chipMinimum)
    }

    /// Tall enough for `rows` whole chips, whatever the phone.
    private static func shelfHeight(side: CGFloat, rows: Int) -> CGFloat {
        let row = side + chipCaption
        return row * CGFloat(rows) + chipSpacing * CGFloat(rows - 1) + 12
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
    var symbol: String?
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
                }
                Text(text).font(.game(14, .bold))
            }
            .foregroundStyle(selected ? PondPalette.onAccent : palette.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(selected ? palette.accent : palette.surface, in: Capsule())
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// A smaller tab, for the filters over the decorations grid.
///
/// Tinted and outlined rather than filled when selected: a row of filters sits
/// directly under a row of tabs, and two rows of solid accent capsules read as
/// one control with two selected things in it.
private struct FilterChip: View {
    @Environment(\.palette) private var palette
    let text: String
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.game(11, .bold))
                .foregroundStyle(selected ? palette.accent : palette.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    selected ? palette.accent.opacity(0.22) : palette.surface,
                    in: Capsule()
                )
                .overlay(
                    Capsule().strokeBorder(selected ? palette.accent : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// Open water in the candidate surface, in the light this pond is in.
///
/// It draws the water but **not** the sky's overlay. First cut drew both, on
/// the reasonable-sounding argument that a chip should show your own pond;
/// under a sunset that made all six waters the same murky violet, because the
/// overlay is opaque enough to *be* the picture. Only the sky chips draw it.
private struct WaterSwatch: View {
    let waterId: String
    let weatherId: String
    @Environment(\.palette) private var palette

    var body: some View {
        Canvas { ctx, size in
            drawPondWater(&ctx, weatherId: weatherId, size: size, palette: palette,
                          time: 0.5, waterId: waterId)
        }
    }
}

/// A slice of bank and water, so a shore is judged against its own shoreline.
private struct ShoreSwatch: View {
    let shoreId: String
    let waterId: String
    let weatherId: String
    @Environment(\.palette) private var palette

    var body: some View {
        Canvas { ctx, size in
            drawPondBasin(&ctx, weatherId: weatherId, size: size, palette: palette,
                          time: 0.5, waterId: waterId, shoreId: shoreId)
        }
    }
}

private struct DecorChip: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let item: PondCatalog.Decor
    /// The square the art is drawn in. Passed in so the chip and the shelf that
    /// has to be tall enough for it are working from the same number.
    let side: CGFloat
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
                .frame(width: side, height: side)
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
            .frame(maxWidth: .infinity)
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


/// A surface chip: a live slice of the pond, its name, and its price.
private struct SurfaceChip<Swatch: View>: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let nameKey: String
    let price: Int
    let owned: Bool
    let selected: Bool
    let affordable: Bool
    @ViewBuilder let swatch: Swatch
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                swatch
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(strings[nameKey])
                    .font(.game(11))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if selected {
                    Text(strings["shop_selected"]).font(.game(11, .bold)).foregroundStyle(palette.accent)
                } else if owned {
                    Text(strings["shop_select"]).font(.game(11)).foregroundStyle(palette.textSecondary)
                } else {
                    CoinPrice(price: price, affordable: affordable)
                }
            }
            .padding(6)
            .frame(width: 104)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? palette.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

