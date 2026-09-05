//
//  BoardArt.swift
//  PondPulse
//
//  Water with nothing in it - the page a stage of ponds is laid out on, and the
//  strip across the top of a pack card. Port of the Android ui/art/BoardArt.kt.
//
//  Both of these used to draw the real level maps, which looked good and was the
//  wrong idea: a pond you have solved in your head from the level grid is a pond
//  you no longer have to solve. Nothing in here may read a level.
//
//  What is left is water doing nothing in particular, seeded so a given stage or
//  pack looks the same every time it is drawn - a background that reshuffled
//  itself under the thumb would be worse than a flat colour.
//

import SwiftUI

/// A cheap, stable hash. The same seed always lays the water out the same way.
private nonisolated func jitter(_ seed: Int, _ salt: Int) -> CGFloat {
    var v = UInt32(truncatingIfNeeded: seed &* 73_856_093) ^ UInt32(truncatingIfNeeded: salt &* 19_349_663)
    v ^= v >> 13
    v = v &* 1_274_126_177
    return CGFloat((v >> 8) & 0xFFFF) / 65_535
}

/// Bands of light and a scatter of rings, over a vertical gradient.
///
/// `rings` and `bands` scale with how much water there is: a strip 60pt tall
/// wants two bands and three rings, and a whole page wants a dozen of each, or
/// the top of the screen is busy and the bottom is a flat slab.
private nonisolated func drawOpenWater(
    _ ctx: inout GraphicsContext,
    size: CGSize,
    palette: PondPalette,
    seed: Int,
    dim: Double,
    bands: Int,
    rings: Int
) {
    let w = size.width
    let h = size.height
    ctx.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .linearGradient(
            Gradient(stops: [
                .init(color: palette.waterDeep.opacity(dim), location: 0),
                .init(color: palette.water.opacity(dim), location: 0.45),
                .init(color: palette.waterDeep.opacity(dim), location: 1),
            ]),
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: h)
        )
    )
    // Slow bands of light lying across the surface. Horizontal, not diagonal: a
    // diagonal band on a page this tall reads as a crease in the paper.
    for i in 0..<bands {
        let y = h * (CGFloat(i) + 0.35 + jitter(seed, i) * 0.3) / CGFloat(bands)
        ctx.fill(
            Path(CGRect(x: 0, y: y, width: w, height: h * 0.021)),
            with: .color(palette.ripple.opacity(0.05 * dim))
        )
    }
    for i in 0..<rings {
        let cx = w * (0.06 + jitter(seed, 100 + i) * 0.88)
        let cy = h * (0.05 + jitter(seed, 200 + i) * 0.9)
        let r = w * (0.03 + jitter(seed, 300 + i) * 0.07)
        ctx.stroke(
            Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
            with: .color(palette.ripple.opacity(0.09 * dim)),
            lineWidth: w * 0.004 + 1
        )
    }
}

/// The page a stage of ponds is laid out on: open water, banked top and bottom.
///
/// The banks are thin - `bank` points each - because this is a menu standing on
/// water, not the pond itself. They are what stops the water from reading as a
/// blue rectangle somebody forgot to fill in, and the reeds along them are what
/// stop the banks from reading as two beige stripes.
nonisolated func drawStagePond(
    _ ctx: inout GraphicsContext,
    size: CGSize,
    palette: PondPalette,
    seed: Int,
    bank: CGFloat
) {
    let w = size.width
    let h = size.height
    guard w > 0, h > 0 else { return }
    drawOpenWater(&ctx, size: size, palette: palette, seed: seed, dim: 1, bands: 7, rings: 11)

    let (bankLit, bankDark) = shoreTones("meadow", palette)
    // A fixed depth rather than a share of the height, because the page has to
    // leave room for it above the first row of pads - and a bank that grew with
    // the screen would bury that row on a tall phone and float free of it on a
    // short one.
    let depth = bank
    for top in [true, false] {
        var edge = Path()
        edge.move(to: CGPoint(x: 0, y: top ? 0 : h))
        for step in 0...24 {
            let x = CGFloat(step) / 24
            let wave = sin(x * 3.2 * .pi + (top ? 0.4 : 2.1)) * depth * 0.32
            let y = top ? depth + wave : h - depth + wave
            edge.addLine(to: CGPoint(x: x * w, y: y))
        }
        edge.addLine(to: CGPoint(x: w, y: top ? 0 : h))
        edge.closeSubpath()
        ctx.fill(
            edge,
            with: .linearGradient(
                Gradient(colors: [bankLit, bankDark]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: h)
            )
        )
        // Reeds, standing on the waterline and leaning off it.
        let reed = bankLit.blended(palette.pad, 0.55).opacity(0.7)
        for i in 0..<14 {
            let x = CGFloat((i * 37) % 100) / 100
            let wave = sin(x * 3.2 * .pi + (top ? 0.4 : 2.1)) * depth * 0.32
            let y = top ? depth + wave : h - depth + wave
            let len = depth * (0.35 + jitter(seed, i + (top ? 0 : 50)) * 0.5)
            var stem = Path()
            stem.move(to: CGPoint(x: x * w, y: y))
            stem.addLine(to: CGPoint(x: x * w + len * 0.25, y: top ? y + len : y - len))
            ctx.stroke(stem, with: .color(reed), style: StrokeStyle(lineWidth: w * 0.005, lineCap: .round))
        }
    }
}

/// A pack card's strip: water and a lily pad or two, and nothing that gives a
/// pond away.
///
/// `shade` is the pack's place on the difficulty ladder, 0 for the gentlest and
/// 1 for the hardest. It is the one thing that legitimately separates one pack
/// from another without showing a level, so the water deepens with it: the last
/// packs are darker water than the first. The card already says "Very hard" in
/// words; this says it again in a way you take in without reading.
nonisolated func drawPackWater(
    _ ctx: inout GraphicsContext,
    size: CGSize,
    palette: PondPalette,
    padId: String,
    seed: Int,
    shade: CGFloat,
    dim: Double = 1
) {
    let w = size.width
    let h = size.height
    guard w > 0, h > 0 else { return }
    drawOpenWater(&ctx, size: size, palette: palette, seed: seed, dim: dim, bands: 2, rings: 4)
    // Deeper water for a harder pack, laid over rather than mixed in, so every
    // palette darkens by the same amount rather than by whatever its own two
    // water tones happen to be apart.
    if shade > 0 {
        ctx.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(palette.waterDeep.opacity(0.55 * Double(shade) * dim))
        )
    }
    // One to three pads, never in a row, never the same for two packs running.
    let count = 1 + seed % 3
    for i in 0..<count {
        let side = h * (0.36 + jitter(seed, 400 + i) * 0.18)
        // Kept comfortably clear of every edge, not merely touching it. Placed
        // by fraction alone the taller pads hung over the top of the strip, and
        // a pad whose rim sits exactly on the edge reads as one somebody
        // cropped - the card's own rounded corner finishes the job.
        let margin = side * 0.68
        let cx = min(max(w * (0.12 + jitter(seed, 500 + i) * 0.76), margin), max(w - margin, margin))
        let cy = min(max(h * (0.25 + jitter(seed, 600 + i) * 0.5), margin), max(h - margin, margin))
        drawPadStyle(
            &ctx,
            padId: padId,
            rect: CGRect(x: cx - side / 2, y: cy - side / 2, width: side, height: side),
            palette: palette,
            ring: nil
        )
    }
}
