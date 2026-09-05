//
//  PondView.swift
//  PondPulse
//
//  My Pond: the screen the friends you own actually live on. Port of the
//  Android ui/PondScreen.kt.
//
//  It is the one place in PondPulse with no puzzle in it. Everything here is a
//  toy - the water answers a tap and the friends drift and get shoved around -
//  and the four games are opened from it rather than being the point of it. The
//  old Collection screen folded in as the roster panel: it showed the same
//  friends as a list with a small pond glued on top, which made the pond the
//  decorative half of a screen that should have been the pond.
//
//  It opens once three friends are owned. The gate is not a paywall - every
//  friend before that is earned by playing - it is the point at which the water
//  stops looking empty.
//

import SwiftUI

// MARK: - The water

/// Seconds a tap's rings take to fade out.
private let splashLife: CGFloat = 0.9

/// Water drag per second.
///
/// Friends used to wander, picking a new spot the moment they reached the last
/// one, and the pond was never still. They do not go anywhere on their own any
/// more: a friend floats exactly where it is until a tap shoves it, glides, and
/// stops wherever it ends up. It does not swim back to a home spot - where the
/// water leaves it *is* its place now.
///
/// The drag sets how far one shove carries: distance is roughly `push / drag`,
/// so the hardest shove (0.9) glides about a third of the pond and takes a
/// second and a half to run out.
private let pondDrag: CGFloat = 3.0

/// Below this, a friend is drifting so slowly it may as well be still.
private let restSpeed: CGFloat = 0.01

/// How close two friends get before they start easing apart.
private let personalSpace: CGFloat = 0.16

/// How hard they ease apart. Weak: this is politeness, not a force field.
private let separation: CGFloat = 1.6

/// Where a friend may swim: inside the banks, inset by half its own drawing.
///
/// The pond gained a shore when the Decorate screen arrived, and a duckling
/// paddling over the grass is a worse bug than one clipped by the screen edge
/// ever was. The insets are the shoreline's own numbers (`shoreTopAt` and
/// `shoreBottomAt` wave by ±0.013) plus room for a floater.
private let pondLeft: CGFloat = 0.14
private let pondRight: CGFloat = 0.86
private let pondTop: CGFloat = 0.23
private let pondBottom: CGFloat = 0.78

/// Where the lily pads float: four fixed, scattered spots, of which as many are
/// used as there are friends.
///
/// Spacing them evenly by cast size put three pads in a straight line across the
/// top of the water, which read as a row of buttons rather than as scenery - and
/// dropped one squarely underneath a friend.
private let padSpots = [
    CGPoint(x: 0.20, y: 0.30),
    CGPoint(x: 0.80, y: 0.38),
    CGPoint(x: 0.30, y: 0.70),
    CGPoint(x: 0.72, y: 0.75),
]

/// One resident, holding its own position and drift.
private final class PondFriend {
    let skinId: String
    var pos: CGPoint
    var vel = CGVector.zero

    init(skinId: String, start: CGPoint) {
        self.skinId = skinId
        self.pos = start
    }
}

private struct PondSplash {
    let at: CGPoint
    let born: CGFloat
}

/// Where the nth of `count` friends starts, spread across the open water.
private func startSlot(index: Int, count: Int) -> CGPoint {
    let columns = count <= 4 ? 2 : 3
    let row = index / columns
    let col = index % columns
    // Rows sit further apart than `personalSpace`, so a parked pond is one
    // nobody is still elbowing out of the way.
    return CGPoint(
        x: 0.28 + CGFloat(col) * (0.44 / CGFloat(max(columns - 1, 1))),
        y: 0.36 + CGFloat(row) * 0.18
    )
}

/// One clock for the whole scene. Every drifting, bobbing, blinking thing on
/// this screen reads its phase off it, so a pond with eight friends, seven
/// decorations and falling snow still costs exactly one frame callback.
private final class PondMotion {
    var time: CGFloat = 0
    var friends: [PondFriend] = []
    var splashes: [PondSplash] = []
    var lastTick: Date?
    /// The box the pond is drawn in, in canvas coordinates. The canvas itself
    /// runs under the status bar and the home indicator; this is the part of it
    /// the scene actually uses, and taps are read against it.
    var lastScene: CGRect = .zero

