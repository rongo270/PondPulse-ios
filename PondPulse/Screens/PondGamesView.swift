//
//  PondGamesView.swift
//  PondPulse
//
//  The pond's four games. Port of the Android ui/PondGames.kt.
//
//  Every one of them is a toy first and a coin faucet a distant second - the
//  week's ceiling (`CoinBank.pondWeeklyCap`) is small enough that nobody grinds
//  these, and each game's own cap means one lucky run is not worth a cosmetic.
//  What they are for is giving the friends you have earned something to do.
//
//  They share one shell: an intro card, the game, and a results card. Only the
//  middle is different, and each middle is a single view driven by one frame
//  loop, exactly like the pond itself.
//
//  Each game keeps its moving parts in a plain class rather than in `@State`.
//  The frame loop writes to those fields sixty times a second, and the whole
//  screen sits inside one `TimelineView(.animation)` - which re-reads them every
//  frame anyway - so the HUD follows the simulation without a published value
//  per counter.
//

import SwiftUI

private enum GamePhase {
    case intro, playing, results
}

struct PondGameView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    let gameId: String

    @State private var phase: GamePhase = .intro
    @State private var score = 0
    /// -1 until the payout returns. The write is quick, but "not quite enough
    /// for a coin" is a statement, and showing it for a frame before the coins
    /// land would make it a false one.
    @State private var paid = -1
    /// Bumped to restart a game: every game's state is keyed on it, so "play
    /// again" rebuilds rather than trying to reset in place.
    @State private var run = 0

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            if let game = PondCatalog.gameById(gameId) {
                content(game)
            } else {
                Color.clear.onAppear { vm.back() }
            }
        }
    }

    @ViewBuilder
    private func content(_ game: PondCatalog.MiniGame) -> some View {
        switch phase {
        case .intro:
            GameIntro(
                game: game,
                best: vm.miniBests[gameId] ?? 0,
                weekLeft: max(CoinBank.pondWeeklyCap - vm.pondEarnedThisWeek, 0),
                onBack: { vm.back() },
                onPlay: { phase = .playing }
            )

        case .playing:
            playing
                .id(run)

        case .results:
            GameResults(
                game: game,
                score: score,
                coins: paid,
                best: vm.miniBests[gameId] ?? 0,
                weekDone: vm.pondEarnedThisWeek >= CoinBank.pondWeeklyCap,
                onAgain: {
                    run += 1
                    phase = .playing
                },
                onDone: { vm.back() }
            )
        }
    }

    @ViewBuilder
    private var playing: some View {
        let finish: (Int) -> Void = { result in
            score = result
            paid = -1
            phase = .results
            paid = vm.finishMiniGame(gameId: gameId, score: result)
        }
        switch gameId {
        case "chain": RippleChainView(vm: vm, onEnd: finish)
        case "herd": DucklingRoundUpView(vm: vm, onEnd: finish)
        case "seek": HideAndSeekView(vm: vm, onEnd: finish)
        case "target": SplashTargetView(vm: vm, onEnd: finish)
        default: Color.clear
        }
    }
}

// MARK: - The shell

private struct GameIntro: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let game: PondCatalog.MiniGame
    let best: Int
    let weekLeft: Int
    let onBack: () -> Void
    let onPlay: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                RoundIconButton(systemName: "chevron.backward", action: onBack)
                Spacer()
            }
            .padding(8)

            VStack(spacing: 0) {
                Spacer()
                Text(strings[game.nameKey])
                    .font(.game(30, .heavy))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 10)
                Text(strings[game.blurbKey])
                    .font(.game(15))
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 22)
                Text(strings["pond_best", best])
                    .font(.game(17, .semibold))
                    .foregroundStyle(palette.accent)
                Spacer().frame(height: 6)
                HStack(spacing: 5) {
                    CoinIcon(size: 14)
                    Text(weekLeft > 0
                         ? strings["pond_week_left", weekLeft, CoinBank.pondWeeklyCap]
                         : strings["pond_week_done"])
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer().frame(height: 26)
                Button(action: onPlay) {
                    Text(strings["pond_play"])
                        .font(.game(18, .bold))
                        .foregroundStyle(PondPalette.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(palette.accent, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(SquishyButtonStyle())
                Spacer()
            }
            .padding(.horizontal, 28)
            .pondContentWidth()
            .frame(maxWidth: .infinity)
        }
    }
}

private struct GameResults: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let game: PondCatalog.MiniGame
    let score: Int
    let coins: Int
    let best: Int
    let weekDone: Bool
    let onAgain: () -> Void
    let onDone: () -> Void

    /// Nothing paid means one of two very different things, and the player
    /// deserves to know which: the week is spent, or the run was simply too
    /// short to be worth a coin.
    private var payoutText: String {
        if coins > 0 { return strings["pond_earned", coins] }
        if coins < 0 { return "" }
        return weekDone ? strings["pond_week_done"] : strings["pond_earned_none"]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(strings[game.nameKey])
                .font(.game(17, .semibold))
                .foregroundStyle(palette.textSecondary)
            Spacer().frame(height: 8)
            Text("\(score)")
                .font(.game(68, .heavy))
                .foregroundStyle(palette.textPrimary)
                .contentTransition(.numericText())
            Text(strings["pond_best", best])
                .font(.game(15))
                .foregroundStyle(palette.textSecondary)
            Spacer().frame(height: 18)

            HStack(spacing: 8) {
                CoinIcon(size: 20)
                Text(payoutText)
                    .font(.game(15, .bold))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer().frame(height: 22)
            Button(action: onAgain) {
                Text(strings["pond_again"])
                    .font(.game(17, .bold))
                    .foregroundStyle(PondPalette.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(palette.accent, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(SquishyButtonStyle())
            Spacer().frame(height: 10)
            Button(action: onDone) {
                Text(strings["pond_done"])
                    .font(.game(15, .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
            }
            .buttonStyle(SquishyButtonStyle())
            Spacer()
        }
        .padding(.horizontal, 28)
        .pondContentWidth()
        .frame(maxWidth: .infinity)
    }
}

/// Back arrow, score, and whatever the game counts down on the right.
///
/// `label` is the word the score is in - ducklings home, buds burst - because a
/// bare number at the top of a screen is only obvious to whoever wrote it. The
/// arrow leaves a run in progress: every one of these games can strand you, and
/// a screen you can only leave by losing is a trap.
private struct GameHud: View {
    @Environment(\.palette) private var palette
    let score: Int
    let right: String
    var label: String?
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            RoundIconButton(systemName: "chevron.backward", action: onBack)
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text("\(score)")
                    .font(.game(24, .heavy))
                    .foregroundStyle(palette.textPrimary)
                if let label {
                    Text(label)
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary)
                }
            }
            Spacer(minLength: 8)
            Text(right)
                .font(.game(17, .bold))
                .foregroundStyle(palette.accent)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.leading, 4)
        .padding(.trailing, 20)
        .padding(.vertical, 4)
    }
}

