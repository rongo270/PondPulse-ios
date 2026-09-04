//
//  FloaterArtPremium.swift
//  PondPulse
//
//  The four friends that come with the two paid themes.
//
//  Every theme but the two free ones hands over a pair, and the pair is the only
//  door to them - so these are drawn to the standard of the legendary shelf
//  rather than the common one. Each is built from the same primitives as the
//  rest of the cast (`oval`, `circle`, `polygon`, `ink` for the eye) so they sit
//  on the same water without looking imported.
//

import SwiftUI

// MARK: - Opal Lagoon

/// An opal koi: pearl-white, with three pale patches that never quite agree on
/// a colour.
///
/// The iridescence is a cheat and has to be - a `Canvas` fill cannot shift hue
/// along a fish - so it is three overlapping translucent patches in mint,
/// orchid and periwinkle over a white body. Overlapped at low opacity they mix
/// into a fourth colour in the middle, which is what an opal actually does.
nonisolated func drawOpalKoi(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xFDF7FB))
    let mint = Color(hex: 0x9BE0D2)
    let orchid = Color(hex: 0xD9A6E0)
    let peri = Color(hex: 0xA9BCEF)

    // Tail first, so the body lands on top of its root.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.13, y: c.y),
            CGPoint(x: c.x - cell * 0.45, y: c.y - cell * 0.19),
            CGPoint(x: c.x - cell * 0.33, y: c.y),
            CGPoint(x: c.x - cell * 0.45, y: c.y + cell * 0.19),
        ]),
        with: .color(peri.opacity(0.72))
    )
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.14), CGSize(width: cell * 0.60, height: cell * 0.30)), with: .color(body.shaded(0.93)))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.16), CGSize(width: cell * 0.58, height: cell * 0.28)), with: .color(body))

    // The three patches, overlapping on purpose.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.14, y: c.y - cell * 0.15), CGSize(width: cell * 0.24, height: cell * 0.17)), with: .color(mint.opacity(0.55)))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.02, y: c.y - cell * 0.11), CGSize(width: cell * 0.22, height: cell * 0.18)), with: .color(orchid.opacity(0.50)))
    ctx.fill(oval(CGPoint(x: c.x + cell * 0.08, y: c.y - cell * 0.06), CGSize(width: cell * 0.18, height: cell * 0.14)), with: .color(peri.opacity(0.45)))

    // One hard white highlight along the back: the flash off a polished stone.
    ctx.stroke(
        ovalArc(CGPoint(x: c.x - cell * 0.02, y: c.y - cell * 0.05), CGSize(width: cell * 0.34, height: cell * 0.16), start: 190, sweep: 140, useCenter: false),
        with: .color(.white.opacity(0.85)), style: stroke(cell * 0.028, cap: .round)
    )
    // A dorsal fin, and the eye.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.04, y: c.y - cell * 0.14),
            CGPoint(x: c.x + cell * 0.06, y: c.y - cell * 0.26),
            CGPoint(x: c.x + cell * 0.12, y: c.y - cell * 0.13),
        ]),
        with: .color(orchid.opacity(0.8))
    )
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.27, y: c.y - cell * 0.03), cell * 0.028), with: .color(ink))
}

/// A pearl swan: the swan silhouette, in mother-of-pearl.
///
/// Read against `drawSwan` it is the same bird - same neck curve, same tail -
/// because a paid friend that changed the shape would stop reading as a swan.
/// What it changes is the surface: a sheen up the neck and a shell-pink bill.
nonisolated func drawPearlSwan(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xFFFBFE))
    let sheen = Color(hex: 0xD6C2EA)
    let bill = Color(hex: 0xF3A6B8)

    ctx.fill(oval(CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.08), CGSize(width: cell * 0.62, height: cell * 0.30)), with: .color(body.shaded(0.94)))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.10), CGSize(width: cell * 0.60, height: cell * 0.28)), with: .color(body))
    // The wing, as a single lifted arc washed in the sheen colour.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.14), CGSize(width: cell * 0.34, height: cell * 0.20)), with: .color(sheen.opacity(0.45)))

    // Neck: an S from the shoulder up to the head.
    var neck = Path()
    neck.move(to: CGPoint(x: c.x + cell * 0.10, y: c.y - cell * 0.02))
    neck.addQuadCurve(
        to: CGPoint(x: c.x + cell * 0.24, y: c.y - cell * 0.30),
        control: CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.12)
    )
    ctx.stroke(neck, with: .color(body), style: stroke(cell * 0.10, cap: .round))
    ctx.stroke(neck, with: .color(sheen.opacity(0.35)), style: stroke(cell * 0.04, cap: .round))

    ctx.fill(circle(CGPoint(x: c.x + cell * 0.25, y: c.y - cell * 0.32), cell * 0.085), with: .color(body))
    ctx.fill(
        polygon([
            CGPoint(x: c.x + cell * 0.32, y: c.y - cell * 0.34),
            CGPoint(x: c.x + cell * 0.45, y: c.y - cell * 0.30),
            CGPoint(x: c.x + cell * 0.32, y: c.y - cell * 0.27),
        ]),
        with: .color(bill)
    )
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.28, y: c.y - cell * 0.34), cell * 0.024), with: .color(ink))
}

// MARK: - Ember Hollow