    /// Keeps the water in step with the cast without restarting anybody: a
    /// friend still in the pond keeps the position it had, so opening the picker
    /// and closing it again does not teleport everyone back to the middle.
    func sync(cast: [String]) {
        friends.removeAll { !cast.contains($0.skinId) }
        for (index, id) in cast.enumerated() where !friends.contains(where: { $0.skinId == id }) {
            friends.append(PondFriend(skinId: id, start: startSlot(index: index, count: cast.count)))
        }
        friends.sort { (cast.firstIndex(of: $0.skinId) ?? 0) < (cast.firstIndex(of: $1.skinId) ?? 0) }
    }

    func step(to now: Date) {
        let dt = min(CGFloat(now.timeIntervalSince(lastTick ?? now)), 0.05)
        lastTick = now
        guard dt > 0 else { return }
        time += dt
        stepPond(dt: dt)
        splashes.removeAll { time - $0.born > splashLife }
    }

    /// A tap pushes every friend away from it - the game's own rule, at play.
    func shove(at: CGPoint) {
        for friend in friends {
            let away = CGVector(dx: friend.pos.x - at.x, dy: friend.pos.y - at.y)
            let dist = sqrt(away.dx * away.dx + away.dy * away.dy)
            let dir = dist < 0.001 ? CGVector(dx: 1, dy: 0) : CGVector(dx: away.dx / dist, dy: away.dy / dist)
            // Close in, the shove is a shove; far out it is barely a nudge.
            let push = min(max(0.9 - dist * 1.1, 0.15), 0.9)
            friend.vel.dx += dir.dx * push
            friend.vel.dy += dir.dy * push
        }
    }

    /// One frame of pond life.
    ///
    /// A friend eases off anyone who drifts too close, coasts to a stop, and
    /// then simply floats there. Nothing pulls it anywhere: a tap is the only
    /// thing that ever moves the pond, and once the last shove has run out the
    /// whole simulation is still until the next one.
    private func stepPond(dt: CGFloat) {
        for friend in friends {
            // A gentle shove off anyone too close. Without it a single tap herds
            // the whole cast into one corner and they stay stacked there, which
            // looks less like a pond than like a bug.
            for other in friends where other !== friend {
                let gap = CGVector(dx: friend.pos.x - other.pos.x, dy: friend.pos.y - other.pos.y)
                let d = sqrt(gap.dx * gap.dx + gap.dy * gap.dy)
                if d >= 0.0001 && d <= personalSpace {
                    let force = (personalSpace - d) * separation * dt
                    friend.vel.dx += gap.dx / d * force
                    friend.vel.dy += gap.dy / d * force
                }
            }

            let keep = min(max(1 - pondDrag * dt, 0), 1)
            friend.vel.dx *= keep
            friend.vel.dy *= keep
            // Drag only ever approaches zero. Cutting the last of it off is what
            // turns the end of a glide into a stop rather than a permanent shiver.
            if sqrt(friend.vel.dx * friend.vel.dx + friend.vel.dy * friend.vel.dy) < restSpeed {
                friend.vel = .zero
            }
            var p = CGPoint(x: friend.pos.x + friend.vel.dx * dt, y: friend.pos.y + friend.vel.dy * dt)
            // The banks bounce rather than wrap: this pond has edges you can see,
            // and something vanishing off one side to reappear on the other would
            // read as a glitch rather than as a pond.
            if p.x < pondLeft { p.x = pondLeft; friend.vel.dx = -friend.vel.dx * 0.6 }
            if p.x > pondRight { p.x = pondRight; friend.vel.dx = -friend.vel.dx * 0.6 }
            if p.y < pondTop { p.y = pondTop; friend.vel.dy = -friend.vel.dy * 0.6 }
            if p.y > pondBottom { p.y = pondBottom; friend.vel.dy = -friend.vel.dy * 0.6 }
            friend.pos = p
        }
    }
}

// MARK: - The screen

private enum PondPanelKind: Hashable {
    case none, friends, games, roster
}