/// The line of text a game speaks to the player, over the water.
private struct GameMessage: View {
    @Environment(\.palette) private var palette
    let text: String
    var tint: Color?

    var body: some View {
        Text(text)
            .font(.game(15, .bold))
            .foregroundStyle(tint ?? palette.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(palette.background.opacity(0.55), in: Capsule())
            .padding(.top, 14)
    }
}

/// Distance between two points of the pond, measured in fractions of its width.
///
/// Everything on these screens is placed in 0..1 of the width and 0..1 of the
/// height, but a circle is drawn with one radius. Comparing raw fractions makes
/// every hit test taller than the ring the player is looking at, which reads as
/// the game scoring things it plainly missed.
private func span(_ a: CGPoint, _ b: CGPoint, _ aspect: CGFloat) -> CGFloat {
    let dx = a.x - b.x
    let dy = (a.y - b.y) * aspect
    return sqrt(dx * dx + dy * dy)
}

/// The shared skeleton: one clock, and the canvas size the taps need.
///
/// Every game steps its engine from inside its `Canvas` draw closure rather than
/// from a modifier beside it. That is not a style choice: a `Canvas` whose
/// closure captures nothing that changes between frames is one SwiftUI is free
/// to leave exactly as it drew it, and a game stepped from an `onChange` next
/// door captures only reference types that never change - so the water froze on
/// frame one while the HUD above it carried on counting. Reading the frame's
/// date inside the closure is what ties the drawing to the clock.
private class GameEngine {
    var time: CGFloat = 0
    var lastTick: Date?
    var size: CGSize = .zero
    var aspect: CGFloat = 1.8
    /// The run's final score, once there is one. Read once, then cleared.
    private var result: Int?

    func finish(_ score: Int) {
        if result == nil { result = score }
    }

    func takeResult() -> Int? {
        defer { result = nil }
        return result
    }

    /// Seconds since the last frame, clamped so a backgrounded app does not
    /// resume with one enormous step.
    func advance(to now: Date) -> CGFloat {
        let dt = min(CGFloat(now.timeIntervalSince(lastTick ?? now)), 0.05)
        lastTick = now
        time += dt
        return dt
    }

    func note(_ size: CGSize) {
        self.size = size
        if size.width > 0 { aspect = size.height / size.width }
    }

    /// A tap in canvas points, as pond fractions - or nil before layout.
    func fraction(_ point: CGPoint) -> CGPoint? {
        guard size.width > 0, size.height > 0 else { return nil }
        return CGPoint(x: point.x / size.width, y: point.y / size.height)
    }
}

// MARK: - Ripple Chain

/// One tap a round. Your ripple opens every bud it washes over, and each of
/// those sends out a ripple of its own - so the tap that scores is not the one
/// on the thickest clump, it is the one where the clump is about to *drift*.
/// Clear the round's quota and the next round has more buds and wants more of
/// them; miss it and the run is over.
///
/// It is here because it is the only game on the pond that is entirely about the
/// ripple, which is the one thing PondPulse is about.
private struct RippleChainView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let onEnd: (Int) -> Void

    @State private var engine = ChainEngine()

