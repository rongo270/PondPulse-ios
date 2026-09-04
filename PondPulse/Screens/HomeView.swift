//
//  HomeView.swift
//  PondPulse
//
//  The menu on top of a living pond: drifting ripples, bobbing lily pads, the
//  player's own floater, and a turtle sunning in the corner. The water is
//  alive - every tap splashes and shoves the ducks away, they glide almost
//  without friction, and swimming off one side brings them back on the other.
//  Park the duck on the top-left pad for five quiet seconds and a red
//  duckling hatches beside it. None of this is saved. Port of HomeScreen.kt.
//

import SwiftUI

/// Water drag per second - small on purpose, so a shove glides a long way.
private let duckFriction: CGFloat = 0.7

/// How far past an edge (in width fractions) a duck swims before wrapping.
private let duckWrap: CGFloat = 0.12

/// Where the top-left home pad floats, in canvas fractions.
private let topLeftPad = CGPoint(x: 0.13, y: 0.15)

/// Seconds the duck must nap on that pad before the second one hatches.
private let hatchRestSeconds: CGFloat = 5

/// The far bank before the Splash button has been measured. Deliberately
/// shallow - a first frame that keeps the ducks too high reads as a pond, while
/// one that lets them under the menu is the bug this fixes.
private let defaultWaterFloor: CGFloat = 0.60

/// Friends owned before the pond opens; mirrors the check in `AppViewModel`.
private let pondMinFriends = 3

/// The one gap the menu block uses, between tiles and between the two rows.
private let menuGap: CGFloat = 12

/// The lowest a duck's centre may float, as a fraction of the canvas height:
/// the top of the Splash button, lifted by the duck's own shadow - the widest
/// thing drawn for it - and by the swell it bobs on, so the whole bird stays in
/// water.
private func duckFloor(canvas: CGSize, waterFloor: CGFloat) -> CGFloat {
    let clearance = canvas.height > 0
        ? canvas.width * 0.15 * 0.62 / canvas.height + 0.008
        : 0.10
    return max(waterFloor - clearance, 0.20)
}

/// A duck gliding on the home pond; position in fractions of the canvas.
private final class HomeDuck {
    var pos: CGPoint
    var vel: CGVector = .zero
    let color: DuckColor?

    init(pos: CGPoint, color: DuckColor?) {
        self.pos = pos
        self.color = color
    }
}

private final class HomePond {
    var ducks = [HomeDuck(pos: CGPoint(x: 0.30, y: 0.50), color: nil)]
    var splashes: [(center: CGPoint, start: Date)] = []
    var lastTick: Date?
    var restTimer: CGFloat = 0
    var lastSize: CGSize = .zero
    /// The top of the Splash button, as a fraction of the screen. Measured
    /// rather than guessed, so it survives a small screen, a large
    /// accessibility font, and the menu growing another row.
    var waterFloor: CGFloat = defaultWaterFloor

    /// The glide loop: velocity decays gently every frame, the left and right
    /// banks wrap around, the top and bottom banks give a soft bounce. When
    /// the lead duck rests on the top-left pad long enough, a red duckling
    /// hatches beside it (the pond holds two ducks, no more).
    func step(to now: Date) {
        let dt = min(CGFloat(now.timeIntervalSince(lastTick ?? now)), 0.05)
        lastTick = now
        guard dt > 0 else { return }
        let floor = duckFloor(canvas: lastSize, waterFloor: waterFloor)
        let drag = exp(-dt * duckFriction)
        for duck in ducks {
            // The floor moves - first measure, a font-size change - so a duck
            // already resting under the menu is lifted out of it even while it
            // is holding perfectly still.
            if duck.pos.y > floor { duck.pos.y = floor }
            duck.vel.dx *= drag
            duck.vel.dy *= drag
            let speed = sqrt(duck.vel.dx * duck.vel.dx + duck.vel.dy * duck.vel.dy)
            if speed < 0.004 {
                duck.vel = .zero
                continue
            }
            var p = CGPoint(x: duck.pos.x + duck.vel.dx * dt, y: duck.pos.y + duck.vel.dy * dt)
            if p.x > 1 + duckWrap { p.x = -duckWrap }
            if p.x < -duckWrap { p.x = 1 + duckWrap }
            if p.y < 0.07 {
                p.y = 0.07
                duck.vel.dy = -duck.vel.dy * 0.5
            }
            if p.y > floor {
                p.y = floor
                duck.vel.dy = -duck.vel.dy * 0.5
            }
            duck.pos = p
        }
        // Second duck hatches only after the lead duck naps on the pad.
        let lead = ducks[0]
        let napping = lead.vel == .zero &&
            abs(lead.pos.x - topLeftPad.x) < 0.11 &&
            abs(lead.pos.y - topLeftPad.y) < 0.08
        restTimer = napping ? restTimer + dt : 0
        if restTimer >= hatchRestSeconds && ducks.count < 2 {
            ducks.append(HomeDuck(
                pos: CGPoint(x: topLeftPad.x + 0.16, y: topLeftPad.y + 0.12),
                color: .red
            ))
        }
        splashes.removeAll { now.timeIntervalSince($0.start) > 0.85 }
    }

