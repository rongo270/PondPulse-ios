//
//  FloaterArtThemed.swift
//  PondPulse
//
//  The twenty theme pairs - a 1:1 port of the Android ui/FloaterArtThemed.kt.
//
//  Same rules as the two shelves before it: everything in multiples of `cell`,
//  every body colour through `bodyTint` so a red, green or blue puzzle duckling
//  stays readable, and silhouette carrying the whole read at one grid cell.
//
//  One extra rule applies here and nowhere else. A theme friend has to look like
//  it *came from* its theme while still being legible on every other one, so the
//  theme's signature colour is used for a small, decisive part - the toucan's
//  bill, the comet duck's tail, the neon tetra's stripe - and never for the
//  whole body. A friend painted entirely in its own theme's palette disappears
//  the moment it is taken anywhere else, which is the one thing a friend you
//  unlocked must never do.
//

import SwiftUI

// MARK: - Jungle Mist

/// Half beak. The bill is the whole silhouette, so it is drawn biggest.
nonisolated func drawToucan(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x23303A))
    let dark = body.shaded()
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.04), CGSize(width: cell * 0.52, height: cell * 0.34)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y - cell * 0.10), CGSize(width: cell * 0.48, height: cell * 0.30)), with: .color(body))
    // Tail, straight up and stubby, so the bird is not a horizontal blob.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.04),
            CGPoint(x: c.x - cell * 0.40, y: c.y - cell * 0.28),
            CGPoint(x: c.x - cell * 0.18, y: c.y - cell * 0.16),
        ]),
        with: .color(dark)
    )
    let head = CGPoint(x: c.x + cell * 0.10, y: c.y - cell * 0.18)
    ctx.fill(circle(head, cell * 0.155), with: .color(body))
    // White bib, which is what stops the black head reading as a hole.
    ctx.fill(oval(CGPoint(x: head.x - cell * 0.02, y: head.y + cell * 0.02), CGSize(width: cell * 0.20, height: cell * 0.20)), with: .color(Color(hex: 0xF6F1E4)))
    // The bill: the jungle's own yellow-green, curving down to a point.
    var bill = Path()
    bill.move(to: CGPoint(x: head.x + cell * 0.06, y: head.y - cell * 0.08))
    bill.addQuadCurve(to: CGPoint(x: head.x + cell * 0.48, y: head.y + cell * 0.06), control: CGPoint(x: head.x + cell * 0.42, y: head.y - cell * 0.10))
    bill.addQuadCurve(to: CGPoint(x: head.x + cell * 0.06, y: head.y + cell * 0.07), control: CGPoint(x: head.x + cell * 0.30, y: head.y + cell * 0.12))
    bill.closeSubpath()
    ctx.fill(bill, with: .color(Color(hex: 0xE9B23A)))
    var tip = Path()
    tip.move(to: CGPoint(x: head.x + cell * 0.30, y: head.y - cell * 0.055))
    tip.addQuadCurve(to: CGPoint(x: head.x + cell * 0.48, y: head.y + cell * 0.06), control: CGPoint(x: head.x + cell * 0.45, y: head.y - cell * 0.04))
    tip.addQuadCurve(to: CGPoint(x: head.x + cell * 0.30, y: head.y + cell * 0.02), control: CGPoint(x: head.x + cell * 0.38, y: head.y + cell * 0.09))
    tip.closeSubpath()
    ctx.fill(tip, with: .color(Color(hex: 0xD1502F)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.01, y: head.y - cell * 0.05), cell * 0.055), with: .color(Color(hex: 0xF6F1E4)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.02, y: head.y - cell * 0.05), cell * 0.030), with: .color(ink))
}

/// A red-eyed tree frog clinging to the surface, toes splayed wide.
nonisolated func drawTreeFrog(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x57C25B))
    let dark = body.shaded()
    // Legs first: four splayed limbs with round toe pads.
    for sx in [-1.0, 1.0] as [CGFloat] {
        for sy in [-1.0, 1.0] as [CGFloat] {
            let knee = CGPoint(x: c.x + cell * 0.20 * sx, y: c.y + cell * 0.10 * sy)
            let foot = CGPoint(x: c.x + cell * 0.40 * sx, y: c.y + cell * 0.20 * sy)
            ctx.stroke(line(knee, foot), with: .color(dark), style: stroke(cell * 0.055))
            for toe in -1...1 {
                ctx.fill(
                    circle(CGPoint(x: foot.x + cell * 0.06 * sx, y: foot.y + cell * 0.06 * CGFloat(toe)), cell * 0.036),
                    with: .color(body.lightened(1.15))
                )
            }
        }
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.14), CGSize(width: cell * 0.56, height: cell * 0.36)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.18), CGSize(width: cell * 0.56, height: cell * 0.34)), with: .color(body))
    // Blue flanks, the mark of the species.
    for sx in [-1.0, 1.0] as [CGFloat] {
        ctx.fill(
            oval(CGPoint(x: c.x + cell * (0.10 * sx - 0.06), y: c.y + cell * 0.02), CGSize(width: cell * 0.12, height: cell * 0.10)),
            with: .color(Color(hex: 0x4A6BD8).opacity(0.75))
        )
    }
    // Red eyes on stalks: the one thing nothing else in the pond has.
    for sx in [-1.0, 1.0] as [CGFloat] {
        let eye = CGPoint(x: c.x + cell * 0.15 * sx, y: c.y - cell * 0.22)
        ctx.fill(circle(eye, cell * 0.115), with: .color(body))
        ctx.fill(circle(eye, cell * 0.082), with: .color(Color(hex: 0xE23B3B)))
        ctx.fill(circle(eye, cell * 0.030), with: .color(ink))
        ctx.fill(circle(CGPoint(x: eye.x - cell * 0.028, y: eye.y - cell * 0.028), cell * 0.020), with: .color(Color.white.opacity(0.8)))
    }
}

// MARK: - Golden Pond