    var body: some View {
        TimelineView(.animation) { timeline in
            VStack(spacing: 0) {
                GameHud(
                    score: engine.banked + engine.popped,
                    right: strings["chain_round", engine.round + 1],
                    label: strings["chain_popped_label"]
                ) { vm.back() }

                ZStack(alignment: .top) {
                    canvas(timeline.date)
                    message
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func canvas(_ date: Date) -> some View {
        Canvas { ctx, size in
            engine.note(size)
            engine.step(dt: engine.advance(to: date))
            let time = engine.time
            let w = size.width
            let h = size.height

            drawPondWater(&ctx, weatherId: "day", size: size, palette: palette, time: time)

            // A burst bud opens into a lily pad and stays open, so the round
            // leaves the pond visibly better off than it found it.
            for bud in engine.buds where bud.burstAt >= 0 {
                let grow = min(max((time - bud.burstAt) / 0.45, 0), 1)
                let side = w * chainPadSide * (0.3 + 0.7 * grow)
                drawPadStyle(
                    &ctx, padId: vm.padId,
                    rect: CGRect(x: bud.pos.x * w - side / 2, y: bud.pos.y * h - side / 2,
                                 width: side, height: side),
                    palette: palette, ring: nil
                )
            }

            for ring in engine.rings {
                let age = time - ring.born
                if age < 0 || age > chainRingLife { continue }
                let radius = chainRadius(age, engine.reach) * w
                let fade = min(max(1 - age / chainRingLife, 0), 1)
                let tint = ring.fromPlayer ? palette.accent : palette.ripple
                let center = CGPoint(x: ring.at.x * w, y: ring.at.y * h)
                ctx.fill(circle(center, radius), with: .color(tint.opacity(0.13 * fade)))
                ctx.stroke(circle(center, radius), with: .color(tint.opacity(0.75 * fade)),
                           style: stroke(w * 0.007))
            }

            for bud in engine.buds where bud.burstAt < 0 {
                drawChainBud(
                    &ctx,
                    at: CGPoint(x: bud.pos.x * w, y: bud.pos.y * h),
                    r: w * chainBudRadius,
                    phase: time + bud.pos.x * 7,
                    palette: palette
                )
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { point in
            guard engine.phase == .aim, let at = engine.fraction(point) else { return }
            Haptics.splash(enabled: vm.haptics)
            engine.tap(at: at)
        }
        .onChange(of: date) { _, _ in
            if let result = engine.takeResult() { onEnd(result) }
        }
    }

    @ViewBuilder
    private var message: some View {
        switch engine.phase {
        case .aim:
            GameMessage(text: strings["chain_aim", engine.quota, engine.budCount])
        case .running:
            GameMessage(text: strings["chain_need", engine.popped, engine.quota])
        case .settle:
            if engine.popped >= engine.quota {
                GameMessage(text: strings["chain_cleared"], tint: palette.accent)
            } else {
                GameMessage(text: strings["chain_short", engine.quota - engine.popped], tint: palette.danger)
            }
        }
    }
}

private enum ChainPhase {
    case aim, running, settle
}

/// Seconds a ripple lives: out, held open, then closed.
private let chainRingLife: CGFloat = 1.9
private let chainRingGrow: CGFloat = 0.45
private let chainRingHold: CGFloat = 0.8

private let chainBudRadius: CGFloat = 0.026
private let chainPadSide: CGFloat = 0.11

/// Buds on the water in `round` (0-based).
func chainBuds(_ round: Int) -> Int { 12 + 3 * round }

/// How far a ripple reaches in `round`, in fractions of the pond's width.
///
/// It shrinks as the bud count grows, and that is the only thing keeping the
/// ramp honest: a chain spreads when a ring covers enough of a crowded pond to
/// find its next bud, so more buds on their own would make every later round
/// *easier* than the one before it.
func chainReach(_ round: Int) -> CGFloat { max(0.26 - 0.012 * CGFloat(round), 0.13) }

/// How many of them the round wants.
///
/// Two more every round against three more buds, so the *share* asked for climbs
/// steadily - 1 of 12, then 3 of 15, 5 of 18, 7 of 21 - without ever jumping.
/// A flat number rather than a percentage because the player is told it before
/// they tap, and "burst 7" is something you can aim at; "burst 33%" is not.
func chainQuota(_ round: Int) -> Int { 1 + 2 * round }

private func chainRadius(_ age: CGFloat, _ reach: CGFloat) -> CGFloat {
    if age < chainRingGrow {
        return reach * sin(age / chainRingGrow * (.pi / 2))
    }
    if age < chainRingGrow + chainRingHold {
        return reach
    }
    if age < chainRingLife {
        return reach * (1 - (age - chainRingGrow - chainRingHold)
                        / (chainRingLife - chainRingGrow - chainRingHold))
    }
    return 0
}

private final class ChainBud {
    var pos: CGPoint
    var vel: CGVector
    /// When it opened, or -1 while it is still a bud.
    var burstAt: CGFloat = -1

    init(pos: CGPoint, vel: CGVector) {
        self.pos = pos
        self.vel = vel
    }
}

private struct ChainRing {
    let at: CGPoint
    let born: CGFloat
    let fromPlayer: Bool
}

private final class ChainEngine: GameEngine {
    var buds: [ChainBud] = []
    var rings: [ChainRing] = []
    var round = 0
    var banked = 0
    var popped = 0
    var phase: ChainPhase = .aim
    /// When the last ring closed, so the verdict can wait a beat: a round that
    /// ends the instant the water stills gives the player nothing to look at
    /// but the number that ended them.
    private var settledAt: CGFloat = -1

    var budCount: Int { chainBuds(round) }
    var quota: Int { chainQuota(round) }
    var reach: CGFloat { chainReach(round) }

    override init() {
        super.init()
        resetRound()
    }

    private func resetRound() {
        buds.removeAll()
        rings.removeAll()
        popped = 0
        phase = .aim
        settledAt = -1
        for _ in 0..<budCount {
            buds.append(ChainBud(
                pos: CGPoint(x: CGFloat.random(in: 0.10...0.90), y: CGFloat.random(in: 0.12...0.88)),
                vel: CGVector(dx: CGFloat.random(in: -0.045...0.045), dy: CGFloat.random(in: -0.03...0.03))
            ))
        }
    }

    func tap(at: CGPoint) {
        guard phase == .aim else { return }
        rings.append(ChainRing(at: at, born: time, fromPlayer: true))
        phase = .running
    }

    func step(dt: CGFloat) {
        drift(dt)
        if phase == .running {
            popped += spread()
            if rings.allSatisfy({ time - $0.born > chainRingLife }) {
                phase = .settle
                settledAt = time
            }
        }
        if phase == .settle, settledAt >= 0, time - settledAt >= 1.0 {
            if popped >= quota {
                banked += popped
                round += 1
                resetRound()
            } else {
                finish(banked + popped)
                settledAt = -1
            }
        }
    }

    private func drift(_ dt: CGFloat) {
        for bud in buds where bud.burstAt < 0 {
            var p = CGPoint(x: bud.pos.x + bud.vel.dx * dt, y: bud.pos.y + bud.vel.dy * dt)
            if p.x < 0.07 || p.x > 0.93 { bud.vel.dx = -bud.vel.dx; p = bud.pos }
            if p.y < 0.09 || p.y > 0.91 { bud.vel.dy = -bud.vel.dy; p = bud.pos }
            bud.pos = p
        }
    }

    /// Opens every bud an open ring is touching. Returns how many.
    private func spread() -> Int {
        var born: [ChainRing] = []
        for ring in rings {
            let age = time - ring.born
            if age < 0 || age > chainRingLife { continue }
            let radius = chainRadius(age, reach)
            for bud in buds where bud.burstAt < 0 {
                if span(bud.pos, ring.at, aspect) <= radius + chainBudRadius {
                    bud.burstAt = time
                    born.append(ChainRing(at: bud.pos, born: time, fromPlayer: false))
                }
            }
        }
        rings.append(contentsOf: born)
        return born.count
    }
}

/// A closed lily bud: a bulb on the water with a nub of a tip.
private func drawChainBud(
    _ ctx: inout GraphicsContext,
    at: CGPoint, r: CGFloat, phase: CGFloat, palette: PondPalette
) {
    let bob = sin(phase) * r * 0.16
    let center = CGPoint(x: at.x, y: at.y + bob)
    ctx.fill(
        circle(CGPoint(x: center.x, y: center.y + r * 0.35), r * 1.05),
        with: .color(palette.waterDeep.opacity(0.30))
    )
    ctx.fill(circle(center, r), with: .color(palette.pad))
    ctx.stroke(circle(center, r), with: .color(palette.padDark.opacity(0.55)), style: stroke(r * 0.22))
    ctx.fill(
        circle(CGPoint(x: center.x - r * 0.18, y: center.y - r * 0.22), r * 0.34),
        with: .color(palette.star.opacity(0.9))
    )
}

// MARK: - Duckling Round-up

/// PondPulse itself, off the grid. Ducklings drift loose, lily pads wait, and
/// one splash shoves *every* loose duckling away from it - close in it launches
/// them, far out it barely nudges. Park them all before the splashes run out.
///
/// A docked duckling is home for good: no later splash moves it, and no current
/// takes it back. That is the campaign's own rule, and the whole reason this
/// reads as practice rather than as a different game.
private struct DucklingRoundUpView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let onEnd: (Int) -> Void

    @State private var engine: HerdEngine?

    var body: some View {
        TimelineView(.animation) { timeline in
            let engine = current
            VStack(spacing: 0) {
                GameHud(
                    score: engine.banked + engine.home,
                    right: strings["herd_splashes", engine.splashesLeft],
                    label: strings["herd_home_label"]
                ) { vm.back() }

                ZStack(alignment: .top) {
                    canvas(engine, timeline.date)
                    message(engine)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    /// The cast is read once, when the run starts: a friend swapped in mid-run
    /// would be a duckling that changed species between splashes.
    private var current: HerdEngine {
        if let engine { return engine }
        let made = HerdEngine(cast: vm.pondCast())
        DispatchQueue.main.async { engine = made }
        return made
    }

    private func canvas(_ engine: HerdEngine, _ date: Date) -> some View {
        Canvas { ctx, size in
            engine.note(size)
            engine.step(dt: engine.advance(to: date))
            let time = engine.time
            let w = size.width
            let h = size.height

            drawPondWater(&ctx, weatherId: "day", size: size, palette: palette, time: time)

            // Twice the catch radius, so a pad that has grown harder to hit is
            // visibly the smaller pad it has become.
            let padSide = w * engine.dock * 2
            for (index, pad) in engine.pads.enumerated() {
                let taken = engine.ducks.contains { $0.homePad == index }
                let x = pad.x * w
                let y = pad.y * h + sin(time + CGFloat(index)) * h * 0.003
                drawPadStyle(
                    &ctx, padId: vm.padId,
                    rect: CGRect(x: x - padSide / 2, y: y - padSide / 2, width: padSide, height: padSide),
                    palette: palette, ring: taken ? nil : palette.accent.opacity(0.55)
                )
            }

            for splash in engine.rings {
                drawSplashRings(
                    &ctx,
                    at: CGPoint(x: splash.at.x * w, y: splash.at.y * h),
                    progress: min(max((time - splash.born) / 0.9, 0), 1),
                    size: size, palette: palette
                )
            }

            let side = padSide * 0.93
            for duck in engine.ducks {
                let bob = duck.homePad >= 0 ? 0 : sin(time * 1.8 + duck.pos.x * 9) * h * 0.004
                let x = duck.pos.x * w
                let y = duck.pos.y * h + bob
                ctx.fill(
                    circle(CGPoint(x: x, y: y + side * 0.18), side * 0.40),
                    with: .color(palette.waterDeep.opacity(0.22))
                )
                drawFloaterSkin(
                    &ctx, skinId: duck.skinId,
                    rect: CGRect(x: x - side / 2, y: y - side / 2, width: side, height: side),
                    palette: palette, color: nil
                )
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { point in
            guard engine.phase == .playing, engine.splashesLeft > 0,
                  let at = engine.fraction(point) else { return }
            engine.splashesLeft -= 1
            Haptics.splash(enabled: vm.haptics)
            engine.splash(at: at)
        }
        .onChange(of: date) { _, _ in
            if let result = engine.takeResult() { onEnd(result) }
        }
    }

    @ViewBuilder
    private func message(_ engine: HerdEngine) -> some View {
        switch engine.phase {
        case .playing:
            GameMessage(text: strings["herd_goal", engine.duckCount - engine.home])
        case .cleared:
            GameMessage(text: strings["herd_cleared"], tint: palette.accent)
        case .stranded:
            GameMessage(text: strings["herd_stranded"], tint: palette.danger)
        }
    }
}

private enum HerdPhase {
    case playing, cleared, stranded
}

/// Ducklings adrift in `round` (0-based). Caps at seven: past that it is soup.
func herdDucks(_ round: Int) -> Int { min(2 + round / 2, herdMaxDucks) }

/// Splashes the round allows.
///
/// Six over the duckling count while the game is still teaching itself, then one
/// fewer every round from `herdBite` on, and never below one a duckling plus a
/// spare. The floor is what stops the ramp from turning a solvable board into an
/// unsolvable one - past a point the round stops getting meaner and only gets
/// bigger.
///
/// It used to bottom out at *two* splashes a duckling, which a player who can
/// aim never needs: from round 14 on every round was the same round, and the
/// game stopped asking anything.
func herdSplashes(_ round: Int) -> Int {
    let ducks = herdDucks(round)
    return max(ducks + 6 - herdBiteAt(round), ducks + 1)
}

/// How far past the ramp's turn `round` is, in rounds. Zero until `herdBite`.
///
/// The first five rounds are the game explaining itself - two, three and four
/// ducklings with splashes to spare - and everything that tightens reads off
/// this, so they all start biting at the same place.
private func herdBiteAt(_ round: Int) -> Int { max(round - herdBite, 0) }

/// How near a pad a duckling has to pass to be caught by it, in width fractions.
///
/// Shrinks with the ramp, and the pad is drawn at exactly twice it, so the pad
/// you can see *is* the pad that catches - a target that quietly stopped
/// matching its own picture would read as the game cheating.
func herdDock(_ round: Int) -> CGFloat {
    max(herdDockRange - 0.002 * CGFloat(herdBiteAt(round)), herdDockMin)
}

/// Water drag per second in `round`. Lower than the pond's, so a shove carries -
/// but it climbs with the ramp, so a wild shove at the far end of a late round
/// dies before it reaches anything and the splash is simply gone.
func herdDrag(_ round: Int) -> CGFloat {
    min(herdFriction + 0.05 * CGFloat(herdBiteAt(round)), herdDragMax)
}

private let herdMaxDucks = 7

/// The round the ramp starts biting on: everything before it is the tutorial.
private let herdBite = 4

/// Within this, in width fractions, a duckling is on the pad and is home.
private let herdDockRange: CGFloat = 0.075
private let herdDockMin: CGFloat = 0.055

/// Water drag per second. Lower than the pond's, so a shove carries further.
private let herdFriction: CGFloat = 1.6
private let herdDragMax: CGFloat = 2.0

/// Below this speed nothing is going to reach anything: the round can be judged.
private let herdStill: CGFloat = 0.012

private let herdLeft: CGFloat = 0.11
private let herdRight: CGFloat = 0.89
private let herdTop: CGFloat = 0.13
private let herdBottom: CGFloat = 0.87

private final class HerdDuck {
    let skinId: String
    var pos: CGPoint
    var vel = CGVector.zero
    /// The pad it settled on, or -1 while it is still loose. Never unset.
    var homePad = -1

    init(skinId: String, pos: CGPoint) {
        self.skinId = skinId
        self.pos = pos
    }
}

private struct HerdSplash {
    let at: CGPoint
    let born: CGFloat
}

private final class HerdEngine: GameEngine {
    var ducks: [HerdDuck] = []
    var pads: [CGPoint] = []
    var rings: [HerdSplash] = []
    var round = 0
    var banked = 0
    var home = 0
    var splashesLeft = 0
    var phase: HerdPhase = .playing
    private var phaseAt: CGFloat = -1
    private let cast: [String]

    var duckCount: Int { herdDucks(round) }

    /// This round's catch radius and water drag, both set by `resetRound`.
    private(set) var dock = herdDockRange
    private(set) var drag = herdFriction

    init(cast: [String]) {
        self.cast = cast.isEmpty ? ["classic"] : cast
        super.init()
        resetRound()
    }

    private func resetRound() {
        ducks.removeAll()
        pads.removeAll()
        rings.removeAll()
        home = 0
        splashesLeft = herdSplashes(round)
        phase = .playing
        phaseAt = -1
        dock = herdDock(round)
        drag = herdDrag(round)
        // Seven pads and seven ducklings will not sit a third of the board
        // apart, and forty tries that all fail leave everything bunched in
        // whatever corner was roomiest. A fuller board asks for less room.
        let padGap: CGFloat = duckCount <= 5 ? 0.30 : 0.22
        // Pads first, then ducklings placed clear of them: a duckling that
        // starts on a pad is a point the player was given, not one they took.
        for _ in 0..<duckCount {
            pads.append(scatter(taken: pads, apart: padGap))
        }
        for index in 0..<duckCount {
            let at = scatter(taken: pads + ducks.map(\.pos), apart: padGap * 0.87)
            ducks.append(HerdDuck(skinId: cast[index % cast.count], pos: at))
        }
    }

    /// A spot in the open water at least `apart` from everything in `taken`.
    private func scatter(taken: [CGPoint], apart: CGFloat) -> CGPoint {
        var best = CGPoint(x: 0.5, y: 0.5)
        var bestGap: CGFloat = -1
        for _ in 0..<40 {
            let at = CGPoint(
                x: CGFloat.random(in: herdLeft...herdRight),
                y: CGFloat.random(in: herdTop...herdBottom)
            )
            let gap = taken.map { span(at, $0, aspect) }.min() ?? .greatestFiniteMagnitude
            if gap >= apart { return at }
            if gap > bestGap { bestGap = gap; best = at }
        }
        // Forty tries and nothing clear: take the roomiest of them rather than
        // looping forever on a board that simply has no room left.
        return best
    }

    func splash(at: CGPoint) {
        rings.append(HerdSplash(at: at, born: time))
        for duck in ducks where duck.homePad < 0 {
            let away = CGVector(dx: duck.pos.x - at.x, dy: duck.pos.y - at.y)
            let dist = span(duck.pos, at, aspect)
            let raw = sqrt(away.dx * away.dx + away.dy * away.dy)
            let dir = dist < 0.001 || raw < 0.0001
                ? CGVector(dx: 1, dy: 0)
                : CGVector(dx: away.dx / raw, dy: away.dy / raw)
            let push = splashPush(dist)
            duck.vel.dx += dir.dx * push
            duck.vel.dy += dir.dy * push
        }
    }

    func step(dt: CGFloat) {
        rings.removeAll { time - $0.born > 0.9 }
        home += stepDucks(dt)

        if phase == .playing {
            if home >= duckCount {
                phase = .cleared
                phaseAt = time
            } else if splashesLeft <= 0 && settled() {
                // Out of splashes is not out of the round: whatever is still
                // gliding may yet find a pad, and calling it over while a
                // duckling is plainly on its way would be a lie.
                phase = .stranded
                phaseAt = time
            }
        }

        guard phaseAt >= 0 else { return }
        switch phase {
        case .cleared where time - phaseAt >= 0.95:
            banked += home
            round += 1
            resetRound()
        case .stranded where time - phaseAt >= 1.1:
            finish(banked + home)
            phaseAt = -1
        default:
            break
        }
    }

    /// One frame. Returns how many ducklings reached a pad on it.
    private func stepDucks(_ dt: CGFloat) -> Int {
        var docked = 0
        for duck in ducks where duck.homePad < 0 {
            for other in ducks where other !== duck && other.homePad < 0 {
                let gap = CGVector(dx: duck.pos.x - other.pos.x, dy: duck.pos.y - other.pos.y)
                let d = sqrt(gap.dx * gap.dx + gap.dy * gap.dy)
                if d >= 0.0001 && d <= 0.14 {
                    let force = (0.14 - d) * 2.2 * dt
                    duck.vel.dx += gap.dx / d * force
                    duck.vel.dy += gap.dy / d * force
                }
            }

            let keep = min(max(1 - drag * dt, 0), 1)
            duck.vel.dx *= keep
            duck.vel.dy *= keep
            var p = CGPoint(x: duck.pos.x + duck.vel.dx * dt, y: duck.pos.y + duck.vel.dy * dt)
            // The banks bounce. A duckling that vanished off one side would be
            // a splash the player cannot answer.
            if p.x < herdLeft { p.x = herdLeft; duck.vel.dx = -duck.vel.dx * 0.55 }
            if p.x > herdRight { p.x = herdRight; duck.vel.dx = -duck.vel.dx * 0.55 }
            if p.y < herdTop { p.y = herdTop; duck.vel.dy = -duck.vel.dy * 0.55 }
            if p.y > herdBottom { p.y = herdBottom; duck.vel.dy = -duck.vel.dy * 0.55 }
            duck.pos = p

            if let free = pads.indices.first(where: { index in
                !ducks.contains { $0.homePad == index } && span(p, pads[index], aspect) < dock
            }) {
                duck.homePad = free
                duck.pos = pads[free]
                duck.vel = .zero
                docked += 1
            }
        }
        return docked
    }

    /// True once nothing loose is still moving anywhere worth waiting for.
    private func settled() -> Bool {
        !ducks.contains { $0.homePad < 0 && sqrt($0.vel.dx * $0.vel.dx + $0.vel.dy * $0.vel.dy) > herdStill }
    }
}

/// How hard a splash `dist` away shoves what it is aimed at.
///
/// The same curve My Pond uses, stretched: close in it launches, far out it
/// barely nudges, and the far end is soft enough to be *aiming*. At the original
/// falloff the gentlest shove available still carried a duckling a tenth of the
/// pond, so the last nudge onto a pad was luck rather than a choice.
func splashPush(_ dist: CGFloat) -> CGFloat { min(max(0.9 - dist * 0.95, 0.10), 0.9) }

// MARK: - Hide & Seek

/// A friend ducks under a pad, the pads slide around each other, and you say
/// which one. Every round cleared adds a swap and, every third round, another
/// pad - so the run ends when your eyes do, not on a clock.
///
/// The swap is an arc, not a slide: two pads trading places pass one over and
/// one under, which is the difference between a shuffle you can follow and two
/// shapes going through each other.
private struct HideAndSeekView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let onEnd: (Int) -> Void

    @State private var engine = SeekEngine()

    private var rightLabel: String {
        switch engine.phase {
        case .showing: strings["seek_watch"]
        case .shuffling: strings["seek_shuffle"]
        case .picking: strings["seek_pick"]
        case .revealed: engine.picked == engine.hidden ? strings["seek_right"] : strings["seek_wrong"]
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            VStack(spacing: 0) {
                GameHud(
                    score: engine.round,
                    right: rightLabel,
                    label: strings["seek_rounds_label"]
                ) { vm.back() }

                canvas(timeline.date)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func canvas(_ date: Date) -> some View {
        Canvas { ctx, size in
            engine.note(size)
            engine.step(dt: engine.advance(to: date))
            let time = engine.time
            let w = size.width
            let h = size.height
            let pads = engine.pads

            drawPondWater(&ctx, weatherId: "day", size: size, palette: palette, time: time)

            let side = min(w / CGFloat(pads) * 0.80, h * 0.34)
            let cy = h * seekRowY

            // The dive that starts the shuffle, so the friend is seen to go
            // under a pad rather than simply stopping being drawn.
            //
            // Drawn where the friend went in, never where the pad hiding it has
            // since got to: read off `xOf[hidden]` the rings followed the right
            // pad through the first swaps, which told the player the answer
            // without them having to follow anything.
            if engine.divedAt > 0 && time - engine.divedAt < seekDiveLife {
                drawSplashRings(
                    &ctx,
                    at: CGPoint(x: engine.divedX * w, y: cy),
                    progress: min(max((time - engine.divedAt) / seekDiveLife, 0), 1),
                    size: size, palette: palette
                )
            }

            if engine.phase == .showing || engine.phase == .revealed {
                let x = engine.xOf[engine.hidden] * w
                let y = cy - side * 0.42
                drawFloaterSkin(
                    &ctx, skinId: vm.skinId,
                    rect: CGRect(x: x - side * 0.34, y: y - side * 0.34,
                                 width: side * 0.68, height: side * 0.68),
                    palette: palette, color: nil
                )
            }

            // Drawn low-to-high so the pad ducking under a swap really does
            // pass beneath the one going over it.
            for pad in (0..<pads).sorted(by: { engine.liftOf[$0] < engine.liftOf[$1] }) {
                let lift = engine.liftOf[pad]
                let scale = 1 + lift * 0.16
                let x = engine.xOf[pad] * w
                let y = cy - lift * side * 0.30
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - side * 0.36, y: cy + side * 0.30,
                                           width: side * 0.72, height: side * 0.16)),
                    with: .color(palette.waterDeep.opacity(0.22 + 0.12 * max(lift, 0)))
                )
                var ring: Color?
                if engine.phase == .revealed {
                    if pad == engine.hidden { ring = palette.accent }
                    else if pad == engine.picked { ring = palette.danger }
                }
                drawPadStyle(
                    &ctx, padId: vm.padId,
                    rect: CGRect(x: x - side * scale / 2, y: y - side * scale / 2,
                                 width: side * scale, height: side * scale),
                    palette: palette, ring: ring
                )
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { point in
            guard engine.phase == .picking, let at = engine.fraction(point) else { return }
            // Only taps on the row of pads count. A stray tap at the very top or
            // bottom of the screen ending a run is the kind of thing a player
            // never forgives.
            guard at.y >= seekRowY - 0.22, at.y <= seekRowY + 0.22 else { return }
            engine.pick(at.x)
            Haptics.splash(enabled: vm.haptics)
        }
        .onChange(of: date) { _, _ in
            if let result = engine.takeResult() { onEnd(result) }
        }
    }
}

private enum SeekPhase {
    case showing, shuffling, picking, revealed
}

private let seekShowSeconds: CGFloat = 1.1

/// How long the dive's rings last - and how long the shuffle waits for them.
private let seekDiveLife: CGFloat = 0.6
private let seekBaseSwaps = 3
private let seekRowY: CGFloat = 0.46

/// Where every pad belongs, where it is being drawn, and how high it is riding.
///
/// The gap between the first two is the whole game - a shuffle you cannot see is
/// not a shuffle you can follow. The third is what keeps two pads trading places
/// from occupying the same water: one arcs over, the other dips under, and
/// `liftOf` is read both for the offset and for the drawing order.
private final class SeekEngine: GameEngine {
    var round = 0
    var phase: SeekPhase = .showing
    var picked = -1
    private(set) var pads = 3
    private(set) var hidden = 0
    private var slotOf: [Int] = []
    var xOf: [CGFloat] = []
    var liftOf: [CGFloat] = []
    /// How far through its arc each pad is: 1 at the swap, 0 when it lands.
    private var swimOf: [CGFloat] = []
    private var arcOf: [CGFloat] = []

    /// When the friend went under, so the splash can be drawn. -1 until then.
    private(set) var divedAt: CGFloat = -1

    /// And where, pinned: the rings stay in the water the friend entered.
    private(set) var divedX: CGFloat = 0

    private var elapsed: CGFloat = 0
    private var swapsLeft = 0
    private var nextSwap: CGFloat = 0
    private var gap: CGFloat = 0.46
    private var revealedAt: CGFloat = -1

    override init() {
        super.init()
        resetRound()
    }

    private func resetRound() {
        pads = 3 + min(round / 3, 2)
        hidden = Int.random(in: 0..<pads)
        slotOf = Array(0..<pads)
        xOf = (0..<pads).map { (CGFloat($0) + 0.5) / CGFloat(pads) }
        liftOf = Array(repeating: 0, count: pads)
        swimOf = Array(repeating: 0, count: pads)
        arcOf = Array(repeating: 0, count: pads)
        divedAt = -1
        divedX = 0
        picked = -1
        phase = .showing
        elapsed = 0
        swapsLeft = seekBaseSwaps + round
        // The first swap waits for the dive's rings to clear. Started on the
        // same frame the friend went under, the shuffle ran *behind* a ripple
        // that was still on the water - and a ripple sitting over a pad that is
        // already moving is the answer, drawn on the board for anyone patient
        // enough to watch it.
        nextSwap = seekShowSeconds + seekDiveLife
        gap = max(0.46 - CGFloat(round) * 0.02, 0.20)
        revealedAt = -1
    }

    func pick(_ fx: CGFloat) {
        guard phase == .picking else { return }
        // Whichever pad is drawn nearest the finger, not whichever slot it is
        // over.
        picked = (0..<pads).min(by: { abs(xOf[$0] - fx) < abs(xOf[$1] - fx) }) ?? 0
        phase = .revealed
        revealedAt = time
    }

    func step(dt: CGFloat) {
        elapsed += dt
        slide(dt)

        if phase == .showing && elapsed >= seekShowSeconds {
            phase = .shuffling
            divedAt = time
            divedX = xOf[hidden]
        }
        if phase == .shuffling && elapsed >= nextSwap {
            if swapsLeft <= 0 {
                phase = .picking
            } else {
                swap()
                swapsLeft -= 1
                nextSwap = elapsed + gap
            }
        }
        // The verdict waits a beat, and fires exactly once: either "next round"
        // or "run over", never both on a frame boundary.
        if phase == .revealed, revealedAt >= 0, time - revealedAt >= 0.9 {
            if picked == hidden {
                round += 1
                resetRound()
            } else {
                finish(round)
                revealedAt = -1
            }
        }
    }

    private func swap() {
        let a = Int.random(in: 0..<pads)
        var b = Int.random(in: 0..<pads)
        while b == a { b = Int.random(in: 0..<pads) }
        slotOf.swapAt(a, b)
        // Whoever is travelling right goes over the top; it reads as one pad
        // giving way to the other rather than as a collision.
        let aRight = xOf[b] > xOf[a]
        arcOf[a] = aRight ? 1 : -1
        arcOf[b] = aRight ? -1 : 1
        swimOf[a] = 1
        swimOf[b] = 1
    }

    private func slide(_ dt: CGFloat) {
        for pad in 0..<pads {
            let goal = (CGFloat(slotOf[pad]) + 0.5) / CGFloat(pads)
            xOf[pad] += (goal - xOf[pad]) * min(dt * 9, 1)
            if swimOf[pad] > 0 {
                swimOf[pad] = max(swimOf[pad] - dt * 3.2, 0)
                liftOf[pad] = arcOf[pad] * sin((1 - swimOf[pad]) * .pi)
            } else {
                liftOf[pad] = 0
            }
        }
    }
}

// MARK: - Splash Target

/// PondPulse's own rule, off the grid: a splash shoves the duckling *away* from
/// it, along whichever of the eight compass directions the push is closest to.
/// Thirty splashes a run, and the pad holds still - land on it and the next one
/// appears somewhere else and holds still there too.
///
/// The shove is the pond's, not a step. A splash close behind the duckling
/// launches it most of the way across the water; one from the far side barely
/// ripples under it. That distance curve is the whole skill, and it is the same
/// curve My Pond uses when you tap the water there.
///
/// Counting taps rather than seconds is what makes a wasted splash cost
/// something. On a clock the answer was always to flail.
private struct SplashTargetView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let onEnd: (Int) -> Void

    @State private var engine = TargetEngine()

    var body: some View {
        TimelineView(.animation) { timeline in
            VStack(spacing: 0) {
                GameHud(
                    score: engine.score,
                    right: strings["target_taps", engine.tapsLeft],
                    label: strings["target_hits_label"]
                ) { vm.back() }

                ZStack(alignment: .top) {
                    canvas(timeline.date)
                    if engine.score == 0 && engine.tapsLeft > targetTaps - 4 {
                        GameMessage(text: strings["target_hint"])
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func canvas(_ date: Date) -> some View {
        Canvas { ctx, size in
            engine.note(size)
            engine.step(dt: engine.advance(to: date))
            let time = engine.time
            let w = size.width
            let h = size.height

            drawPondWater(&ctx, weatherId: "day", size: size, palette: palette, time: time)

            let ringAt = CGPoint(x: engine.target.x * w, y: engine.target.y * h)
            // Smaller than the ring on purpose. At 0.20 the pad covered the ring
            // completely, and the ring is the only thing telling the player how
            // close is close enough.
            let padSide = w * 0.11
            drawPadStyle(
                &ctx, padId: vm.padId,
                rect: CGRect(x: ringAt.x - padSide / 2, y: ringAt.y - padSide / 2,
                             width: padSide, height: padSide),
                palette: palette, ring: palette.accent
            )
            ctx.stroke(
                circle(ringAt, targetRadius * w),
                with: .color(palette.accent.opacity(0.55 + 0.25 * sin(time * 3))),
                style: stroke(w * 0.008)
            )

            // The pad bursts when it is scored, so a point is something the
            // player sees rather than something the counter mentions.
            if engine.scoredAt > 0 && time - engine.scoredAt < 0.5 {
                let p = (time - engine.scoredAt) / 0.5
                ctx.stroke(
                    circle(CGPoint(x: engine.scoredAtPos.x * w, y: engine.scoredAtPos.y * h),
                           w * (targetRadius + p * 0.10)),
                    with: .color(palette.accent.opacity((1 - p) * 0.7)),
                    style: stroke(w * 0.01 * (1 - p))
                )
            }

            for splash in engine.splashes {
                drawSplashRings(
                    &ctx,
                    at: CGPoint(x: splash.at.x * w, y: splash.at.y * h),
                    progress: min(max((time - splash.born) / 0.9, 0), 1),
                    size: size, palette: palette
                )
            }

            let side = w * 0.15
            let speed = sqrt(engine.vel.dx * engine.vel.dx + engine.vel.dy * engine.vel.dy)
            if speed > 0.05 {
                // Two flattened ovals trailing the glide. A round blob read as a
                // second duckling; a wake has to lie on the water.
                for step in 1...2 {
                    let back = CGPoint(
                        x: engine.pos.x - engine.vel.dx * (0.035 * CGFloat(step)),
                        y: engine.pos.y - engine.vel.dy * (0.035 * CGFloat(step))
                    )
                    let fade = min(speed * 0.3, 0.20) / CGFloat(step)
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: back.x * w - side * 0.30,
                            y: back.y * h + side * 0.06 - side * 0.09,
                            width: side * 0.60, height: side * 0.18
                        )),
                        with: .color(palette.ripple.opacity(fade))
                    )
                }
            }
            let duckAt = CGPoint(x: engine.pos.x * w, y: engine.pos.y * h + sin(time * 2) * h * 0.004)
            drawFloaterSkin(
                &ctx, skinId: vm.skinId,
                rect: CGRect(x: duckAt.x - side / 2, y: duckAt.y - side / 2, width: side, height: side),
                palette: palette, color: nil
            )
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { point in
            guard engine.tapsLeft > 0, let at = engine.fraction(point) else { return }
            engine.tapsLeft -= 1
            engine.splash(at: at)
        }
        .onChange(of: date) { _, _ in
            // The buzz for a landed duckling is raised by the step and spent
            // here: a haptic fired from inside a draw pass is a side effect in
            // a render, and one dropped frame would fire it twice.
            if engine.takeScored() { Haptics.splash(enabled: vm.haptics) }
            if let result = engine.takeResult() { onEnd(result) }
        }
    }
}

/// Splashes a run gets. A budget, not a clock - see the note above.
private let targetTaps = 30
private let targetRadius: CGFloat = 0.075

/// Water drag per second. The shove itself is `splashPush`, shared with the
/// round-up.
private let targetFriction: CGFloat = 1.7

/// Below this speed the water is still and the run may be judged.
private let targetStill: CGFloat = 0.012

/// How far a fresh pad must land from the duckling, in width fractions.
private let targetClearance: CGFloat = 0.30

private let targetLeft: CGFloat = 0.12
private let targetRight: CGFloat = 0.88
private let targetTop: CGFloat = 0.14
private let targetBottom: CGFloat = 0.86

private struct TargetSplash {
    let at: CGPoint
    let born: CGFloat
}

private final class TargetEngine: GameEngine {
    var pos = CGPoint(x: 0.5, y: 0.62)
    var vel = CGVector.zero
    var target = CGPoint(x: 0.5, y: 0.28)
    var scoredAt: CGFloat = -1
    var scoredAtPos: CGPoint = .zero
    var splashes: [TargetSplash] = []
    var score = 0
    var tapsLeft = targetTaps
    private var overAt: CGFloat = -1
    /// Raised on the frame a duckling lands, and taken by the view for a buzz.
    private var scored = false

    func takeScored() -> Bool {
        defer { scored = false }
        return scored
    }

    func splash(at: CGPoint) {
        splashes.append(TargetSplash(at: at, born: time))
        let dir = awayEighth(pos, at)
        let push = splashPush(span(pos, at, aspect))
        vel.dx += dir.dx * push
        vel.dy += dir.dy * push
    }

    private func settled() -> Bool { sqrt(vel.dx * vel.dx + vel.dy * vel.dy) <= targetStill }

    /// One frame.
    func step(dt: CGFloat) {
        splashes.removeAll { time - $0.born > 0.9 }

        let keep = min(max(1 - targetFriction * dt, 0), 1)
        vel.dx *= keep
        vel.dy *= keep
        var p = CGPoint(x: pos.x + vel.dx * dt, y: pos.y + vel.dy * dt)
        if p.x < targetLeft { p.x = targetLeft; vel.dx = -vel.dx * 0.55 }
        if p.x > targetRight { p.x = targetRight; vel.dx = -vel.dx * 0.55 }
        if p.y < targetTop { p.y = targetTop; vel.dy = -vel.dy * 0.55 }
        if p.y > targetBottom { p.y = targetBottom; vel.dy = -vel.dy * 0.55 }
        pos = p

        // Scored on arrival, not on the tap: what counts is where the duckling
        // actually got to, and a glide that passes through the pad counts.
        if span(pos, target, aspect) < targetRadius {
            scoredAt = time
            scoredAtPos = target
            score += 1
            // Never on top of the duckling: a point you score by not moving is
            // not a point.
            var next = target
            var tries = 0
            repeat {
                next = CGPoint(
                    x: CGFloat.random(in: targetLeft...targetRight),
                    y: CGFloat.random(in: targetTop...targetBottom)
                )
                tries += 1
            } while tries < 16 && span(next, pos, aspect) <= targetClearance
            target = next
            scored = true
        }

        // The last splash is not the last chance: whatever it set gliding may
        // still find the pad, so the run ends when the water does.
        if overAt < 0 && tapsLeft <= 0 && settled() { overAt = time }
        if overAt >= 0 && time - overAt >= 0.7 {
            finish(score)
            overAt = -1
        }
    }
}

/// A unit push away from `tap`, snapped to one of the eight compass directions.
///
/// Snapping to eight rather than pushing along the exact vector is the point.
/// The real game moves floaters on a grid, and a toy that shoved them along any
/// angle at all would teach a rule PondPulse does not have. Only the *direction*
/// is snapped - how hard the shove is comes from how close the tap was, exactly
/// as it does on My Pond.
private func awayEighth(_ duck: CGPoint, _ tap: CGPoint) -> CGVector {
    let away = CGVector(dx: duck.x - tap.x, dy: duck.y - tap.y)
    let dist = sqrt(away.dx * away.dx + away.dy * away.dy)
    let angle = dist < 0.001 ? 0 : atan2(away.dy, away.dx)
    let eighth = CGFloat.pi / 4
    let snapped = (angle / eighth).rounded() * eighth
    return CGVector(dx: cos(snapped), dy: sin(snapped))
}

/// Kept for the direction snap's own sanity check.
func splashDirectionIndex(_ duck: CGPoint, _ tap: CGPoint) -> Int {
    let away = CGVector(dx: duck.x - tap.x, dy: duck.y - tap.y)
    if sqrt(away.dx * away.dx + away.dy * away.dy) < 0.001 { return 0 }
    let eighth = CGFloat.pi / 4
    let raw = Int((atan2(away.dy, away.dx) / eighth).rounded())
    return ((raw % 8) + 8) % 8
}