/// An ember drake: a charcoal water-dragon with a lit belly.
///
/// The glow is drawn as three passes of the same shape at falling opacity and
/// rising size rather than as a blur, because `Canvas` shadows cost a layer per
/// floater and there can be eight of them on the pond at once.
nonisolated func drawEmberDrake(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x3A2B2A))
    let ember = Color(hex: 0xFF8A2B)
    let hot = Color(hex: 0xFFD27A)

    // The heat coming off it, before anything solid.
    for (i, spread) in [(0, 0.46), (1, 0.38), (2, 0.30)] {
        ctx.fill(
            oval(CGPoint(x: c.x - cell * CGFloat(spread) / 2, y: c.y + cell * 0.02 - cell * CGFloat(spread) / 4),
                 CGSize(width: cell * CGFloat(spread), height: cell * CGFloat(spread) / 2)),
            with: .color(ember.opacity(0.10 + 0.05 * Double(i)))
        )
    }

    // Spines along the back, hottest at the shoulder.
    for i in 0..<4 {
        let t = CGFloat(i) / 3
        let x = c.x - cell * 0.20 + cell * 0.36 * t
        let h = cell * (0.20 - 0.05 * t)
        ctx.fill(
            polygon([
                CGPoint(x: x - cell * 0.05, y: c.y - cell * 0.09),
                CGPoint(x: x, y: c.y - cell * 0.09 - h),
                CGPoint(x: x + cell * 0.05, y: c.y - cell * 0.09),
            ]),
            with: .color(ember.opacity(1 - Double(t) * 0.45))
        )
    }

    ctx.fill(oval(CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.12), CGSize(width: cell * 0.62, height: cell * 0.30)), with: .color(body.shaded(0.85)))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.14), CGSize(width: cell * 0.60, height: cell * 0.28)), with: .color(body))
    // The lit seam down the flank - the whole reason it is not just a dark fish.
    ctx.stroke(
        ovalArc(CGPoint(x: c.x - cell * 0.04, y: c.y + cell * 0.01), CGSize(width: cell * 0.46, height: cell * 0.18), start: 20, sweep: 140, useCenter: false),
        with: .color(hot), style: stroke(cell * 0.035, cap: .round)
    )

    // Neck and head, carried forward the way the swan's is.
    var neck = Path()
    neck.move(to: CGPoint(x: c.x + cell * 0.12, y: c.y - cell * 0.04))
    neck.addQuadCurve(
        to: CGPoint(x: c.x + cell * 0.26, y: c.y - cell * 0.26),
        control: CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.10)
    )
    ctx.stroke(neck, with: .color(body), style: stroke(cell * 0.10, cap: .round))
    ctx.fill(oval(CGPoint(x: c.x + cell * 0.18, y: c.y - cell * 0.34), CGSize(width: cell * 0.22, height: cell * 0.16)), with: .color(body))
    // Horn, and an eye that is the only cold thing on it.
    ctx.fill(
        polygon([
            CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.33),
            CGPoint(x: c.x + cell * 0.19, y: c.y - cell * 0.46),
            CGPoint(x: c.x + cell * 0.29, y: c.y - cell * 0.34),
        ]),
        with: .color(ember)
    )
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.31, y: c.y - cell * 0.28), cell * 0.030), with: .color(hot))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.32, y: c.y - cell * 0.28), cell * 0.014), with: .color(ink))
}

/// A cinder moth: charcoal wings edged in ember, with two lit eyespots.
///
/// The only floater in the game whose silhouette is wider than it is long, which
/// is deliberate - on a pond of ducks and fish, a moth resting on the water
/// reads immediately as something that does not belong there and is worth
/// looking at.
nonisolated func drawCinderMoth(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x33262B))
    let ember = Color(hex: 0xFF8A2B)
    let ash = Color(hex: 0x6E5A5E)

    for side in [-1.0, 1.0] as [CGFloat] {
        // Hind wing, then fore wing, so the fore wing's edge reads on top.
        ctx.fill(
            oval(CGPoint(x: c.x - cell * 0.02, y: c.y + (side < 0 ? -cell * 0.30 : cell * 0.02)),
                 CGSize(width: cell * 0.30, height: cell * 0.28)),
            with: .color(body.shaded(0.85))
        )
        var fore = Path()
        fore.move(to: CGPoint(x: c.x, y: c.y))
        fore.addQuadCurve(
            to: CGPoint(x: c.x - cell * 0.36, y: c.y + cell * 0.16 * side),
            control: CGPoint(x: c.x - cell * 0.12, y: c.y + cell * 0.32 * side)
        )
        fore.addQuadCurve(
            to: CGPoint(x: c.x, y: c.y),
            control: CGPoint(x: c.x - cell * 0.18, y: c.y + cell * 0.04 * side)
        )
        ctx.fill(fore, with: .color(body))
        ctx.stroke(fore, with: .color(ember.opacity(0.9)), style: stroke(cell * 0.022))
        // The eyespot: a coal that has not gone out.
        let eye = CGPoint(x: c.x - cell * 0.17, y: c.y + cell * 0.15 * side)
        ctx.fill(circle(eye, cell * 0.055), with: .color(ash))
        ctx.fill(circle(eye, cell * 0.030), with: .color(ember))
    }

    // Body and antennae.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.06, y: c.y - cell * 0.12), CGSize(width: cell * 0.20, height: cell * 0.24)), with: .color(body.shaded(0.9)))
    for side in [-1.0, 1.0] as [CGFloat] {
        var feeler = Path()
        feeler.move(to: CGPoint(x: c.x + cell * 0.06, y: c.y + cell * 0.03 * side))
        feeler.addQuadCurve(
            to: CGPoint(x: c.x + cell * 0.30, y: c.y + cell * 0.16 * side),
            control: CGPoint(x: c.x + cell * 0.22, y: c.y + cell * 0.02 * side)
        )
        ctx.stroke(feeler, with: .color(ash), style: stroke(cell * 0.018, cap: .round))
    }
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.09, y: c.y - cell * 0.05), cell * 0.026), with: .color(ember))
}