/// A mandarin drake: the sail fin on its back is the whole silhouette.
nonisolated func drawMandarin(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xE8A33C))
    let dark = body.shaded()
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y - cell * 0.04), CGSize(width: cell * 0.56, height: cell * 0.30)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.10), CGSize(width: cell * 0.52, height: cell * 0.28)), with: .color(body))
    // The sail: one orange fin standing straight up off the back.
    var sail = Path()
    sail.move(to: CGPoint(x: c.x - cell * 0.08, y: c.y - cell * 0.06))
    sail.addQuadCurve(to: CGPoint(x: c.x + cell * 0.12, y: c.y - cell * 0.34), control: CGPoint(x: c.x - cell * 0.06, y: c.y - cell * 0.40))
    sail.addQuadCurve(to: CGPoint(x: c.x + cell * 0.10, y: c.y - cell * 0.04), control: CGPoint(x: c.x + cell * 0.06, y: c.y - cell * 0.12))
    sail.closeSubpath()
    ctx.fill(sail, with: .color(Color(hex: 0xD9722C)))
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.02),
            CGPoint(x: c.x - cell * 0.46, y: c.y - cell * 0.10),
            CGPoint(x: c.x - cell * 0.26, y: c.y + cell * 0.08),
        ]),
        with: .color(dark)
    )
    let head = CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.16)
    ctx.fill(circle(head, cell * 0.145), with: .color(Color(hex: 0x7C4A9E)))
    // Cream cheek stripe and green crest, the two marks that make it mandarin.
    ctx.fill(oval(CGPoint(x: head.x - cell * 0.02, y: head.y - cell * 0.01), CGSize(width: cell * 0.16, height: cell * 0.09)), with: .color(Color(hex: 0xF6EBD2)))
    var crest = Path()
    crest.move(to: CGPoint(x: head.x - cell * 0.12, y: head.y - cell * 0.06))
    crest.addQuadCurve(to: CGPoint(x: head.x + cell * 0.10, y: head.y - cell * 0.10), control: CGPoint(x: head.x - cell * 0.02, y: head.y - cell * 0.26))
    crest.closeSubpath()
    ctx.fill(crest, with: .color(Color(hex: 0x2F7A5A)))
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.10, y: head.y + cell * 0.01),
            CGPoint(x: head.x + cell * 0.30, y: head.y + cell * 0.05),
            CGPoint(x: head.x + cell * 0.10, y: head.y + cell * 0.08),
        ]),
        with: .color(Color(hex: 0xE0524A))
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.03), cell * 0.028), with: .color(ink))
}

/// A fantail goldfish: the veil tail is half the fish.
nonisolated func drawGoldfish(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xF2892F))
    let pale = body.lightened(1.30)
    // Three veils, each a wide closed lobe built on its own axis rather than a
    // sliver - the first pass collapsed to two stray whiskers.
    let root = CGPoint(x: c.x - cell * 0.08, y: c.y)
    for a in [2.32, 3.14, 3.96] as [CGFloat] {
        let dir = CGPoint(x: cos(a), y: sin(a))
        let across = CGPoint(x: -dir.y, y: dir.x)
        let len = cell * 0.40
        let tip = CGPoint(x: root.x + dir.x * len, y: root.y + dir.y * len)
        let fat = cell * 0.13
        var veil = Path()
        veil.move(to: root)
        veil.addQuadCurve(to: tip, control: CGPoint(x: root.x + dir.x * len * 0.6 + across.x * fat, y: root.y + dir.y * len * 0.6 + across.y * fat))
        veil.addQuadCurve(to: root, control: CGPoint(x: root.x + dir.x * len * 0.6 - across.x * fat, y: root.y + dir.y * len * 0.6 - across.y * fat))
        veil.closeSubpath()
        ctx.fill(veil, with: .color(pale.opacity(0.68)))
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.14, y: c.y - cell * 0.15), CGSize(width: cell * 0.50, height: cell * 0.33)), with: .color(body.shaded()))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.14, y: c.y - cell * 0.18), CGSize(width: cell * 0.48, height: cell * 0.30)), with: .color(body))
    // A pale saddle, so a plain orange oval has something to read as scales.
    ctx.fill(oval(CGPoint(x: c.x + cell * 0.04, y: c.y - cell * 0.13), CGSize(width: cell * 0.20, height: cell * 0.12)), with: .color(pale.opacity(0.55)))
    // A dorsal fin, so it is a fish from above and not a leaf.
    var dorsal = Path()
    dorsal.move(to: CGPoint(x: c.x + cell * 0.02, y: c.y - cell * 0.16))
    dorsal.addQuadCurve(to: CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.14), control: CGPoint(x: c.x + cell * 0.10, y: c.y - cell * 0.34))
    dorsal.closeSubpath()
    ctx.fill(dorsal, with: .color(pale.opacity(0.8)))
    // Bulging eyes on the sides of the head.
    for sy in [-1.0, 1.0] as [CGFloat] {
        let eye = CGPoint(x: c.x + cell * 0.27, y: c.y + cell * 0.085 * sy - cell * 0.03)
        ctx.fill(circle(eye, cell * 0.055), with: .color(pale))
        ctx.fill(circle(eye, cell * 0.030), with: .color(ink))
    }
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.33, y: c.y - cell * 0.03), cell * 0.028), with: .color(body.shaded()))
}

// MARK: - Sakura Pond

/// A swallow skimming the surface: forked tail, swept wings.
nonisolated func drawSwallow(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x2E4A7A))
    let dark = body.shaded()
    // Swept wings, one either side, drawn before the body.
    for sy in [-1.0, 1.0] as [CGFloat] {
        var wing = Path()
        wing.move(to: c)
        wing.addQuadCurve(to: CGPoint(x: c.x - cell * 0.34, y: c.y + cell * 0.30 * sy), control: CGPoint(x: c.x - cell * 0.16, y: c.y + cell * 0.34 * sy))
        wing.addQuadCurve(to: c, control: CGPoint(x: c.x - cell * 0.10, y: c.y + cell * 0.14 * sy))
        wing.closeSubpath()
        ctx.fill(wing, with: .color(dark))
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.26, y: c.y - cell * 0.11), CGSize(width: cell * 0.48, height: cell * 0.22)), with: .color(body))
    // The fork, which is the whole silhouette of a swallow.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.20, y: c.y - cell * 0.02),
            CGPoint(x: c.x - cell * 0.48, y: c.y - cell * 0.16),
            CGPoint(x: c.x - cell * 0.30, y: c.y + cell * 0.02),
            CGPoint(x: c.x - cell * 0.46, y: c.y + cell * 0.16),
        ]),
        with: .color(dark)
    )
    let head = CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.06)
    ctx.fill(circle(head, cell * 0.115), with: .color(body))
    // Rust throat - sakura's own pink-red, and the bird's real marking.
    ctx.fill(oval(CGPoint(x: head.x - cell * 0.02, y: head.y + cell * 0.01), CGSize(width: cell * 0.13, height: cell * 0.09)), with: .color(Color(hex: 0xD9707E)))
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.07, y: head.y - cell * 0.02),
            CGPoint(x: head.x + cell * 0.19, y: head.y + cell * 0.01),
            CGPoint(x: head.x + cell * 0.07, y: head.y + cell * 0.04),
        ]),
        with: .color(ink)
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.02, y: head.y - cell * 0.035), cell * 0.026), with: .color(ink))
}