struct PondView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    @State private var panel: PondPanelKind = .none
    @State private var motion = PondMotion()

    /// Whether the pond is being looked at rather than used.
    ///
    /// The header and the four buttons are the only things on this screen that
    /// are not pond, and the screen is a pond you are meant to sit and watch.
    /// The toggle is a real button in both states - and the same button in the
    /// same corner in both - rather than a tap on the water: the water already
    /// answers a tap with a ripple, and a gesture that sometimes ripples and
    /// sometimes swallows the whole interface is a gesture nobody trusts.
    @State private var bare = false

    /// Where the safe area sits in the window - measured, not asked for.
    ///
    /// The canvas draws to the glass on purpose, and a `GeometryReader` inside
    /// `.ignoresSafeArea()` answers zero for `safeAreaInsets`: by then there is
    /// no safe area left for it to report. The probe below is laid out in the
    /// safe area like everything else on the screen, so where it lands in the
    /// window *is* the inset - and it is measured on every phone rather than
    /// guessed from a list of them.
    @State private var safeFrame: CGRect = .zero

    var body: some View {
        let cast = vm.pondCast()
        // Asked of the view model rather than of the owned set: a decoration
        // won from a golden pond is never written to that set, so this used to
        // draw the Decorate screen's pond minus every decoration the player had
        // *earned*. Sorted down the screen so a thing lower on the bank stands
        // in front of a thing higher up it - with thirty decorations, a bench
        // behind the fence it is in front of is the first thing anyone notices.
        let decorOwned = PondCatalog.decor
            .filter { vm.isDecorOwned($0) && !vm.decorStored.contains($0.id) }
            .sorted { (vm.decorSpots[$0.id] ?? $0.at).y < (vm.decorSpots[$1.id] ?? $1.at).y }

        ZStack {
            pondCanvas(cast: cast, decorOwned: decorOwned)

            Color.clear
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { safeFrame = $0 }
                .allowsHitTesting(false)

            // A soft scrim under the bars. The pond grew a bank the player can
            // put a dock or a willow on, and white-on-grass is not text you can
            // read.
            //
            // It runs to the glass at both ends, not just the bottom: the scene
            // steps back from the notch and the strip behind it is bare bank, so
            // a scrim that started at the safe area drew a hard line across the
            // grass exactly where the pond was trying not to have one.
            if !bare {
            VStack {
                // Full strength as far down as the status bar, then the same
                // 96-point fade the header has always sat in: stretching the
                // fade over the notch instead would have thinned it exactly
                // where the title is.
                let hold = max(safeFrame.minY, 0)
                LinearGradient(
                    stops: [
                        .init(color: palette.background.opacity(0.65), location: 0),
                        .init(color: palette.background.opacity(0.65), location: hold / (hold + 96)),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: hold + 96)
                Spacer()
                LinearGradient(
                    colors: [.clear, palette.background.opacity(0.65)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 132)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .transition(.opacity)
            }

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    if bare {
                        Spacer()
                    } else {
                        RoundIconButton(systemName: "chevron.backward") { vm.back() }
                        Text(strings["pond_title"])
                            .font(.game(22, .bold))
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                    }
                    // Always here, always the same size, in the same corner: the
                    // way back out of a screen with nothing else on it has to be
                    // the thing you already know where to find.
                    RoundIconButton(
                        systemName: bare
                            ? "arrow.down.right.and.arrow.up.left"
                            : "arrow.up.left.and.arrow.down.right",
                        action: {
                            panel = .none
                            bare.toggle()
                            Haptics.tick(enabled: vm.haptics)
                        },
                        accessibilityLabel: strings[bare ? "pond_show_ui" : "pond_hide_ui"]
                    )
                    if !bare {
                        CoinChip(coins: vm.coins) { vm.navigate(.shop) }
                    }
                }
                Spacer()
                if !bare {
                HStack(spacing: 8) {
                    PondAction(icon: "pawprint.fill", label: strings["pond_friends"]) {
                        panel = .friends
                    }
                    PondAction(icon: "leaf.fill", label: strings["pond_decorate"]) {
                        vm.navigate(.decorate)
                    }
                    // What the week has left to pay, on the button rather than
                    // only inside the sheet behind it: the games are worth
                    // opening because they still pay, and a player cannot want
                    // a number they have to go and look for.
                    PondAction(
                        icon: "gamecontroller.fill",
                        label: strings["pond_games"],
                        badge: pondWeekLeft > 0 ? "\(pondWeekLeft)" : nil
                    ) {
                        panel = .games
                    }
                    PondAction(icon: "rectangle.grid.2x2.fill", label: strings["pond_roster"]) {
                        panel = .roster
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            PondSheet(visible: panel != .none, onClose: { panel = .none }) {
                switch panel {
                case .friends: FriendsPanel(vm: vm, cast: cast)
                case .games: GamesPanel(vm: vm) { panel = .none }
                case .roster: RosterPanel(vm: vm)
                case .none: EmptyView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: panel)
        .animation(.easeInOut(duration: 0.28), value: bare)
    }

    /// Coins the pond's games can still pay out this week.
    private var pondWeekLeft: Int {
        max(CoinBank.pondWeeklyCap - vm.pondEarnedThisWeek, 0)
    }

    private func pondCanvas(cast: [String], decorOwned: [PondCatalog.Decor]) -> some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, canvas in
                // The canvas runs to the glass; the scene inside it steps back
                // from the notch and the home indicator, and the strips it
                // leaves are painted in the bank's own colour so the grass still
                // reaches both edges.
                let measured = safeFrame.height > 0
                let scene = pondSceneRect(
                    canvas: canvas,
                    top: measured ? safeFrame.minY : 0,
                    bottom: measured ? max(canvas.height - safeFrame.maxY, 0) : 0
                )
                motion.lastScene = scene
                drawPondBleed(&ctx, canvas: canvas, scene: scene, shoreId: vm.pondShore, palette: palette)
                // Kept unshifted for the weather, which is sky and belongs to
                // the whole screen rather than to the pond in it.
                var sky = ctx
                ctx.translateBy(x: scene.minX, y: scene.minY)

                let size = scene.size
                motion.sync(cast: cast)
                motion.step(to: timeline.date)
                let time = motion.time
                let w = size.width
                let h = size.height

                drawPondBasin(&ctx, weatherId: vm.pondWeather, size: size, palette: palette, time: time,
                              waterId: vm.pondWater, shoreId: vm.pondShore)

                for item in decorOwned {
                    let at = decorSpot(
                        zone: item.zone,
                        at: vm.decorSpots[item.id] ?? item.at,
                        scale: item.scale, in: size
                    )
                    let side = w * item.scale
                    // Only what floats bobs. A bench that breathed would be
                    // worse than a bench that did not move at all.
                    let bob = item.zone == .water ? sin(time * 0.9 + at.x * 6) * h * 0.004 : 0
                    drawDecor(
                        &ctx, id: item.id,
                        rect: CGRect(x: w * at.x - side / 2, y: h * at.y - side / 2 + bob,
                                     width: side, height: side),
                        palette: palette, phase: time
                    )
                }

                // The equipped pad, up to one per friend, so everybody has
                // somewhere to be without the water turning into a car park.
                let padSide = w * 0.13
                for i in 0..<min(motion.friends.count, padSpots.count) {
                    let at = padSpots[i]
                    drawPadStyle(
                        &ctx, padId: vm.padId,
                        rect: CGRect(
                            x: w * at.x - padSide / 2,
                            y: h * at.y - padSide / 2 + sin(time + CGFloat(i)) * h * 0.003,
                            width: padSide, height: padSide
                        ),
                        palette: palette, ring: nil
                    )
                }

                for fx in motion.splashes {
                    drawSplashRings(
                        &ctx,
                        at: CGPoint(x: fx.at.x * w, y: fx.at.y * h),
                        progress: min(max((time - fx.born) / splashLife, 0), 1),
                        size: size, palette: palette
                    )
                }

                let side = w * 0.15
                for (index, friend) in motion.friends.enumerated() {
                    let x = friend.pos.x * w
                    let y = friend.pos.y * h + sin(time * 1.6 + CGFloat(index) * 2.1) * h * 0.005
                    ctx.fill(
                        circle(CGPoint(x: x, y: y + side * 0.16), side * 0.6),
                        with: .color(palette.ripple.opacity(0.10))
                    )
                    drawFloaterSkin(
                        &ctx, skinId: friend.skinId,
                        rect: CGRect(x: x - side / 2, y: y - side / 2, width: side, height: side),
                        palette: palette, color: nil
                    )
                }

                drawWeather(&sky, id: vm.pondWeather, size: canvas, palette: palette, time: time)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { point in
            let scene = motion.lastScene
            guard scene.width > 0, scene.height > 0 else { return }
            // A tap on the strip behind the notch still lands in the pond, at
            // the nearest place there is water to splash.
            let at = CGPoint(
                x: min(max((point.x - scene.minX) / scene.width, 0), 1),
                y: min(max((point.y - scene.minY) / scene.height, 0), 1)
            )
            motion.splashes.append(PondSplash(at: at, born: motion.time))
            motion.shove(at: at)
            Haptics.tick(enabled: vm.haptics)
            vm.noteQuest(.pondTaps)
        }
    }
}

// MARK: - The HUD

private struct PondAction: View {
    @Environment(\.palette) private var palette
    let icon: String
    let label: String
    var badge: String?
    var enabled = true
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(enabled ? palette.accent : palette.textSecondary.opacity(0.5))
                    .overlay(alignment: .topTrailing) {
                        if let badge {
                            Text(badge)
                                .font(.game(9, .bold))
                                .foregroundStyle(PondPalette.onAccent)
                                .padding(.horizontal, 4)
                                .background(palette.accent, in: Capsule())
                                .offset(x: 10, y: -6)
                        }
                    }
                Text(label)
                    .font(.game(11, .semibold))
                    .foregroundStyle(enabled ? palette.textPrimary : palette.textSecondary.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(palette.surface.opacity(0.88), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(SquishyButtonStyle())
        .disabled(!enabled)
    }
}

/// A panel over the water: scrim, rounded surface, and whatever is inside it.
struct PondSheet<Content: View>: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let visible: Bool
    let onClose: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            if visible {
                palette.background.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)
                    .transition(.opacity)

                VStack {
                    Spacer()
                    ZStack(alignment: .topTrailing) {
                        content
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(palette.textSecondary)
                                .padding(14)
                        }
                        .buttonStyle(.plain)
                    }
                    // Never the whole screen: the pond stays visible above the
                    // panel, which is what keeps a purchase feeling like a
                    // change to the thing behind it.
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 460, alignment: .top)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous)
                            .fill(palette.surfaceHigh)
                    )
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
            }
        }
    }
}