    /// Shove, don't teleport: the splash adds velocity away from the tap and
    /// the glide loop does the rest.
    func splash(at tap: CGPoint, in size: CGSize) {
        splashes.append((center: CGPoint(x: tap.x / size.width, y: tap.y / size.height), start: Date()))
        for duck in ducks {
            let duckPx = CGPoint(x: duck.pos.x * size.width, y: duck.pos.y * size.height)
            let away = CGVector(dx: duckPx.x - tap.x, dy: duckPx.y - tap.y)
            let dist = sqrt(away.dx * away.dx + away.dy * away.dy)
            let dir = dist < 1 ? CGVector(dx: 1, dy: 0) : CGVector(dx: away.dx / dist, dy: away.dy / dist)
            let speed = min(max(1.1 - 0.9 * (dist / size.width), 0.35), 1.1)
            duck.vel.dx += dir.dx * speed
            duck.vel.dy += dir.dy * speed * (size.width / size.height)
        }
    }
}

struct HomeView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    @State private var showRules = false

    /// Where the water ends. The menu is drawn over the pond, so the ducks used
    /// to drift in behind the Splash button and sit there half-eaten. The button
    /// reports its own top up to here and the backdrop treats that line as the
    /// far bank - measured rather than guessed.
    @State private var waterFloor: CGFloat = defaultWaterFloor

    var body: some View {
        let earned = vm.totalStars
        let total = (Levels.all.count + Levels.bonusPonds.count) * 3
        let continueNumber = vm.globalLevelNumber(vm.continueLevelId())
        let pondOpen = vm.pondUnlocked
        let dailyStreak = vm.dailyStreak

        ZStack {
            PondBackdrop(skinId: vm.skinId, padId: vm.padId, waterFloor: waterFloor)

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    StarsPill(earned: earned, total: total)
                    Spacer()
                    RoundIconButton(systemName: "questionmark") { showRules = true }
                        .accessibilityLabel(strings["home_how_to_play"])
                    RoundIconButton(systemName: "gearshape.fill") { vm.navigate(.settings) }
                        .accessibilityLabel(strings["home_settings"])
                }

                // Compose weights the two gaps 0.9 : 1.1; SwiftUI splits free
                // space evenly between equal Spacers, which lands the wordmark
                // in the same place to within a few points.
                Spacer(minLength: 0)
                VStack(spacing: 4) {
                    Text(strings["app_name"])
                        // 38pt, not 50. The menu went to two rows and the height
                        // had to come from somewhere; taking it from the
                        // wordmark leaves the open water in the middle exactly
                        // as big as it was, so the ducks keep the room the Daily
                        // card used to take.
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                        .shadow(color: palette.waterDeep.opacity(0.65), radius: 8, y: 4)
                    Text(strings["home_tagline"])
                        .font(.game(16, .medium))
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer(minLength: 0)

                Button {
                    vm.navigate(.game(levelId: vm.continueLevelId()))
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 26, weight: .bold))
                        VStack(spacing: 1) {
                            Text(strings["home_continue"])
                                .font(.game(18, .bold))
                            Text(strings["home_level_badge", continueNumber])
                                .font(.game(12, .semibold))
                                .opacity(0.75)
                        }
                    }
                    .foregroundStyle(PondPalette.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 66)
                    .background(palette.accent, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 10, y: 5)
                }
                .buttonStyle(SquishyButtonStyle())
                .background {
                    // The button's own top, in screen fractions, handed to the
                    // pond behind it.
                    GeometryReader { proxy in
                        let top = proxy.frame(in: .global).minY
                        let screen = UIScreen.main.bounds.height
                        Color.clear.onAppear {
                            guard screen > 0 else { return }
                            waterFloor = min(max(top / screen, 0.25), 1)
                        }
                        .onChange(of: top) { _, now in
                            guard screen > 0 else { return }
                            waterFloor = min(max(now / screen, 0.25), 1)
                        }
                    }
                }

                // Five destinations across one row left every tile about 56pt
                // wide with a hairline between them - cramped on a big phone and
                // worse on a small one. Three and then two gives each tile
                // roughly twice the width and a gap you can see. The Daily Pond
                // is one of them now rather than the full-width card it used to
                // be, keeping only what a tile can carry: the accent ring while
                // today's pond is unplayed, and the streak under the flame.
                HStack(spacing: menuGap) {
                    MenuTile(
                        systemName: "flame.fill",
                        label: strings["home_daily"],
                        subLabel: dailyStreak > 0 ? "\(dailyStreak)" : nil,
                        highlight: !vm.dailyDoneToday
                    ) { vm.navigate(.daily) }
                    MenuTile(systemName: "bolt.fill", label: strings["home_rush"]) { vm.navigate(.rush) }
                    MenuTile(systemName: "square.grid.2x2.fill", label: strings["home_levels"]) { vm.navigate(.packs) }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, menuGap)

                // The pond opens at three friends. Shown locked rather than
                // hidden: a tile that says what it wants is a reason to play on,
                // and a tile that appears from nowhere is a surprise the player
                // cannot have been working toward.
                HStack(spacing: menuGap) {
                    MenuTile(
                        systemName: "pawprint.fill",
                        label: strings["home_pond"],
                        subLabel: pondOpen ? nil : strings["home_pond_locked", pondMinFriends],
                        locked: !pondOpen
                    ) { vm.navigate(pondOpen ? .pond : .shop) }
                    // The badge shelf. It carries how many are earned rather
                    // than sitting there unlabelled: a tile that says 14/24 is
                    // a reason to open it, and one that says only "Badges" is
                    // furniture.
                    MenuTile(
                        systemName: "trophy.fill",
                        label: strings["home_achievements"],
                        subLabel: strings[
                            "home_stars_short",
                            Achievements.earnedCount(vm.achievements),
                            Achievements.totalRungs
                        ]
                    ) { vm.navigate(.quests) }
                    MenuTile(systemName: "bag.fill", label: strings["home_shop"]) { vm.navigate(.shop) }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, menuGap)

                Text(strings["home_version", appVersion])
                    .font(.game(11))
                    .foregroundStyle(palette.textSecondary.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 18)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .pondContentWidth()

            if showRules {
                RulesOverlay { showRules = false }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showRules)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