/// A pale koi with blossom-pink markings and one open flower on its back.
nonisolated func drawBlossomKoi(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xFBF1F0))
    let mark = Color(hex: 0xE5809B)
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.14, y: c.y),
            CGPoint(x: c.x - cell * 0.44, y: c.y - cell * 0.20),
            CGPoint(x: c.x - cell * 0.32, y: c.y),
            CGPoint(x: c.x - cell * 0.44, y: c.y + cell * 0.20),
        ]),
        with: .color(mark.opacity(0.75))
    )
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.14), CGSize(width: cell * 0.60, height: cell * 0.30)), with: .color(body.shaded(0.92)))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.16), CGSize(width: cell * 0.58, height: cell * 0.28)), with: .color(body))
    // Two koi blotches and one open blossom, five petals round a gold centre.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.10, y: c.y - cell * 0.14), CGSize(width: cell * 0.16, height: cell * 0.12)), with: .color(mark))
    ctx.fill(oval(CGPoint(x: c.x + cell * 0.16, y: c.y - cell * 0.02), CGSize(width: cell * 0.12, height: cell * 0.10)), with: .color(mark.opacity(0.8)))
    let bloom = CGPoint(x: c.x + cell * 0.05, y: c.y + cell * 0.02)
    for i in 0..<5 {
        let a = CGFloat(i) * (2 * .pi / 5)
        ctx.fill(circle(CGPoint(x: bloom.x + cos(a) * cell * 0.045, y: bloom.y + sin(a) * cell * 0.045), cell * 0.042), with: .color(Color(hex: 0xF9C9D6)))
    }
    ctx.fill(circle(bloom, cell * 0.028), with: .color(Color(hex: 0xE9B23A)))
    for sy in [-1.0, 1.0] as [CGFloat] {
        ctx.fill(circle(CGPoint(x: c.x + cell * 0.30, y: c.y + cell * 0.06 * sy - cell * 0.02), cell * 0.026), with: .color(ink))
    }
}

// MARK: - Midnight Neon

/// A neon tetra: a dark sliver with one electric stripe down its side.
nonisolated func drawNeonTetra(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x20323F))
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.16, y: c.y),
            CGPoint(x: c.x - cell * 0.44, y: c.y - cell * 0.16),
            CGPoint(x: c.x - cell * 0.44, y: c.y + cell * 0.16),
        ]),
        with: .color(Color(hex: 0xE8455E).opacity(0.85))
    )
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.13), CGSize(width: cell * 0.58, height: cell * 0.26)), with: .color(body))
    // The stripe, with a soft halo under it so it actually glows rather than
    // just being a bright line.
    let glow = Color(hex: 0x3FE0FF)
    ctx.stroke(
        line(CGPoint(x: c.x - cell * 0.18, y: c.y - cell * 0.03), CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.03)),
        with: .color(glow.opacity(0.30)), style: stroke(cell * 0.16)
    )
    ctx.stroke(
        line(CGPoint(x: c.x - cell * 0.18, y: c.y - cell * 0.03), CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.03)),
        with: .color(glow), style: stroke(cell * 0.055)
    )
    // A second stripe, red, along the belly aft of the middle.
    ctx.stroke(
        line(CGPoint(x: c.x - cell * 0.10, y: c.y + cell * 0.06), CGPoint(x: c.x + cell * 0.20, y: c.y + cell * 0.06)),
        with: .color(Color(hex: 0xE8455E)), style: stroke(cell * 0.045)
    )
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.28, y: c.y - cell * 0.04), cell * 0.045), with: .color(Color(hex: 0xEAF7FF)))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.29, y: c.y - cell * 0.04), cell * 0.026), with: .color(ink))
}

/// A jellyfish lit from inside, tentacles trailing in bright threads.
nonisolated func drawGlowJelly(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xB56BE8))
    let glow = Color(hex: 0x6BF0E0)
    ctx.fill(circle(CGPoint(x: c.x, y: c.y - cell * 0.06), cell * 0.42), with: .color(body.opacity(0.18)))
    // Threads first, so the bell sits over the top of them.
    for i in -3...3 {
        let x = c.x + cell * 0.065 * CGFloat(i)
        var thread = Path()
        thread.move(to: CGPoint(x: x, y: c.y + cell * 0.02))
        thread.addQuadCurve(
            to: CGPoint(x: x - cell * 0.04 * CGFloat(i), y: c.y + cell * 0.44),
            control: CGPoint(x: x + cell * 0.07 * (i % 2 == 0 ? 1 : -1), y: c.y + cell * 0.22)
        )
        ctx.stroke(thread, with: .color(glow.opacity(0.75)), style: stroke(cell * 0.020))
    }
    var bell = Path()
    bell.move(to: CGPoint(x: c.x - cell * 0.30, y: c.y + cell * 0.04))
    bell.addQuadCurve(to: CGPoint(x: c.x, y: c.y - cell * 0.34), control: CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.34))
    bell.addQuadCurve(to: CGPoint(x: c.x + cell * 0.30, y: c.y + cell * 0.04), control: CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.34))
    // A scalloped hem, which is what stops it reading as a mushroom.
    bell.addQuadCurve(to: CGPoint(x: c.x + cell * 0.10, y: c.y + cell * 0.04), control: CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.04))
    bell.addQuadCurve(to: CGPoint(x: c.x - cell * 0.10, y: c.y + cell * 0.04), control: CGPoint(x: c.x, y: c.y - cell * 0.04))
    bell.addQuadCurve(to: CGPoint(x: c.x - cell * 0.30, y: c.y + cell * 0.04), control: CGPoint(x: c.x - cell * 0.20, y: c.y - cell * 0.04))
    bell.closeSubpath()
    ctx.fill(bell, with: .color(body.opacity(0.82)))
    ctx.stroke(bell, with: .color(glow.opacity(0.55)), style: stroke(cell * 0.022))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.14, y: c.y - cell * 0.26), CGSize(width: cell * 0.28, height: cell * 0.16)), with: .color(glow.opacity(0.45)))
    for sx in [-1.0, 1.0] as [CGFloat] {
        ctx.fill(circle(CGPoint(x: c.x + cell * 0.09 * sx, y: c.y - cell * 0.12), cell * 0.026), with: .color(ink))
    }
}