struct PanelTitle: View {
    @Environment(\.palette) private var palette
    let text: String
    var subtitle: String?
    var emphasis = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text)
                .font(.game(17, .bold))
                .foregroundStyle(palette.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.game(12, emphasis ? .bold : .regular))
                    .foregroundStyle(emphasis ? palette.accent : palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 20)
        .padding(.trailing, 52)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }
}

struct PanelSection: View {
    @Environment(\.palette) private var palette
    let text: String

    var body: some View {
        Text(text)
            .font(.game(14, .bold))
            .foregroundStyle(palette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
}

// MARK: - The panels

/// Who is in the water, and how many may be.
///
/// Tapping a friend puts them in or takes them out. The pond fills itself when
/// nothing has ever been chosen, so this panel is somewhere a player goes to
/// change their mind rather than somewhere they must go first.
///
/// A full pond refuses rather than swapping. It used to drop whoever had been in
/// the water longest to make room, which from the outside looked like a friend
/// being evicted at random by a tap that said nothing about them - the one thing
/// a screen whose whole job is arranging things must never do.
private struct FriendsPanel: View {
    @ObservedObject var vm: AppViewModel
    let cast: [String]
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    /// What the panel says back when a tap cannot do what it looks like it
    /// should. Clears itself, so it never becomes part of the furniture.
    @State private var notice: String?

    var body: some View {
        let ownedIds = vm.ownedSkinIds()
        let slots = vm.pondSlots
        let nextSlotPrice = CoinBank.slotPrice(slots: slots)

        VStack(spacing: 0) {
            PanelTitle(
                text: strings["pond_friends"],
                subtitle: notice.map { strings[$0] } ?? strings["pond_seats", cast.count, slots],
                emphasis: notice != nil
            )
            ScrollView {
                LazyVStack(spacing: 8) {
                    tileRows(ownedIds) { id in
                        let inPond = cast.contains(id)
                        let skin = Catalog.skinById(id)
                        RosterTile(
                            name: strings[skin.nameKey],
                            lockLabel: nil,
                            selected: inPond,
                            onTap: {
                                if inPond && cast.count > 1 {
                                    vm.setPondFriends(cast.filter { $0 != id })
                                } else if inPond {
                                    show("pond_last_friend")
                                } else if cast.count < slots {
                                    vm.setPondFriends(cast + [id])
                                } else {
                                    show("pond_seats_taken")
                                }
                            }
                        ) { SkinPreview(skinId: id).aspectRatio(1, contentMode: .fit) }
                    }
                    if let nextSlotPrice {
                        BuyRow(
                            title: strings["pond_buy_seat", slots + 1],
                            desc: strings["pond_buy_seat_desc", CoinBank.maxSlots],
                            price: nextSlotPrice,
                            owned: false,
                            affordable: vm.canAfford(nextSlotPrice),
                            onBuy: { vm.buyPondSlot() }
                        )
                    } else {
                        Text(strings["pond_seats_full", CoinBank.maxSlots])
                            .font(.game(12))
                            .foregroundStyle(palette.textSecondary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .frame(maxHeight: 300)
        }
    }

    private func show(_ key: String) {
        notice = key
        Task {
            try? await Task.sleep(for: .seconds(2.6))
            if notice == key { notice = nil }
        }
    }
}

/// The four games, with what each has ever scored and what the week has left.
private struct GamesPanel: View {
    @ObservedObject var vm: AppViewModel
    let onPlay: () -> Void
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        let left = max(CoinBank.pondWeeklyCap - vm.pondEarnedThisWeek, 0)
        VStack(spacing: 0) {
            PanelTitle(
                text: strings["pond_games"],
                subtitle: strings["pond_week_left", left, CoinBank.pondWeeklyCap]
            )
            // Scrolls because the blurbs are three lines each and a large
            // accessibility font turns four cards into five cards' worth.
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(PondCatalog.games) { game in
                        Button {
                            onPlay()
                            vm.navigate(.pondGame(gameId: game.id))
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(strings[game.nameKey])
                                        .font(.game(15, .bold))
                                        .foregroundStyle(palette.textPrimary)
                                    Text(strings[game.blurbKey])
                                        .font(.game(12))
                                        .foregroundStyle(palette.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Text(strings["pond_best", vm.miniBests[game.id] ?? 0])
                                    .font(.game(12, .semibold))
                                    .foregroundStyle(palette.accent)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

/// The whole roster: every friend and pad in the game, with the locked ones
/// dimmed and labelled with what earns them.
///
/// This is what the Collection screen was, kept because it answers "what is
/// next" - and moved in here because it was only ever half a screen.
private struct RosterPanel: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        let ownedSkins = Catalog.skins.count { vm.isOwned($0.unlock, productId: Catalog.skinProductId($0.id)) }
        let ownedPads = Catalog.pads.count { vm.isOwned($0.unlock, productId: Catalog.padProductId($0.id)) }

        VStack(spacing: 0) {
            PanelTitle(
                text: strings["pond_roster"],
                subtitle: strings["collection_tally", ownedSkins, Catalog.skins.count, ownedPads, Catalog.pads.count]
            )
            ScrollView {
                LazyVStack(spacing: 8) {
                    // Seventy-three friends in one unbroken grid says nothing
                    // about how any of them is got. Cut along the same ladder
                    // the shop's shelf uses, so the two screens describe the
                    // collection the same way.
                    ForEach(friendGroups(), id: \.titleKey) { group in
                        if !group.skins.isEmpty {
                            PanelSection(text: strings[group.titleKey])
                            tileRows(group.skins.map(\.id)) { id in
                                let skin = Catalog.skinById(id)
                                let can = vm.isOwned(skin.unlock, productId: Catalog.skinProductId(skin.id))
                                RosterTile(
                                    name: strings[skin.nameKey],
                                    lockLabel: can ? nil : lockLabel(skin.unlock, strings),
                                    selected: skin.id == vm.skinId,
                                    onTap: { if can { vm.selectSkin(skin.id) } }
                                ) { SkinPreview(skinId: skin.id).aspectRatio(1, contentMode: .fit) }
                            }
                        }
                    }
                    PanelSection(text: strings["shop_section_pads"])
                    tileRows(Catalog.pads.map(\.id)) { id in
                        let pad = Catalog.padById(id)
                        let can = vm.isOwned(pad.unlock, productId: Catalog.padProductId(pad.id))
                        RosterTile(
                            name: strings[pad.nameKey],
                            lockLabel: can ? nil : lockLabel(pad.unlock, strings),
                            selected: pad.id == vm.padId,
                            onTap: { if can { vm.selectPad(pad.id) } }
                        ) { PadPreview(padId: pad.id).aspectRatio(1, contentMode: .fit) }
                    }
                    Button(strings["collection_open_shop"]) { vm.navigate(.shop) }
                        .font(.game(15, .bold))
                        .foregroundStyle(palette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 340)
        }
    }
}

/// One heading in the roster, and the friends under it.
private struct FriendGroup {
    let titleKey: String
    let skins: [SkinItem]
}

/// The roster's sections, in the order the ladder puts them.
///
/// The first heading used to be "Earned by playing" and held the level prizes as
/// well as the free pair. Nothing is pinned to a level number any more, so what
/// is left under it is what the game opens with, and it says so.
private func friendGroups() -> [FriendGroup] {
    func group(_ key: String, _ keep: (Unlock) -> Bool) -> FriendGroup {
        FriendGroup(titleKey: key, skins: Catalog.skins.filter { keep($0.unlock) })
    }
    return [
        group("friends_section_free", \.isFree),
        group("friends_section_golden") { $0.rewardBonusPonds != nil },
        group("friends_section_daily") { $0.rewardStreak != nil },
        group("friends_section_themes") { $0.themeFriendOf != nil },
        group("friends_section_coins") { $0.coinPrice != nil },
        group("friends_section_special", \.isMoney),
        group("friends_section_premium", \.isPremium),
    ]
}

/// What a locked roster square says instead of a price.
private func lockLabel(_ unlock: Unlock, _ strings: Strings) -> String {
    switch unlock {
    case .bonusReward(let count): return strings["bonus_locked_shop", count]
    case .streakReward(let days): return strings["collection_streak_lock", days]
    case .premium: return strings["collection_premium_lock"]
    case .themeFriend(let themeId):
        let name = Catalog.themes.first { $0.id == themeId }?.nameKey ?? ""
        return strings["friends_theme_lock", strings[name]]
    // A special friend falls through to "in the shop" like any other purchase:
    // the roster has no StoreKit prices to hand, and a hard-coded "$0.99" would
    // be wrong in every country that does not use dollars.
    case .money: return strings["collection_shop_lock"]
    default: return strings["collection_shop_lock"]
    }
}

/// Four to a row, the shape both roster grids use.
@ViewBuilder
private func tileRows<Tile: View>(
    _ ids: [String], @ViewBuilder tile: @escaping (String) -> Tile
) -> some View {
    let rows = stride(from: 0, to: ids.count, by: 4).map { Array(ids[$0..<min($0 + 4, ids.count)]) }
    ForEach(Array(rows.enumerated()), id: \.offset) { _, rowIds in
        HStack(alignment: .top, spacing: 8) {
            ForEach(rowIds, id: \.self) { id in
                tile(id).frame(maxWidth: .infinity)
            }
            ForEach(0..<(4 - rowIds.count), id: \.self) { _ in
                Color.clear.frame(maxWidth: .infinity)
            }
        }
    }
}

/// One square in a roster or picker grid.
struct RosterTile<Preview: View>: View {
    @Environment(\.palette) private var palette
    let name: String
    let lockLabel: String?
    let selected: Bool
    let onTap: () -> Void
    @ViewBuilder let preview: Preview

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                preview
                    .overlay {
                        if lockLabel != nil {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(palette.background.opacity(0.6))
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(palette.textPrimary.opacity(0.85))
                        }
                    }
                Text(name)
                    .font(.game(10, .semibold))
                    .foregroundStyle(lockLabel == nil ? palette.textPrimary : palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if let lockLabel {
                    Text(lockLabel)
                        .font(.game(9))
                        .foregroundStyle(palette.textSecondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? palette.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(SquishyButtonStyle())
        .disabled(lockLabel != nil)
    }
}

/// A priced row: buy it, or select it once it is yours.
struct BuyRow: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let title: String
    var desc: String?
    let price: Int
    let owned: Bool
    let affordable: Bool
    var selected = false
    var onBuy: () -> Void = {}
    var onSelect: (() -> Void)?

    var body: some View {
        Button {
            if owned { onSelect?() } else { onBuy() }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.game(15, .bold))
                        .foregroundStyle(palette.textPrimary)
                    if let desc {
                        Text(desc)
                            .font(.game(12))
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
                if selected {
                    Text(strings["shop_selected"])
                        .font(.game(14, .bold))
                        .foregroundStyle(palette.accent)
                } else if owned {
                    Text(strings["shop_select"])
                        .font(.game(14))
                        .foregroundStyle(palette.textSecondary)
                } else {
                    CoinPrice(price: price, affordable: affordable)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? palette.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(SquishyButtonStyle())
        .disabled(owned ? (onSelect == nil || selected) : !affordable)
    }
}