/// How-to-play, as a themed overlay card (the game's take on an alert).
private struct RulesOverlay: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let dismiss: () -> Void

    var body: some View {
        OverlayCard {
            SectionTitle(strings["rules_title"])
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(["rule_1", "rule_2", "rule_3", "rule_4", "rule_5", "rule_6"].enumerated()), id: \.offset) { index, key in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.game(15, .bold))
                            .foregroundStyle(palette.accent)
                        Text(strings[key])
                            .font(.game(15))
                            .foregroundStyle(palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            PrimaryButton(strings["close"]) { dismiss() }
        }
    }
}

private struct StarsPill: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let earned: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(palette.star)
            Text(strings["home_stars_short", earned, total])
                .font(.game(14, .bold))
                .foregroundStyle(palette.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(palette.surface.opacity(0.88), in: Capsule())
    }
}

private struct MenuTile: View {
    @Environment(\.palette) private var palette
    let systemName: String
    let label: String
    var subLabel: String?
    var locked = false
    var highlight = false
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: locked ? "lock.fill" : systemName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(locked ? palette.textSecondary : palette.accent)
                Text(label)
                    .font(.game(13, .semibold))
                    .foregroundStyle(locked ? palette.textSecondary : palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let subLabel {
                    Text(subLabel)
                        .font(.game(11, .semibold))
                        .foregroundStyle(palette.textSecondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .padding(.vertical, 14)
            .background(palette.surface.opacity(0.92), in: shape)
            // Only one tile at a time asks to be tapped - today's unplayed
            // Daily Pond - and the ring is how the card used to say it.
            .overlay(shape.strokeBorder(highlight ? palette.accent.opacity(0.75) : .clear, lineWidth: 2))
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

private struct PondBackdrop: View {
    let skinId: String
    let padId: String
    /// The top of the Splash button as a fraction of the screen: everything that
    /// swims stays above it, so no floater is ever half-hidden by the menu drawn
    /// on top.
    let waterFloor: CGFloat

    @Environment(\.palette) private var palette
    @State private var pond = HomePond()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                pond.lastSize = size
                pond.waterFloor = waterFloor
                pond.step(to: timeline.date)
                draw(&ctx, size: size, now: timeline.date)
            }
        }
        .ignoresSafeArea()
        .onTapGesture { location in
            guard pond.lastSize.width > 0 else { return }
            pond.splash(at: location, in: pond.lastSize)
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, now: Date) {
        let w = size.width
        let h = size.height
        let t = now.timeIntervalSinceReferenceDate
        let ripple = CGFloat(t.truncatingRemainder(dividingBy: 5.2) / 5.2)
        let bob = CGFloat(t.truncatingRemainder(dividingBy: 4.2) / 4.2) * 2 * .pi

        ctx.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: palette.backgroundHigh, location: 0),
                    .init(color: palette.background, location: 0.45),
                    .init(color: palette.background, location: 1),
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: h)
            )
        )

        // Expanding ripple rings, staggered around the open water.
        let anchors: [(CGPoint, CGFloat)] = [
            (CGPoint(x: w * 0.22, y: h * 0.40), 0.00),
            (CGPoint(x: w * 0.78, y: h * 0.12), 0.33),
            (CGPoint(x: w * 0.55, y: h * 0.47), 0.66),
        ]
        for (at, phase) in anchors {
            let p = (ripple + phase).truncatingRemainder(dividingBy: 1)
            let r = w * (0.03 + p * 0.13)
            ctx.stroke(
                Path(ellipseIn: CGRect(x: at.x - r, y: at.y - r, width: r * 2, height: r * 2)),
                with: .color(palette.ripple.opacity((1 - p) * 0.28)),
                style: StrokeStyle(lineWidth: w * 0.006)
            )
        }

        // Lily pads riding a gentle swell.
        let pads: [(CGPoint, CGFloat, CGFloat)] = [
            (CGPoint(x: w * topLeftPad.x, y: h * topLeftPad.y), w * 0.17, 0),
            (CGPoint(x: w * 0.88, y: h * 0.24), w * 0.12, 2.1),
            (CGPoint(x: w * 0.08, y: h * 0.47), w * 0.10, 4.2),
        ]
        for (at, side, phase) in pads {
            let dy = sin(bob + phase) * h * 0.004
            drawPadStyle(
                &ctx,
                padId: padId,
                rect: CGRect(x: at.x - side / 2, y: at.y - side / 2 + dy, width: side, height: side),
                palette: palette,
                ring: nil
            )
        }

        // Splashes from the player's taps, pushing rings across the water.
        for fx in pond.splashes {
            let p = CGFloat(min(now.timeIntervalSince(fx.start) / 0.85, 1))
            let at = CGPoint(x: fx.center.x * w, y: fx.center.y * h)
            for ring in 0...2 {
                let alpha = max((1 - p) * (0.40 - CGFloat(ring) * 0.11), 0)
                if alpha > 0 {
                    let r = w * (0.02 + p * 0.17 + CGFloat(ring) * 0.03)
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: at.x - r, y: at.y - r, width: r * 2, height: r * 2)),
                        with: .color(palette.ripple.opacity(alpha)),
                        style: StrokeStyle(lineWidth: w * 0.004 + (1 - p) * w * 0.005)
                    )
                }
            }
            if p < 0.3 {
                let r = w * 0.018
                ctx.fill(
                    Path(ellipseIn: CGRect(x: at.x - r, y: at.y - r, width: r * 2, height: r * 2)),
                    with: .color(palette.ripple.opacity((0.3 - p) * 1.6))
                )
            }
        }

        // The floaters, bobbing wherever the water carried them.
        let duckSide = w * 0.15
        for (index, duck) in pond.ducks.enumerated() {
            let duckX = duck.pos.x * w
            let duckY = duck.pos.y * h + sin(bob + CGFloat(index) * 2.1) * h * 0.006
            let glowR = duckSide * 0.62
            ctx.fill(
                Path(ellipseIn: CGRect(x: duckX - glowR, y: duckY - glowR, width: glowR * 2, height: glowR * 2)),
                with: .color(palette.ripple.opacity(0.10))
            )
            drawFloaterSkin(
                &ctx,
                skinId: skinId,
                rect: CGRect(x: duckX - duckSide / 2, y: duckY - duckSide / 2, width: duckSide, height: duckSide),
                palette: palette,
                color: duck.color
            )
        }

        // A turtle dozing off to the side of the duck's lane, tucked just above
        // the far bank - it used to sun itself at a fixed 0.665, which on most
        // phones is squarely behind the Splash button.
        let turtleSide = w * 0.11
        let turtleY = h * waterFloor - turtleSide * 0.62 + sin(bob + 1.3) * h * 0.003
        drawTurtle(
            &ctx,
            CGRect(x: w * 0.86 - turtleSide / 2, y: turtleY - turtleSide / 2, width: turtleSide, height: turtleSide),
            palette
        )
    }
}