// MARK: - Autumn Gold

/// A wood duck: the swept crest off the back of the head does the work.
nonisolated func drawWoodDuck(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x9A5C33))
    let dark = body.shaded()
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y - cell * 0.04), CGSize(width: cell * 0.56, height: cell * 0.30)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.10), CGSize(width: cell * 0.52, height: cell * 0.28)), with: .color(body))
    // Pale flank bar, the marking that reads at a glance on the water.
    ctx.fill(
        Path(roundedRect: CGRect(x: c.x - cell * 0.04, y: c.y - cell * 0.02, width: cell * 0.10, height: cell * 0.16), cornerRadius: cell * 0.02),
        with: .color(Color(hex: 0xF3E4C9))
    )
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.02),
            CGPoint(x: c.x - cell * 0.46, y: c.y - cell * 0.08),
            CGPoint(x: c.x - cell * 0.26, y: c.y + cell * 0.08),
        ]),
        with: .color(dark)
    )
    let head = CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.17)
    ctx.fill(circle(head, cell * 0.145), with: .color(Color(hex: 0x2E6E5B)))
    // The crest, sweeping back and down past the shoulder.
    var crest = Path()
    crest.move(to: CGPoint(x: head.x - cell * 0.02, y: head.y - cell * 0.14))
    crest.addQuadCurve(to: CGPoint(x: head.x - cell * 0.26, y: head.y + cell * 0.10), control: CGPoint(x: head.x - cell * 0.26, y: head.y - cell * 0.14))
    crest.addQuadCurve(to: CGPoint(x: head.x - cell * 0.02, y: head.y - cell * 0.02), control: CGPoint(x: head.x - cell * 0.10, y: head.y - cell * 0.02))
    crest.closeSubpath()
    ctx.fill(crest, with: .color(Color(hex: 0x255C4C)))
    // Two white face stripes.
    for dy in [-0.02, 0.06] as [CGFloat] {
        ctx.stroke(
            line(CGPoint(x: head.x - cell * 0.02, y: head.y + cell * dy), CGPoint(x: head.x + cell * 0.11, y: head.y + cell * (dy - 0.02))),
            with: .color(Color(hex: 0xF6F1E4)), style: stroke(cell * 0.022)
        )
    }
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.09, y: head.y),
            CGPoint(x: head.x + cell * 0.30, y: head.y + cell * 0.04),
            CGPoint(x: head.x + cell * 0.09, y: head.y + cell * 0.08),
        ]),
        with: .color(Color(hex: 0xD9534A))
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.03), cell * 0.032), with: .color(Color(hex: 0xE9B23A)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.03), cell * 0.020), with: .color(ink))
}

/// A squirrel riding a maple leaf, tail curled up over its back.
nonisolated func drawSquirrel(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xC2703A))
    let dark = body.shaded()
    // The leaf it is floating on: five lobes off a short stem.
    let leafC = CGPoint(x: c.x, y: c.y + cell * 0.20)
    for i in 0..<5 {
        let a = CGFloat.pi * (0.12 + 0.19 * CGFloat(i))
        ctx.fill(
            oval(CGPoint(x: leafC.x - cos(a) * cell * 0.30 - cell * 0.11, y: leafC.y - sin(a) * cell * 0.10 - cell * 0.06),
                 CGSize(width: cell * 0.22, height: cell * 0.14)),
            with: .color(Color(hex: 0xD1552E))
        )
    }
    ctx.fill(oval(CGPoint(x: leafC.x - cell * 0.26, y: leafC.y - cell * 0.07), CGSize(width: cell * 0.52, height: cell * 0.16)), with: .color(Color(hex: 0xE0763C)))
    // The tail: a fat question mark behind and above the body.
    var tail = Path()
    tail.move(to: CGPoint(x: c.x - cell * 0.10, y: c.y + cell * 0.08))
    tail.addCurve(
        to: CGPoint(x: c.x - cell * 0.06, y: c.y - cell * 0.30),
        control1: CGPoint(x: c.x - cell * 0.46, y: c.y + cell * 0.04),
        control2: CGPoint(x: c.x - cell * 0.40, y: c.y - cell * 0.44)
    )
    tail.addCurve(
        to: CGPoint(x: c.x - cell * 0.10, y: c.y + cell * 0.08),
        control1: CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.30),
        control2: CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.02)
    )
    tail.closeSubpath()
    ctx.fill(tail, with: .color(body.lightened(1.12)))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.14, y: c.y - cell * 0.14), CGSize(width: cell * 0.34, height: cell * 0.30)), with: .color(body))
    let head = CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.18)
    ctx.fill(circle(head, cell * 0.125), with: .color(body))
    for sx in [-0.06, 0.06] as [CGFloat] {
        ctx.fill(oval(CGPoint(x: head.x + cell * sx - cell * 0.035, y: head.y - cell * 0.17), CGSize(width: cell * 0.07, height: cell * 0.10)), with: .color(dark))
    }
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.08, y: head.y + cell * 0.03), cell * 0.045), with: .color(Color(hex: 0xF6E7D2)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.03), cell * 0.026), with: .color(ink))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.11, y: head.y + cell * 0.02), cell * 0.020), with: .color(ink))
    // An acorn, held.
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.16, y: c.y + cell * 0.04), cell * 0.050), with: .color(Color(hex: 0xD8B27A)))
    ctx.fill(
        ovalArc(CGPoint(x: c.x + cell * 0.10, y: c.y - cell * 0.02), CGSize(width: cell * 0.12, height: cell * 0.07), start: 180, sweep: 180, useCenter: true),
        with: .color(Color(hex: 0x7A5231))
    )
}

