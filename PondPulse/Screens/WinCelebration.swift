//
//  WinCelebration.swift
//  PondPulse
//
//  A short burst of joy for a solved pond: confetti rains while the equipped
//  floater pops in and does a full happy spin. Purely decorative - sits behind
//  the win card, which slides in a moment later. Port of Android's
//  WinCelebration.kt with the same timings.
//

import SwiftUI

private struct ConfettiPiece {
    let startX: CGFloat
    let startY: CGFloat
    let fall: CGFloat
    let swayAmp: CGFloat
    let swayFreq: CGFloat
    let phase: CGFloat
    let spin: CGFloat
    let sizeFactor: CGFloat
    let round: Bool
    let colorIndex: Int

    init(seed: UInt64, colorCount: Int) {
        var rng = SplitMix64(seed: seed)
        startX = rng.unit()
        startY = -0.15 * rng.unit()
        fall = 0.75 + rng.unit() * 0.65
        swayAmp = 0.02 + rng.unit() * 0.05
        swayFreq = 6 + rng.unit() * 6
        phase = rng.unit() * 6.28
        spin = (rng.unit() - 0.5) * 900
        sizeFactor = 0.010 + rng.unit() * 0.012
        round = rng.unit() < 0.5
        colorIndex = Int(rng.next() % UInt64(colorCount))
    }
}

/// Tiny deterministic RNG so the confetti shower is stable per piece.
private struct SplitMix64 {
    var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> CGFloat {
        CGFloat(next() >> 11) / CGFloat(1 << 53)
    }
}

struct WinCelebration: View {
    let skinId: String

    @Environment(\.palette) private var palette
    @State private var start = Date()

    var body: some View {
        let confettiColors: [Color] = [
            palette.accent,
            palette.star,
            palette.ripple,
            Color(hex: 0xFF7B6E),
            Color(hex: 0x7BE08A),
            Color(hex: 0x6FB9FF),
        ]
        let confetti = (0..<70).map { ConfettiPiece(seed: UInt64($0) &* 977, colorCount: confettiColors.count) }

        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                let t = CGFloat(min(elapsed / 1.8, 1))
                // Everything fades out together over the last stretch.
                let fade = min(max((1 - t) / 0.25, 0), 1)

                for piece in confetti {
                    let y = (piece.startY + piece.fall * t) * size.height
                    if y < -20 || y > size.height + 20 { continue }
                    let x = (piece.startX + piece.swayAmp * sin(t * piece.swayFreq + piece.phase)) * size.width
                    let side = min(size.width, size.height) * piece.sizeFactor
                    let color = confettiColors[piece.colorIndex].opacity(fade)
                    if piece.round {
                        let r = side * 0.6
                        ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(color))
                    } else {
                        var rc = ctx
                        rc.translateBy(x: x, y: y)
                        rc.rotate(by: .degrees(piece.phase * 57 + t * piece.spin))
                        rc.fill(
                            Path(CGRect(x: -side / 2, y: -side * 0.8, width: side, height: side * 1.6)),
                            with: .color(color)
                        )
                    }
                }

                // The hero of the pond, spinning once in the middle; shrinks away at the end.
                let spin = 360 * easeInOut(CGFloat(min(elapsed / 1.0, 1)))
                let pop = springPop(CGFloat(elapsed))
                let heroSide = min(size.width, size.height) * 0.34 * pop * fade
                if heroSide > 1 {
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let glowR = heroSide * 0.72
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center.x - glowR, y: center.y - glowR, width: glowR * 2, height: glowR * 2)),
                        with: .color(palette.ripple.opacity(0.18 * fade * pop))
                    )
                    var rc = ctx
                    rc.translateBy(x: center.x, y: center.y)
                    rc.rotate(by: .degrees(spin))
                    rc.translateBy(x: -center.x, y: -center.y)
                    let heroRect = CGRect(
                        x: center.x - heroSide / 2, y: center.y - heroSide / 2,
                        width: heroSide, height: heroSide
                    )
                    drawFloaterSkin(&rc, skinId: skinId, rect: heroRect, palette: palette, color: nil)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear { start = Date() }
    }

    private func easeInOut(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }

    /// Underdamped spring matching Compose spring(dampingRatio 0.55, medium stiffness).
    private func springPop(_ t: CGFloat) -> CGFloat {
        let zeta: CGFloat = 0.55
        let omega0: CGFloat = sqrt(1500)
        let omegaD = omega0 * sqrt(1 - zeta * zeta)
        let decay = exp(-zeta * omega0 * t)
        return max(0, 1 - decay * (cos(omegaD * t) + (zeta * omega0 / omegaD) * sin(omegaD * t)))
    }
}