// MARK: - Frozen Pond

/// A snow goose: white body, black wingtips, pink bill.
nonisolated func drawSnowGoose(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xF7FAFC))
    let dark = body.shaded(0.90)
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.02), CGSize(width: cell * 0.60, height: cell * 0.30)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y - cell * 0.10), CGSize(width: cell * 0.56, height: cell * 0.28)), with: .color(body))
    // Black primaries at the trailing edge - the only way a white bird on
    // white water still has an outline.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.20, y: c.y - cell * 0.02),
            CGPoint(x: c.x - cell * 0.46, y: c.y - cell * 0.12),
            CGPoint(x: c.x - cell * 0.40, y: c.y + cell * 0.04),
            CGPoint(x: c.x - cell * 0.20, y: c.y + cell * 0.06),
        ]),
        with: .color(Color(hex: 0x2A3542))
    )
    let head = CGPoint(x: c.x + cell * 0.24, y: c.y - cell * 0.22)
    var neck = Path()
    neck.move(to: CGPoint(x: c.x + cell * 0.12, y: c.y - cell * 0.04))
    neck.addQuadCurve(to: head, control: CGPoint(x: c.x + cell * 0.16, y: c.y - cell * 0.22))
    neck.addLine(to: CGPoint(x: head.x + cell * 0.06, y: head.y + cell * 0.06))
    neck.addQuadCurve(to: CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.02), control: CGPoint(x: c.x + cell * 0.26, y: c.y - cell * 0.20))
    neck.closeSubpath()
    ctx.fill(neck, with: .color(body))
    ctx.fill(circle(head, cell * 0.115), with: .color(body))
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.06, y: head.y - cell * 0.03),
            CGPoint(x: head.x + cell * 0.25, y: head.y + cell * 0.02),
            CGPoint(x: head.x + cell * 0.06, y: head.y + cell * 0.07),
        ]),
        with: .color(Color(hex: 0xE79AAE))
    )
    ctx.stroke(
        line(CGPoint(x: head.x + cell * 0.10, y: head.y + cell * 0.01), CGPoint(x: head.x + cell * 0.20, y: head.y + cell * 0.03)),
        with: .color(Color(hex: 0x2A3542)), style: stroke(cell * 0.014)
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.02, y: head.y - cell * 0.03), cell * 0.026), with: .color(ink))
}

/// A pale fish under a skin of ice, with frost crystals along its back.
nonisolated func drawIceFish(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xBFE6F4))
    let edge = Color(hex: 0x7FC7E8)
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.14, y: c.y),
            CGPoint(x: c.x - cell * 0.46, y: c.y - cell * 0.22),
            CGPoint(x: c.x - cell * 0.30, y: c.y),
            CGPoint(x: c.x - cell * 0.46, y: c.y + cell * 0.22),
        ]),
        with: .color(body.opacity(0.7))
    )
    // Body drawn as a faceted shard rather than an oval: an ice fish that is
    // smooth is just a pale fish.
    let shard = polygon([
        CGPoint(x: c.x - cell * 0.20, y: c.y - cell * 0.02),
        CGPoint(x: c.x - cell * 0.02, y: c.y - cell * 0.17),
        CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.12),
        CGPoint(x: c.x + cell * 0.34, y: c.y + cell * 0.01),
        CGPoint(x: c.x + cell * 0.18, y: c.y + cell * 0.15),
        CGPoint(x: c.x - cell * 0.10, y: c.y + cell * 0.14),
    ])
    ctx.fill(shard, with: .color(body.opacity(0.85)))
    ctx.stroke(shard, with: .color(edge), style: stroke(cell * 0.018))
    ctx.stroke(line(CGPoint(x: c.x - cell * 0.02, y: c.y - cell * 0.17), CGPoint(x: c.x + cell * 0.06, y: c.y + cell * 0.14)), with: .color(edge.opacity(0.7)), style: stroke(cell * 0.012))
    ctx.stroke(line(CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.12), CGPoint(x: c.x + cell * 0.06, y: c.y + cell * 0.14)), with: .color(edge.opacity(0.7)), style: stroke(cell * 0.012))
    // Frost spikes along the spine.
    for i in 0..<3 {
        let x = c.x - cell * 0.06 + cell * 0.14 * CGFloat(i)
        ctx.fill(
            polygon([
                CGPoint(x: x - cell * 0.04, y: c.y - cell * 0.14),
                CGPoint(x: x, y: c.y - cell * 0.30),
                CGPoint(x: x + cell * 0.04, y: c.y - cell * 0.14),
            ]),
            with: .color(Color(hex: 0xEAF7FF).opacity(0.9))
        )
    }
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.24, y: c.y - cell * 0.02), cell * 0.045), with: .color(Color(hex: 0xEAF7FF)))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.25, y: c.y - cell * 0.02), cell * 0.024), with: .color(ink))
}

// MARK: - Coral Reef

/// A clownfish: three white bands with black piping, and nothing else.
nonisolated func drawClownfish(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xF2792B))
    let band = Color(hex: 0xFDF6EF)
    let dark = Color(hex: 0x221A16)
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.16, y: c.y),
            CGPoint(x: c.x - cell * 0.44, y: c.y - cell * 0.18),
            CGPoint(x: c.x - cell * 0.34, y: c.y),
            CGPoint(x: c.x - cell * 0.44, y: c.y + cell * 0.18),
        ]),
        with: .color(body)
    )
    // Top and bottom fins, then the body over both of them.
    for sy in [-1.0, 1.0] as [CGFloat] {
        var fin = Path()
        fin.move(to: CGPoint(x: c.x - cell * 0.06, y: c.y + cell * 0.06 * sy))
        fin.addQuadCurve(to: CGPoint(x: c.x + cell * 0.16, y: c.y + cell * 0.10 * sy), control: CGPoint(x: c.x + cell * 0.04, y: c.y + cell * 0.28 * sy))
        fin.closeSubpath()
        ctx.fill(fin, with: .color(body))
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.15), CGSize(width: cell * 0.60, height: cell * 0.30)), with: .color(body))
    for (i, dx) in ([-0.10, 0.08, 0.26] as [CGFloat]).enumerated() {
        let w = cell * (0.09 - 0.012 * CGFloat(i))
        ctx.fill(
            Path(roundedRect: CGRect(x: c.x + cell * dx - w * 0.62, y: c.y - cell * 0.16, width: w * 1.24, height: cell * 0.32), cornerRadius: w * 0.4),
            with: .color(dark)
        )
        ctx.fill(
            Path(roundedRect: CGRect(x: c.x + cell * dx - w * 0.5, y: c.y - cell * 0.16, width: w, height: cell * 0.32), cornerRadius: w * 0.4),
            with: .color(band)
        )
    }
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.03), cell * 0.048), with: .color(band))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.31, y: c.y - cell * 0.03), cell * 0.026), with: .color(dark))
}

/// A five-armed starfish, seen from above, dimpled.
nonisolated func drawStarfish(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xE9704E))
    let dark = body.shaded()
    let outer = cell * 0.42
    let inner = cell * 0.17

    func star(_ scale: CGFloat) -> Path {
        var pts: [CGPoint] = []
        for i in 0..<10 {
            let a = -CGFloat.pi / 2 + CGFloat(i) * (CGFloat.pi / 5)
            let r = (i % 2 == 0 ? outer : inner) * scale
            pts.append(CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r))
        }
        return polygon(pts)
    }
    ctx.fill(star(1), with: .color(dark))
    // The same star again, a touch smaller, so it has a rim rather than a line.
    ctx.fill(star(0.88), with: .color(body))
    // Dimples down each arm.
    for i in 0..<5 {
        let a = -CGFloat.pi / 2 + CGFloat(i) * (2 * .pi / 5)
        for t in [0.30, 0.52, 0.72] as [CGFloat] {
            ctx.fill(circle(CGPoint(x: c.x + cos(a) * outer * t, y: c.y + sin(a) * outer * t), cell * 0.026), with: .color(body.lightened(1.22)))
        }
    }
    for sx in [-1.0, 1.0] as [CGFloat] {
        ctx.fill(circle(CGPoint(x: c.x + cell * 0.075 * sx, y: c.y - cell * 0.02), cell * 0.028), with: .color(ink))
    }
    ctx.stroke(
        ovalArc(CGPoint(x: c.x - cell * 0.07, y: c.y + cell * 0.02), CGSize(width: cell * 0.14, height: cell * 0.09), start: 20, sweep: 140, useCenter: false),
        with: .color(ink), style: stroke(cell * 0.016)
    )
}

// MARK: - Galaxy Night

/// A filled five-pointed star. Used as a spark by several of these.
nonisolated func starBurst(_ at: CGPoint, _ r: CGFloat) -> Path {
    var pts: [CGPoint] = []
    for i in 0..<10 {
        let a = -CGFloat.pi / 2 + CGFloat(i) * (CGFloat.pi / 5)
        let rr = i % 2 == 0 ? r : r * 0.42
        pts.append(CGPoint(x: at.x + cos(a) * rr, y: at.y + sin(a) * rr))
    }
    return polygon(pts)
}

/// A duckling with a comet's tail of stars streaming behind it.
nonisolated func drawCometDuck(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x3B3170))
    let dark = body.shaded()
    // The tail: a bright wedge fading out behind, with stars in it.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.18, y: c.y - cell * 0.10),
            CGPoint(x: c.x - cell * 0.50, y: c.y - cell * 0.02),
            CGPoint(x: c.x - cell * 0.18, y: c.y + cell * 0.12),
        ]),
        with: .color(Color(hex: 0x7FE3FF).opacity(0.45))
    )
    for (i, t) in ([0.30, 0.55, 0.80] as [CGFloat]).enumerated() {
        let p = CGPoint(x: c.x - cell * (0.18 + 0.32 * t), y: c.y + cell * (0.02 - 0.06 * CGFloat(i % 2)))
        ctx.fill(starBurst(p, cell * (0.055 - 0.010 * CGFloat(i))), with: .color(Color(hex: 0xDCEFFF)))
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.04), CGSize(width: cell * 0.52, height: cell * 0.30)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.26, y: c.y - cell * 0.10), CGSize(width: cell * 0.48, height: cell * 0.28)), with: .color(body))
    // Constellation freckles on the back.
    for p in [CGPoint(x: -0.10, y: -0.02), CGPoint(x: 0.02, y: 0.04), CGPoint(x: 0.10, y: -0.04)] {
        ctx.fill(circle(CGPoint(x: c.x + cell * p.x, y: c.y + cell * p.y), cell * 0.020), with: .color(Color(hex: 0xDCEFFF)))
    }
    let head = CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.18)
    ctx.fill(circle(head, cell * 0.145), with: .color(body))
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.09, y: head.y - cell * 0.02),
            CGPoint(x: head.x + cell * 0.30, y: head.y + cell * 0.03),
            CGPoint(x: head.x + cell * 0.09, y: head.y + cell * 0.08),
        ]),
        with: .color(Color(hex: 0xF2B84B))
    )
    ctx.fill(starBurst(CGPoint(x: head.x - cell * 0.06, y: head.y - cell * 0.15), cell * 0.055), with: .color(Color(hex: 0xFFF0B8)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.04), cell * 0.030), with: .color(Color(hex: 0xDCEFFF)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.055, y: head.y - cell * 0.04), cell * 0.018), with: .color(ink))
}

/// A moon jelly: four pale rings inside a translucent bell.
nonisolated func drawMoonJelly(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xCFE0FF))
    ctx.fill(circle(c, cell * 0.44), with: .color(body.opacity(0.16)))
    for i in -2...2 {
        let x = c.x + cell * 0.085 * CGFloat(i)
        var thread = Path()
        thread.move(to: CGPoint(x: x, y: c.y + cell * 0.06))
        thread.addQuadCurve(
            to: CGPoint(x: x + cell * 0.02 * CGFloat(i), y: c.y + cell * 0.40),
            control: CGPoint(x: x + cell * 0.05 * CGFloat(i), y: c.y + cell * 0.24)
        )
        ctx.stroke(thread, with: .color(body.opacity(0.6)), style: stroke(cell * 0.016))
    }
    var bell = Path()
    bell.move(to: CGPoint(x: c.x - cell * 0.32, y: c.y + cell * 0.06))
    bell.addQuadCurve(to: CGPoint(x: c.x, y: c.y - cell * 0.32), control: CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.32))
    bell.addQuadCurve(to: CGPoint(x: c.x + cell * 0.32, y: c.y + cell * 0.06), control: CGPoint(x: c.x + cell * 0.34, y: c.y - cell * 0.32))
    bell.closeSubpath()
    ctx.fill(bell, with: .color(body.opacity(0.62)))
    ctx.stroke(bell, with: .color(Color(hex: 0xEAF2FF).opacity(0.7)), style: stroke(cell * 0.018))
    // The four horseshoe gonads - the mark that makes it a moon jelly.
    for i in 0..<4 {
        let a = CGFloat.pi / 4 + CGFloat(i) * (CGFloat.pi / 2)
        ctx.stroke(
            circle(CGPoint(x: c.x + cos(a) * cell * 0.11, y: c.y + sin(a) * cell * 0.09 - cell * 0.08), cell * 0.055),
            with: .color(Color(hex: 0x8FA9E8).opacity(0.75)), style: stroke(cell * 0.020)
        )
    }
}

// MARK: - Candy Pop

/// A duckling moulded out of gum: glossy, rounded, with a highlight.
nonisolated func drawGummyDuck(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xFF6FA8))
    // Everything semi-transparent, which is what says "gummy" rather than
    // "duck that happens to be pink".
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.06), CGSize(width: cell * 0.52, height: cell * 0.32)), with: .color(body.opacity(0.55)))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.26, y: c.y - cell * 0.10), CGSize(width: cell * 0.48, height: cell * 0.28)), with: .color(body.opacity(0.80)))
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.02),
            CGPoint(x: c.x - cell * 0.42, y: c.y - cell * 0.14),
            CGPoint(x: c.x - cell * 0.20, y: c.y + cell * 0.08),
        ]),
        with: .color(body.opacity(0.75))
    )
    let head = CGPoint(x: c.x + cell * 0.19, y: c.y - cell * 0.18)
    ctx.fill(circle(head, cell * 0.145), with: .color(body.opacity(0.82)))
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.09, y: head.y - cell * 0.02),
            CGPoint(x: head.x + cell * 0.29, y: head.y + cell * 0.03),
            CGPoint(x: head.x + cell * 0.09, y: head.y + cell * 0.08),
        ]),
        with: .color(Color(hex: 0xFFC94D).opacity(0.9))
    )
    // Sugar crystals scattered over the surface.
    for p in [CGPoint(x: -0.14, y: 0.02), CGPoint(x: -0.02, y: 0.08), CGPoint(x: 0.08, y: -0.02), CGPoint(x: 0.14, y: -0.20)] {
        ctx.fill(circle(CGPoint(x: c.x + cell * p.x, y: c.y + cell * p.y), cell * 0.018), with: .color(Color.white.opacity(0.55)))
    }
    // The gloss: one long highlight, which is what makes a shape look wet.
    ctx.fill(oval(CGPoint(x: head.x - cell * 0.09, y: head.y - cell * 0.11), CGSize(width: cell * 0.11, height: cell * 0.06)), with: .color(Color.white.opacity(0.55)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.03), cell * 0.026), with: .color(ink.opacity(0.8)))
}

/// A bubblegum fish blowing one enormous bubble.
nonisolated func drawBubblegumFish(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x7FD8E8))
    let pale = body.lightened(1.25)
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.10, y: c.y),
            CGPoint(x: c.x - cell * 0.42, y: c.y - cell * 0.20),
            CGPoint(x: c.x - cell * 0.28, y: c.y),
            CGPoint(x: c.x - cell * 0.42, y: c.y + cell * 0.20),
        ]),
        with: .color(pale)
    )
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.18, y: c.y - cell * 0.13), CGSize(width: cell * 0.44, height: cell * 0.28)), with: .color(body.shaded()))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.18, y: c.y - cell * 0.15), CGSize(width: cell * 0.42, height: cell * 0.26)), with: .color(body))
    // Candy stripes.
    for dx in [-0.06, 0.04, 0.14] as [CGFloat] {
        ctx.stroke(
            line(CGPoint(x: c.x + cell * dx, y: c.y - cell * 0.13), CGPoint(x: c.x + cell * (dx - 0.03), y: c.y + cell * 0.11)),
            with: .color(Color(hex: 0xFF9FC4)), style: stroke(cell * 0.030)
        )
    }
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.18, y: c.y - cell * 0.04), cell * 0.040), with: .color(.white))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.19, y: c.y - cell * 0.04), cell * 0.022), with: .color(ink))
    // The bubble, bigger than the fish's head, which is the joke.
    let bub = CGPoint(x: c.x + cell * 0.36, y: c.y - cell * 0.06)
    ctx.fill(circle(bub, cell * 0.16), with: .color(Color(hex: 0xFF9FC4).opacity(0.55)))
    ctx.stroke(circle(bub, cell * 0.16), with: .color(Color(hex: 0xFF6FA8).opacity(0.85)), style: stroke(cell * 0.018))
    ctx.fill(circle(CGPoint(x: bub.x - cell * 0.06, y: bub.y - cell * 0.06), cell * 0.035), with: .color(Color.white.opacity(0.7)))
}

// MARK: - Royal Lagoon

/// A swan wearing a crown, neck held high.
nonisolated func drawRoyalSwan(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xFBFCFD))
    let dark = body.shaded(0.90)
    let gold = Color(hex: 0xE9C05A)
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.02), CGSize(width: cell * 0.62, height: cell * 0.30)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y - cell * 0.10), CGSize(width: cell * 0.58, height: cell * 0.28)), with: .color(body))
    // The raised wing, scalloped, so the bird has a profile from the side.
    var wing = Path()
    wing.move(to: CGPoint(x: c.x - cell * 0.22, y: c.y))
    wing.addQuadCurve(to: CGPoint(x: c.x + cell * 0.14, y: c.y - cell * 0.08), control: CGPoint(x: c.x - cell * 0.10, y: c.y - cell * 0.26))
    wing.addQuadCurve(to: CGPoint(x: c.x - cell * 0.06, y: c.y + cell * 0.04), control: CGPoint(x: c.x, y: c.y - cell * 0.02))
    wing.addQuadCurve(to: CGPoint(x: c.x - cell * 0.22, y: c.y), control: CGPoint(x: c.x - cell * 0.14, y: c.y - cell * 0.02))
    wing.closeSubpath()
    ctx.fill(wing, with: .color(dark))
    let head = CGPoint(x: c.x + cell * 0.26, y: c.y - cell * 0.28)
    var neck = Path()
    neck.move(to: CGPoint(x: c.x + cell * 0.14, y: c.y - cell * 0.04))
    neck.addCurve(
        to: head,
        control1: CGPoint(x: c.x + cell * 0.06, y: c.y - cell * 0.26),
        control2: CGPoint(x: head.x - cell * 0.02, y: head.y + cell * 0.14)
    )
    neck.addLine(to: CGPoint(x: head.x + cell * 0.07, y: head.y + cell * 0.03))
    neck.addCurve(
        to: CGPoint(x: c.x + cell * 0.24, y: c.y - cell * 0.02),
        control1: CGPoint(x: head.x + cell * 0.06, y: head.y + cell * 0.18),
        control2: CGPoint(x: c.x + cell * 0.24, y: c.y - cell * 0.18)
    )
    neck.closeSubpath()
    ctx.fill(neck, with: .color(body))
    ctx.fill(circle(head, cell * 0.105), with: .color(body))
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.02),
            CGPoint(x: head.x + cell * 0.23, y: head.y + cell * 0.02),
            CGPoint(x: head.x + cell * 0.05, y: head.y + cell * 0.06),
        ]),
        with: .color(Color(hex: 0xE58A3C))
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.02, y: head.y - cell * 0.02), cell * 0.024), with: .color(ink))
    // The crown: three points on a band, in gold, sitting on the crest.
    let crownY = head.y - cell * 0.11
    ctx.fill(
        polygon([
            CGPoint(x: head.x - cell * 0.09, y: crownY),
            CGPoint(x: head.x - cell * 0.06, y: crownY - cell * 0.10),
            CGPoint(x: head.x - cell * 0.02, y: crownY - cell * 0.02),
            CGPoint(x: head.x + cell * 0.02, y: crownY - cell * 0.12),
            CGPoint(x: head.x + cell * 0.06, y: crownY - cell * 0.02),
            CGPoint(x: head.x + cell * 0.10, y: crownY - cell * 0.10),
            CGPoint(x: head.x + cell * 0.11, y: crownY),
        ]),
        with: .color(gold)
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.01, y: crownY - cell * 0.11), cell * 0.020), with: .color(Color(hex: 0xE05A82)))
}

/// A peacock with the fan up: the tail is nearly the whole cell.
nonisolated func drawPeacock(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x1E7A8C))
    let fan = CGPoint(x: c.x + cell * 0.04, y: c.y + cell * 0.02)
    // Seven feathers in a half circle, each with an eye on the end.
    for i in 0..<7 {
        let a = CGFloat.pi * (0.06 + 0.13 * CGFloat(i)) + .pi
        let tip = CGPoint(x: fan.x + cos(a) * cell * 0.44, y: fan.y + sin(a) * cell * 0.44)
        ctx.stroke(line(fan, tip), with: .color(Color(hex: 0x2E8F6B)), style: stroke(cell * 0.018))
        ctx.fill(oval(CGPoint(x: tip.x - cell * 0.055, y: tip.y - cell * 0.055), CGSize(width: cell * 0.11, height: cell * 0.11)), with: .color(Color(hex: 0x2E8F6B)))
        ctx.fill(circle(tip, cell * 0.038), with: .color(Color(hex: 0x2A5FA8)))
        ctx.fill(circle(tip, cell * 0.020), with: .color(Color(hex: 0xE9C05A)))
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.14, y: c.y - cell * 0.04), CGSize(width: cell * 0.36, height: cell * 0.28)), with: .color(body.shaded()))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.14, y: c.y - cell * 0.08), CGSize(width: cell * 0.34, height: cell * 0.26)), with: .color(body))
    let head = CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.20)
    var neck = Path()
    neck.move(to: CGPoint(x: c.x + cell * 0.08, y: c.y - cell * 0.02))
    neck.addQuadCurve(to: head, control: CGPoint(x: c.x + cell * 0.10, y: c.y - cell * 0.20))
    neck.addLine(to: CGPoint(x: head.x + cell * 0.06, y: head.y + cell * 0.05))
    neck.addQuadCurve(to: CGPoint(x: c.x + cell * 0.18, y: c.y - cell * 0.02), control: CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.18))
    neck.closeSubpath()
    ctx.fill(neck, with: .color(body))
    ctx.fill(circle(head, cell * 0.095), with: .color(body))
    // The crest: three fine stalks with dots on the ends.
    for dx in [-0.04, 0.0, 0.04] as [CGFloat] {
        ctx.stroke(
            line(CGPoint(x: head.x + cell * dx, y: head.y - cell * 0.07), CGPoint(x: head.x + cell * dx * 1.8, y: head.y - cell * 0.19)),
            with: .color(body), style: stroke(cell * 0.012)
        )
        ctx.fill(circle(CGPoint(x: head.x + cell * dx * 1.8, y: head.y - cell * 0.19), cell * 0.020), with: .color(Color(hex: 0x2E8F6B)))
    }
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.01),
            CGPoint(x: head.x + cell * 0.19, y: head.y + cell * 0.02),
            CGPoint(x: head.x + cell * 0.05, y: head.y + cell * 0.05),
        ]),
        with: .color(Color(hex: 0xD8CDB4))
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.01, y: head.y - cell * 0.02), cell * 0.022), with: .color(ink))
}
