//
//  FloaterArtLegends.swift
//  PondPulse
//
//  The far end of every ladder: eight friends and eight lily pads that are the
//  last thing on the route that pays them. A 1:1 port of the Android
//  ui/FloaterArtLegends.kt.
//
//  One for finishing all thirty golden ponds, two for a fifty- and a
//  seventy-five-day daily streak, and five at a top coin band worth most of a
//  pack of three-starred ponds. Each pair - a friend and a pad - is gated the
//  same way, so the two shelves climb together.
//

import SwiftUI

// MARK: - Friends

/// Every thirty golden ponds, once: a turtle plated in gold.
nonisolated func drawGoldenTurtle(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let gold = bodyTint(palette, color, Color(hex: 0xE9B93C))
    let deep = gold.shaded(0.74)
    let lit = gold.lightened(1.28)

    // Flippers first, so the shell sits over their roots.
    for sx in [-1.0, 1.0] as [CGFloat] {
        for sy in [-1.0, 1.0] as [CGFloat] {
            ctx.fill(
                oval(CGPoint(x: c.x + cell * 0.16 * sx - cell * 0.11, y: c.y + cell * 0.15 * sy - cell * 0.07),
                     CGSize(width: cell * 0.26, height: cell * 0.16)),
                with: .color(deep)
            )
        }
    }
    let head = CGPoint(x: c.x + cell * 0.34, y: c.y - cell * 0.02)
    ctx.fill(circle(head, cell * 0.115), with: .color(deep))
    ctx.fill(circle(CGPoint(x: head.x - cell * 0.008, y: head.y - cell * 0.012), cell * 0.10), with: .color(gold))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.03, y: head.y - cell * 0.03), cell * 0.024), with: .color(ink))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.045, y: head.y - cell * 0.045), cell * 0.012), with: .color(Color.white.opacity(0.8)))

    // The shell: a dome, a rim, and six plates picked out in a lighter gold.
    ctx.fill(circle(c, cell * 0.34), with: .color(deep))
    ctx.fill(circle(c, cell * 0.30), with: .color(gold))
    for i in 0..<6 {
        let a = CGFloat(i) * (2 * .pi / 6) + 0.4
        let at = CGPoint(x: c.x + cos(a) * cell * 0.185, y: c.y + sin(a) * cell * 0.185)
        ctx.fill(circle(at, cell * 0.072), with: .color(lit.opacity(0.75)))
        ctx.stroke(circle(at, cell * 0.072), with: .color(deep.opacity(0.55)), style: stroke(cell * 0.010))
    }
    ctx.fill(circle(c, cell * 0.085), with: .color(lit))
    ctx.stroke(circle(c, cell * 0.085), with: .color(deep.opacity(0.6)), style: stroke(cell * 0.012))
    // A gleam across the dome, which is what turns yellow into gold.
    ctx.stroke(
        ovalArc(CGPoint(x: c.x - cell * 0.26, y: c.y - cell * 0.26), CGSize(width: cell * 0.52, height: cell * 0.52),
                start: 195, sweep: 60, useCenter: false),
        with: .color(Color.white.opacity(0.45)), style: stroke(cell * 0.030, cap: .round)
    )
}

/// Fifty days running: a firefly, lantern lit.
nonisolated func drawFirefly(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x3B3A2E))
    let glow = Color(hex: 0xCBFF7A)

    // The halo. Three rings rather than a gradient, so it stays crisp small.
    for (r, a) in [(0.44, 0.10), (0.32, 0.16), (0.22, 0.26)] as [(CGFloat, CGFloat)] {
        ctx.fill(circle(CGPoint(x: c.x - cell * 0.16, y: c.y + cell * 0.10), cell * r), with: .color(glow.opacity(a)))
    }
    // Wings, swept back and translucent.
    for sy in [-1.0, 1.0] as [CGFloat] {
        var wing = Path()
        wing.move(to: CGPoint(x: c.x + cell * 0.04, y: c.y - cell * 0.02))
        wing.addQuadCurve(to: CGPoint(x: c.x - cell * 0.26, y: c.y + cell * 0.24 * sy), control: CGPoint(x: c.x + cell * 0.02, y: c.y + cell * 0.34 * sy))
        wing.addQuadCurve(to: CGPoint(x: c.x + cell * 0.04, y: c.y - cell * 0.02), control: CGPoint(x: c.x - cell * 0.06, y: c.y + cell * 0.10 * sy))
        wing.closeSubpath()
        ctx.fill(wing, with: .color(Color(hex: 0xE9F7C8).opacity(0.42)))
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.10), CGSize(width: cell * 0.44, height: cell * 0.20)), with: .color(body))
    // The lantern: the abdomen tip, lit, which is the whole animal.
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.20, y: c.y + cell * 0.01), cell * 0.105), with: .color(glow))
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.21, y: c.y + cell * 0.005), cell * 0.055), with: .color(Color(hex: 0xF6FFE0)))
    let head = CGPoint(x: c.x + cell * 0.23, y: c.y - cell * 0.04)
    ctx.fill(circle(head, cell * 0.085), with: .color(body.shaded()))
    for sy in [-1.0, 1.0] as [CGFloat] {
        var antenna = Path()
        antenna.move(to: CGPoint(x: head.x + cell * 0.04, y: head.y + cell * 0.02 * sy))
        antenna.addQuadCurve(to: CGPoint(x: head.x + cell * 0.16, y: head.y + cell * 0.24 * sy), control: CGPoint(x: head.x + cell * 0.20, y: head.y + cell * 0.10 * sy))
        ctx.stroke(antenna, with: .color(body.shaded()), style: stroke(cell * 0.014))
    }
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.03, y: head.y - cell * 0.025), cell * 0.022), with: .color(glow.opacity(0.9)))
}

/// Seventy-five days running: a small owl, wide awake.
nonisolated func drawOwl(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x8A6A4A))
    let dark = body.shaded(0.76)
    let pale = body.lightened(1.36)

    // Folded wings either side, drawn before the breast.
    for sx in [-1.0, 1.0] as [CGFloat] {
        ctx.fill(
            oval(CGPoint(x: c.x + cell * 0.20 * sx - cell * 0.10, y: c.y - cell * 0.14), CGSize(width: cell * 0.20, height: cell * 0.38)),
            with: .color(dark)
        )
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.20), CGSize(width: cell * 0.48, height: cell * 0.46)), with: .color(body))
    // Barred breast: three short rows of chevrons.
    for i in 0..<3 {
        let y = c.y + cell * (0.02 + 0.09 * CGFloat(i))
        for dx in [-0.10, 0.02] as [CGFloat] {
            var bar = Path()
            bar.move(to: CGPoint(x: c.x + cell * dx, y: y))
            bar.addQuadCurve(to: CGPoint(x: c.x + cell * (dx + 0.08), y: y), control: CGPoint(x: c.x + cell * (dx + 0.04), y: y + cell * 0.04))
            ctx.stroke(bar, with: .color(dark.opacity(0.5)), style: stroke(cell * 0.012))
        }
    }
    // Ear tufts, then the facial disc - the two things that say "owl" at once.
    for sx in [-1.0, 1.0] as [CGFloat] {
        ctx.fill(
            polygon([
                CGPoint(x: c.x + cell * 0.10 * sx, y: c.y - cell * 0.20),
                CGPoint(x: c.x + cell * 0.20 * sx, y: c.y - cell * 0.42),
                CGPoint(x: c.x + cell * 0.24 * sx, y: c.y - cell * 0.16),
            ]),
            with: .color(dark)
        )
    }
    for sx in [-1.0, 1.0] as [CGFloat] {
        let eye = CGPoint(x: c.x + cell * 0.115 * sx, y: c.y - cell * 0.13)
        ctx.fill(circle(eye, cell * 0.125), with: .color(pale))
        ctx.fill(circle(eye, cell * 0.085), with: .color(Color(hex: 0xF2B33C)))
        ctx.fill(circle(eye, cell * 0.048), with: .color(ink))
        ctx.fill(circle(CGPoint(x: eye.x - cell * 0.030, y: eye.y - cell * 0.030), cell * 0.020), with: .color(Color.white.opacity(0.9)))
    }
    ctx.fill(
        polygon([
            CGPoint(x: c.x, y: c.y - cell * 0.10),
            CGPoint(x: c.x - cell * 0.045, y: c.y - cell * 0.02),
            CGPoint(x: c.x + cell * 0.045, y: c.y - cell * 0.02),
        ]),
        with: .color(Color(hex: 0xE0913C))
    )
}

/// A kraken: eight arms and one eye, filling the cell.
nonisolated func drawKraken(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x6A3E7A))
    let dark = body.shaded(0.72)
    let sucker = body.lightened(1.45)

    // Eight arms, curling alternately, each tapering to a point.
    for i in 0..<8 {
        let a = CGFloat.pi * (0.10 + 0.115 * CGFloat(i)) + .pi * 0.42
        let curl: CGFloat = i % 2 == 0 ? 1 : -1
        let root = CGPoint(x: c.x + cos(a) * cell * 0.14, y: c.y + sin(a) * cell * 0.10 + cell * 0.06)
        let tipPt = CGPoint(x: c.x + cos(a) * cell * 0.50, y: c.y + sin(a) * cell * 0.42 + cell * 0.10)
        let bend = CGPoint(
            x: (root.x + tipPt.x) / 2 - sin(a) * cell * 0.16 * curl,
            y: (root.y + tipPt.y) / 2 + cos(a) * cell * 0.16 * curl
        )
        var arm = Path()
        arm.move(to: root)
        arm.addQuadCurve(to: tipPt, control: CGPoint(x: bend.x + cell * 0.05, y: bend.y))
        arm.addQuadCurve(to: root, control: CGPoint(x: bend.x - cell * 0.05, y: bend.y))
        arm.closeSubpath()
        ctx.fill(arm, with: .color(i % 2 == 0 ? body : dark))
        // Two suckers per arm, so the arms read as arms and not as ribbons.
        for t in [0.45, 0.72] as [CGFloat] {
            ctx.fill(
                circle(CGPoint(x: root.x + (tipPt.x - root.x) * t, y: root.y + (tipPt.y - root.y) * t), cell * 0.022),
                with: .color(sucker.opacity(0.7))
            )
        }
    }
    // The mantle: a tall dome, with a ridge down it.
    var mantle = Path()
    mantle.move(to: CGPoint(x: c.x - cell * 0.26, y: c.y + cell * 0.06))
    mantle.addCurve(
        to: CGPoint(x: c.x + cell * 0.26, y: c.y + cell * 0.06),
        control1: CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.36),
        control2: CGPoint(x: c.x + cell * 0.28, y: c.y - cell * 0.36)
    )
    mantle.closeSubpath()
    ctx.fill(mantle, with: .color(body))
    var ridge = Path()
    ridge.move(to: CGPoint(x: c.x - cell * 0.05, y: c.y - cell * 0.30))
    ridge.addQuadCurve(to: CGPoint(x: c.x + cell * 0.05, y: c.y - cell * 0.30), control: CGPoint(x: c.x, y: c.y - cell * 0.36))
    ridge.addQuadCurve(to: CGPoint(x: c.x - cell * 0.05, y: c.y - cell * 0.30), control: CGPoint(x: c.x, y: c.y - cell * 0.12))
    ridge.closeSubpath()
    ctx.fill(ridge, with: .color(body.lightened(1.18)))
    // One eye, big, low and slit - the difference between a kraken and a squid.
    let eye = CGPoint(x: c.x + cell * 0.02, y: c.y - cell * 0.05)
    ctx.fill(oval(CGPoint(x: eye.x - cell * 0.135, y: eye.y - cell * 0.085), CGSize(width: cell * 0.27, height: cell * 0.17)), with: .color(Color(hex: 0xF6E9A8)))
    ctx.fill(oval(CGPoint(x: eye.x - cell * 0.030, y: eye.y - cell * 0.075), CGSize(width: cell * 0.060, height: cell * 0.15)), with: .color(ink))
    ctx.fill(oval(CGPoint(x: eye.x - cell * 0.135, y: eye.y - cell * 0.105), CGSize(width: cell * 0.27, height: cell * 0.06)), with: .color(dark.opacity(0.5)))
}

/// An anglerfish: a mouth of teeth and a light on a stalk.
nonisolated func drawAnglerfish(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x2C3A4A))
    let dark = body.shaded(0.72)
    let lure = Color(hex: 0x8FE9FF)

    // The lure's glow reaches the body, so the light looks like it is lighting.
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.30), cell * 0.34), with: .color(lure.opacity(0.16)))
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.10, y: c.y - cell * 0.20),
            CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.06),
            CGPoint(x: c.x - cell * 0.30, y: c.y + cell * 0.16),
        ]),
        with: .color(dark)
    )
    // A fat, round body - the shape does most of the work.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.22), CGSize(width: cell * 0.60, height: cell * 0.48)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.25), CGSize(width: cell * 0.58, height: cell * 0.45)), with: .color(body))
    // The mouth: a wide grin of triangular teeth.
    var mouth = Path()
    mouth.move(to: CGPoint(x: c.x - cell * 0.04, y: c.y + cell * 0.02))
    mouth.addQuadCurve(to: CGPoint(x: c.x + cell * 0.28, y: c.y + cell * 0.02), control: CGPoint(x: c.x + cell * 0.16, y: c.y + cell * 0.20))
    mouth.addLine(to: CGPoint(x: c.x + cell * 0.24, y: c.y - cell * 0.02))
    mouth.addQuadCurve(to: CGPoint(x: c.x - cell * 0.02, y: c.y - cell * 0.02), control: CGPoint(x: c.x + cell * 0.14, y: c.y + cell * 0.10))
    mouth.closeSubpath()
    ctx.fill(mouth, with: .color(ink.opacity(0.85)))
    for i in 0..<5 {
        let t = CGFloat(i) / 4
        let x = c.x - cell * 0.02 + cell * 0.28 * t
        let y = c.y + cell * (0.03 + 0.10 * (1 - (2 * t - 1) * (2 * t - 1)))
        ctx.fill(
            polygon([
                CGPoint(x: x - cell * 0.022, y: y - cell * 0.05),
                CGPoint(x: x, y: y),
                CGPoint(x: x + cell * 0.022, y: y - cell * 0.05),
            ]),
            with: .color(Color(hex: 0xF2F6F8))
        )
    }
    // The illicium: stalk, bulb, and a hard white core.
    var stalk = Path()
    stalk.move(to: CGPoint(x: c.x - cell * 0.02, y: c.y - cell * 0.22))
    stalk.addQuadCurve(to: CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.30), control: CGPoint(x: c.x + cell * 0.18, y: c.y - cell * 0.46))
    ctx.stroke(stalk, with: .color(dark), style: stroke(cell * 0.026))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.30), cell * 0.095), with: .color(lure.opacity(0.55)))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.30), cell * 0.048), with: .color(Color(hex: 0xEFFBFF)))
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.10, y: c.y - cell * 0.06), cell * 0.048), with: .color(Color(hex: 0xF6E9A8)))
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.10, y: c.y - cell * 0.06), cell * 0.024), with: .color(ink))
}

/// A manta ray from above: pure wingspan.
nonisolated func drawManta(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    // A deep blue-black back over a bright belly. The first pass was one flat
    // mid-grey and the wingspan read as a smudge on the tile: a manta seen from
    // above is a *contrast* shape, dark on top and pale beneath.
    let body = bodyTint(palette, color, Color(hex: 0x27405C))
    let pale = body.lightened(2.1)

    var wings = Path()
    wings.move(to: CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.02))
    wings.addCurve(
        to: CGPoint(x: c.x - cell * 0.48, y: c.y - cell * 0.10),
        control1: CGPoint(x: c.x + cell * 0.04, y: c.y - cell * 0.34),
        control2: CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.36)
    )
    wings.addCurve(
        to: CGPoint(x: c.x - cell * 0.48, y: c.y + cell * 0.10),
        control1: CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.04),
        control2: CGPoint(x: c.x - cell * 0.26, y: c.y + cell * 0.04)
    )
    wings.addCurve(
        to: CGPoint(x: c.x + cell * 0.20, y: c.y + cell * 0.02),
        control1: CGPoint(x: c.x - cell * 0.34, y: c.y + cell * 0.36),
        control2: CGPoint(x: c.x + cell * 0.04, y: c.y + cell * 0.34)
    )
    wings.closeSubpath()
    ctx.fill(wings, with: .color(body))
    // The two pale shoulder patches every manta has, and the gill slits.
    for sy in [-1.0, 1.0] as [CGFloat] {
        var patch = Path()
        patch.move(to: CGPoint(x: c.x + cell * 0.10, y: c.y + cell * 0.02 * sy))
        patch.addQuadCurve(to: CGPoint(x: c.x - cell * 0.24, y: c.y + cell * 0.20 * sy), control: CGPoint(x: c.x - cell * 0.06, y: c.y + cell * 0.26 * sy))
        patch.addQuadCurve(to: CGPoint(x: c.x + cell * 0.10, y: c.y + cell * 0.02 * sy), control: CGPoint(x: c.x - cell * 0.10, y: c.y + cell * 0.10 * sy))
        patch.closeSubpath()
        ctx.fill(patch, with: .color(pale.opacity(0.55)))
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.06, y: c.y - cell * 0.07), CGSize(width: cell * 0.22, height: cell * 0.14)), with: .color(pale.opacity(0.85)))
    for sy in [-1.0, 1.0] as [CGFloat] {
        for i in 0..<3 {
            ctx.stroke(
                line(CGPoint(x: c.x + cell * (0.04 + 0.05 * CGFloat(i)), y: c.y + cell * 0.07 * sy),
                     CGPoint(x: c.x + cell * (0.04 + 0.05 * CGFloat(i)), y: c.y + cell * 0.13 * sy)),
                with: .color(body.shaded(0.62)), style: stroke(cell * 0.012)
            )
        }
    }
    // Cephalic fins reaching forward, and a whip tail behind.
    for sy in [-1.0, 1.0] as [CGFloat] {
        var horn = Path()
        horn.move(to: CGPoint(x: c.x + cell * 0.16, y: c.y + cell * 0.06 * sy))
        horn.addQuadCurve(to: CGPoint(x: c.x + cell * 0.36, y: c.y + cell * 0.02 * sy), control: CGPoint(x: c.x + cell * 0.34, y: c.y + cell * 0.10 * sy))
        horn.addQuadCurve(to: CGPoint(x: c.x + cell * 0.16, y: c.y + cell * 0.02 * sy), control: CGPoint(x: c.x + cell * 0.28, y: c.y + cell * 0.04 * sy))
        horn.closeSubpath()
        ctx.fill(horn, with: .color(body))
    }
    var tail = Path()
    tail.move(to: CGPoint(x: c.x - cell * 0.22, y: c.y))
    tail.addQuadCurve(to: CGPoint(x: c.x - cell * 0.50, y: c.y + cell * 0.22), control: CGPoint(x: c.x - cell * 0.42, y: c.y + cell * 0.06))
    ctx.stroke(tail, with: .color(body.shaded(0.8)), style: stroke(cell * 0.018, cap: .round))
    for sy in [-1.0, 1.0] as [CGFloat] {
        ctx.fill(circle(CGPoint(x: c.x + cell * 0.19, y: c.y + cell * 0.055 * sy), cell * 0.022), with: .color(ink))
    }
}

/// A raven: black, hunched, with one bright eye.
nonisolated func drawRaven(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x23262E))
    let sheen = body.lightened(2.2)

    // Tail, wedge-shaped, and a folded wing with three feather splits.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.16, y: c.y - cell * 0.02),
            CGPoint(x: c.x - cell * 0.48, y: c.y - cell * 0.14),
            CGPoint(x: c.x - cell * 0.46, y: c.y + cell * 0.06),
            CGPoint(x: c.x - cell * 0.16, y: c.y + cell * 0.10),
        ]),
        with: .color(body)
    )
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.26, y: c.y - cell * 0.16), CGSize(width: cell * 0.50, height: cell * 0.34)), with: .color(body))
    var wing = Path()
    wing.move(to: CGPoint(x: c.x - cell * 0.16, y: c.y - cell * 0.10))
    wing.addQuadCurve(to: CGPoint(x: c.x + cell * 0.12, y: c.y + cell * 0.10), control: CGPoint(x: c.x + cell * 0.06, y: c.y - cell * 0.06))
    wing.addQuadCurve(to: CGPoint(x: c.x - cell * 0.18, y: c.y + cell * 0.04), control: CGPoint(x: c.x - cell * 0.04, y: c.y + cell * 0.14))
    wing.closeSubpath()
    ctx.fill(wing, with: .color(body.shaded(0.86)))
    for i in 0..<3 {
        ctx.stroke(
            line(CGPoint(x: c.x - cell * 0.10 + cell * 0.07 * CGFloat(i), y: c.y - cell * 0.04),
                 CGPoint(x: c.x - cell * 0.04 + cell * 0.07 * CGFloat(i), y: c.y + cell * 0.10)),
            with: .color(sheen.opacity(0.22)), style: stroke(cell * 0.010)
        )
    }
    // Hackles at the throat - the shaggy neck is the raven's own silhouette.
    let head = CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.20)
    for i in 0..<4 {
        ctx.fill(
            polygon([
                CGPoint(x: c.x + cell * (0.06 + 0.05 * CGFloat(i)), y: c.y - cell * 0.06),
                CGPoint(x: c.x + cell * (0.14 + 0.05 * CGFloat(i)), y: c.y + cell * 0.06),
                CGPoint(x: c.x + cell * (0.04 + 0.05 * CGFloat(i)), y: c.y + cell * 0.04),
            ]),
            with: .color(body.shaded(0.8))
        )
    }
    ctx.fill(circle(head, cell * 0.125), with: .color(body))
    // The bill: heavy, slightly hooked, which is what says raven not crow.
    var bill = Path()
    bill.move(to: CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.055))
    bill.addQuadCurve(to: CGPoint(x: head.x + cell * 0.30, y: head.y + cell * 0.055), control: CGPoint(x: head.x + cell * 0.34, y: head.y - cell * 0.02))
    bill.addQuadCurve(to: CGPoint(x: head.x + cell * 0.05, y: head.y + cell * 0.055), control: CGPoint(x: head.x + cell * 0.18, y: head.y + cell * 0.02))
    bill.closeSubpath()
    ctx.fill(bill, with: .color(body.shaded(0.7)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.01, y: head.y - cell * 0.035), cell * 0.040), with: .color(Color(hex: 0xE8E2D4)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.02, y: head.y - cell * 0.035), cell * 0.022), with: .color(ink))
    // A cold sheen along the back: black that is only black is a hole.
    ctx.stroke(
        ovalArc(CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.18), CGSize(width: cell * 0.46, height: cell * 0.30),
                start: 200, sweep: 80, useCenter: false),
        with: .color(sheen.opacity(0.16)), style: stroke(cell * 0.026, cap: .round)
    )
}

/// A lionfish: a crown of venomous spines, striped red and white.
nonisolated func drawLionfish(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xD9563C))
    let stripe = Color(hex: 0xFBF3E6)
    let fin = Color(hex: 0xF0A08C)

    // The fan of spines, all round, drawn first so the body sits inside it.
    for i in 0..<13 {
        let a = CGFloat(i) * (2 * .pi / 13) + 0.25
        let len = cell * (0.46 + 0.06 * sin(CGFloat(i) * 2.1))
        let dir = CGPoint(x: cos(a), y: sin(a))
        let across = CGPoint(x: -dir.y, y: dir.x)
        let tipPt = CGPoint(x: c.x + dir.x * len, y: c.y + dir.y * len)
        var spine = Path()
        spine.move(to: CGPoint(x: c.x + dir.x * cell * 0.16, y: c.y + dir.y * cell * 0.16))
        spine.addQuadCurve(to: tipPt, control: CGPoint(x: c.x + dir.x * len * 0.6 + across.x * cell * 0.055, y: c.y + dir.y * len * 0.6 + across.y * cell * 0.055))
        spine.addQuadCurve(
            to: CGPoint(x: c.x + dir.x * cell * 0.16, y: c.y + dir.y * cell * 0.16),
            control: CGPoint(x: c.x + dir.x * len * 0.6 - across.x * cell * 0.055, y: c.y + dir.y * len * 0.6 - across.y * cell * 0.055)
        )
        spine.closeSubpath()
        ctx.fill(spine, with: .color(fin.opacity(0.55)))
        ctx.stroke(
            line(CGPoint(x: c.x + dir.x * cell * 0.18, y: c.y + dir.y * cell * 0.18), tipPt),
            with: .color(body.opacity(0.85)), style: stroke(cell * 0.014)
        )
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.15), CGSize(width: cell * 0.46, height: cell * 0.30)), with: .color(body.shaded()))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.17), CGSize(width: cell * 0.44, height: cell * 0.28)), with: .color(body))
    // Four bold bands: the lionfish is unmistakable and it is the stripes.
    for (i, dx) in ([-0.14, -0.04, 0.06, 0.16] as [CGFloat]).enumerated() {
        let h = cell * (0.26 - 0.02 * abs(CGFloat(i) - 1.5))
        ctx.fill(oval(CGPoint(x: c.x + cell * dx - cell * 0.022, y: c.y - h / 2), CGSize(width: cell * 0.044, height: h)), with: .color(stripe))
    }
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.17, y: c.y - cell * 0.03), cell * 0.048), with: .color(stripe))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.18, y: c.y - cell * 0.03), cell * 0.026), with: .color(ink))
}

// MARK: - Lily pads
//
// A pad is read *underneath* a duckling, at a glance, while the player is
// thinking about something else - so each of these is built from one strong
// silhouette and one strong colour, never from detail. The rule the whole shelf
// follows: whatever else it does, it must still read as somewhere to stand.

/// Every thirty golden ponds: a lily wearing a crown of gold.
nonisolated func drawCrownLilyPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let leaf = Color(hex: 0x2F7A44)
    let leafLit = Color(hex: 0x49A85F)
    let gold = Color(hex: 0xE9C05A)

    ctx.fill(circle(c, cell * 0.42), with: .color(leaf))
    ctx.stroke(circle(c, cell * 0.42), with: .color(leafLit), style: stroke(cell * 0.05))
    for i in 0..<7 {
        let a = CGFloat(i) * (2 * .pi / 7)
        ctx.stroke(
            line(c, CGPoint(x: c.x + cos(a) * cell * 0.40, y: c.y + sin(a) * cell * 0.40)),
            with: .color(leafLit.opacity(0.6)), style: stroke(cell * 0.014)
        )
    }
    // A five-pointed crown sitting on the pad, with a jewel in the middle.
    let base = c.y + cell * 0.10
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.22, y: base),
            CGPoint(x: c.x - cell * 0.26, y: base - cell * 0.26),
            CGPoint(x: c.x - cell * 0.11, y: base - cell * 0.10),
            CGPoint(x: c.x, y: base - cell * 0.34),
            CGPoint(x: c.x + cell * 0.11, y: base - cell * 0.10),
            CGPoint(x: c.x + cell * 0.26, y: base - cell * 0.26),
            CGPoint(x: c.x + cell * 0.22, y: base),
        ]),
        with: .color(gold)
    )
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.22, y: base),
            CGPoint(x: c.x + cell * 0.22, y: base),
            CGPoint(x: c.x + cell * 0.20, y: base + cell * 0.07),
            CGPoint(x: c.x - cell * 0.20, y: base + cell * 0.07),
        ]),
        with: .color(gold.shaded(0.82))
    )
    ctx.fill(circle(CGPoint(x: c.x, y: base - cell * 0.03), cell * 0.040), with: .color(Color(hex: 0xE0526B)))
    ctx.fill(circle(CGPoint(x: c.x, y: base - cell * 0.30), cell * 0.020), with: .color(Color.white.opacity(0.7)))
}

/// Fifty days running: a pad of banked embers, glowing from underneath.
nonisolated func drawEmberPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let ash = Color(hex: 0x3A2A28)
    let ember = Color(hex: 0xE0561F)
    let hot = Color(hex: 0xFFC24A)

    ctx.fill(circle(c, cell * 0.48), with: .color(ember.opacity(0.20)))
    ctx.fill(circle(c, cell * 0.42), with: .color(ash))
    // Cracks: the glow comes through the gaps, not off the surface.
    for i in 0..<7 {
        let a = CGFloat(i) * (2 * .pi / 7) + 0.3
        var crack = Path()
        crack.move(to: c)
        crack.addLine(to: CGPoint(x: c.x + cos(a) * cell * 0.20, y: c.y + sin(a) * cell * 0.20))
        crack.addLine(to: CGPoint(x: c.x + cos(a + 0.22) * cell * 0.40, y: c.y + sin(a + 0.22) * cell * 0.40))
        ctx.stroke(crack, with: .color(i % 2 == 0 ? hot : ember), style: stroke(cell * 0.030, cap: .round))
    }
    ctx.fill(circle(c, cell * 0.085), with: .color(hot))
    ctx.fill(circle(c, cell * 0.040), with: .color(Color(hex: 0xFFF0C0)))
    ctx.stroke(circle(c, cell * 0.42), with: .color(ash.opacity(0.9)), style: stroke(cell * 0.045))
    // Three sparks lifting off it.
    for (dx, dy, r) in [(-0.22, -0.34, 0.024), (0.10, -0.42, 0.018), (0.28, -0.28, 0.014)] as [(CGFloat, CGFloat, CGFloat)] {
        ctx.fill(circle(CGPoint(x: c.x + cell * dx, y: c.y + cell * dy), cell * r), with: .color(hot.opacity(0.85)))
    }
}

/// Seventy-five days running: a pad of clear ice, frosted at the rim.
nonisolated func drawFrostPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let ice = Color(hex: 0xBFE6F4)
    let deep = Color(hex: 0x6FA9C8)
    let white = Color(hex: 0xF4FBFF)

    // A faceted disc rather than a circle: ice does not have a smooth edge.
    var pts: [CGPoint] = []
    for i in 0..<9 {
        let a = CGFloat(i) * (2 * .pi / 9) - 0.2
        let r = cell * (0.40 + 0.035 * sin(CGFloat(i) * 2.7))
        pts.append(CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r))
    }
    let facets = polygon(pts)
    ctx.fill(facets, with: .color(ice.opacity(0.92)))
    ctx.stroke(facets, with: .color(white), style: stroke(cell * 0.030))
    for i in 0..<9 {
        let a = CGFloat(i) * (2 * .pi / 9) - 0.2
        ctx.stroke(
            line(c, CGPoint(x: c.x + cos(a) * cell * 0.38, y: c.y + sin(a) * cell * 0.38)),
            with: .color(deep.opacity(0.35)), style: stroke(cell * 0.012)
        )
    }
    // A six-armed snowflake at the middle, each arm with a pair of barbs.
    for i in 0..<6 {
        let a = CGFloat(i) * (2 * .pi / 6)
        let dir = CGPoint(x: cos(a), y: sin(a))
        let tipPt = CGPoint(x: c.x + dir.x * cell * 0.22, y: c.y + dir.y * cell * 0.22)
        ctx.stroke(line(c, tipPt), with: .color(white), style: stroke(cell * 0.020, cap: .round))
        for side in [-1.0, 1.0] as [CGFloat] {
            let at = CGPoint(x: c.x + dir.x * cell * 0.13, y: c.y + dir.y * cell * 0.13)
            let barb = CGPoint(
                x: at.x + (dir.x * 0.5 - dir.y * side) * cell * 0.09,
                y: at.y + (dir.y * 0.5 + dir.x * side) * cell * 0.09
            )
            ctx.stroke(line(at, barb), with: .color(white), style: stroke(cell * 0.013, cap: .round))
        }
    }
    ctx.fill(circle(c, cell * 0.035), with: .color(white))
}

/// A pearl in a half-open oyster, wide enough to stand on.
nonisolated func drawPearlPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let shell = Color(hex: 0x8E7FA8)
    let inner = Color(hex: 0xEADFF2)
    let pearl = Color(hex: 0xFBF7FF)

    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.03), cell * 0.42), with: .color(shell))
    // Ribs radiating from the hinge at the bottom.
    for i in 0..<9 {
        let a = CGFloat.pi * (1.04 + 0.115 * CGFloat(i))
        ctx.stroke(
            line(CGPoint(x: c.x, y: c.y + cell * 0.30),
                 CGPoint(x: c.x + cos(a) * cell * 0.46, y: c.y + cell * 0.30 + sin(a) * cell * 0.62)),
            with: .color(shell.shaded(0.82)), style: stroke(cell * 0.016)
        )
    }
    ctx.fill(circle(c, cell * 0.33), with: .color(inner))
    ctx.stroke(circle(c, cell * 0.33), with: .color(shell.opacity(0.5)), style: stroke(cell * 0.018))
    ctx.fill(circle(CGPoint(x: c.x, y: c.y - cell * 0.01), cell * 0.19), with: .color(pearl))
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.06, y: c.y - cell * 0.07), cell * 0.055), with: .color(.white))
    ctx.stroke(circle(CGPoint(x: c.x, y: c.y - cell * 0.01), cell * 0.19), with: .color(shell.opacity(0.22)), style: stroke(cell * 0.016))
}

/// Volcanic glass, cut to a hexagon and edged with a hairline of light.
nonisolated func drawObsidianPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let glass = Color(hex: 0x1B1826)
    let edge = Color(hex: 0x8A6FD6)

    func hex(_ r: CGFloat) -> Path {
        var pts: [CGPoint] = []
        for i in 0..<6 {
            let a = CGFloat(i) * (2 * .pi / 6) + 0.26
            pts.append(CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r))
        }
        return polygon(pts)
    }
    ctx.fill(hex(cell * 0.44), with: .color(glass.shaded(0.7)))
    ctx.fill(hex(cell * 0.40), with: .color(glass))
    ctx.stroke(hex(cell * 0.40), with: .color(edge.opacity(0.85)), style: stroke(cell * 0.018))
    // Conchoidal fracture: three long facets catching the light differently.
    for (i, a) in ([0.5, 2.6, 4.4] as [CGFloat]).enumerated() {
        ctx.fill(
            polygon([
                c,
                CGPoint(x: c.x + cos(a) * cell * 0.38, y: c.y + sin(a) * cell * 0.38),
                CGPoint(x: c.x + cos(a + 0.9) * cell * 0.34, y: c.y + sin(a + 0.9) * cell * 0.34),
            ]),
            with: .color(Color.white.opacity(0.05 + 0.035 * CGFloat(i)))
        )
    }
    ctx.stroke(
        line(CGPoint(x: c.x - cell * 0.16, y: c.y - cell * 0.20), CGPoint(x: c.x + cell * 0.12, y: c.y + cell * 0.06)),
        with: .color(edge.opacity(0.55)), style: stroke(cell * 0.014, cap: .round)
    )
}

/// A folded paper lily - creases, not curves.
nonisolated func drawOrigamiPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let paper = Color(hex: 0xF3E9D8)
    let fold = Color(hex: 0xD8C4A6)
    let accent = Color(hex: 0xE07A6B)

    // Eight flat petals, alternating shade, so every crease is a hard edge.
    for i in 0..<8 {
        let a = CGFloat(i) * (2 * .pi / 8) + 0.2
        let next = a + (2 * .pi / 8)
        ctx.fill(
            polygon([
                c,
                CGPoint(x: c.x + cos(a) * cell * 0.44, y: c.y + sin(a) * cell * 0.44),
                CGPoint(x: c.x + cos((a + next) / 2) * cell * 0.30, y: c.y + sin((a + next) / 2) * cell * 0.30),
                CGPoint(x: c.x + cos(next) * cell * 0.44, y: c.y + sin(next) * cell * 0.44),
            ]),
            with: .color(i % 2 == 0 ? paper : fold)
        )
    }
    for i in 0..<8 {
        let a = CGFloat(i) * (2 * .pi / 8) + 0.2
        ctx.stroke(
            line(c, CGPoint(x: c.x + cos(a) * cell * 0.44, y: c.y + sin(a) * cell * 0.44)),
            with: .color(fold.opacity(0.85)), style: stroke(cell * 0.010)
        )
    }
    ctx.fill(circle(c, cell * 0.075), with: .color(accent))
    ctx.fill(circle(c, cell * 0.032), with: .color(paper))
}

/// A standing stone cut with runes that catch the light.
nonisolated func drawRunePad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let stone = Color(hex: 0x6E7480)
    let dark = Color(hex: 0x474C56)
    let glyph = Color(hex: 0x7FE0C8)

    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.025), cell * 0.42), with: .color(dark))
    ctx.fill(circle(c, cell * 0.40), with: .color(stone))
    // A weathered rim, chipped rather than smooth.
    for i in 0..<12 {
        let a = CGFloat(i) * (2 * .pi / 12) + 0.15
        ctx.fill(
            circle(CGPoint(x: c.x + cos(a) * cell * 0.40, y: c.y + sin(a) * cell * 0.40), cell * (0.030 + 0.012 * CGFloat((i * 7) % 3))),
            with: .color(dark.opacity(0.5))
        )
    }
    // Three runes, each a few straight strokes - angular on purpose, because a
    // curve here reads as a doodle and a straight line reads as carved.
    let strokes: [[CGPoint]] = [
        [CGPoint(x: -0.18, y: -0.16), CGPoint(x: -0.18, y: 0.16), CGPoint(x: -0.04, y: 0)],
        [CGPoint(x: 0.02, y: -0.18), CGPoint(x: 0.02, y: 0.18)],
        [CGPoint(x: 0.10, y: -0.16), CGPoint(x: 0.22, y: 0), CGPoint(x: 0.10, y: 0.16)],
    ]
    for rune in strokes {
        for i in 0..<(rune.count - 1) {
            ctx.stroke(
                line(CGPoint(x: c.x + cell * rune[i].x, y: c.y + cell * rune[i].y),
                     CGPoint(x: c.x + cell * rune[i + 1].x, y: c.y + cell * rune[i + 1].y)),
                with: .color(glyph), style: stroke(cell * 0.028, cap: .round)
            )
        }
    }
    ctx.fill(circle(c, cell * 0.30), with: .color(glyph.opacity(0.12)))
}

/// A prism: one pad, split into every colour it can hold.
nonisolated func drawPrismPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let bands = [
        Color(hex: 0xE8524F), Color(hex: 0xF08A3C), Color(hex: 0xF3D24A),
        Color(hex: 0x56BE6A), Color(hex: 0x3E8BE0), Color(hex: 0x8E56C8),
    ]
    // Six wedges of the spectrum, then a glassy face over the top so it reads
    // as one solid thing rather than as a pie chart.
    for (i, colour) in bands.enumerated() {
        let a = CGFloat(i) * (2 * .pi / 6) - .pi / 2
        let next = a + (2 * .pi / 6)
        ctx.fill(
            polygon([
                c,
                CGPoint(x: c.x + cos(a) * cell * 0.42, y: c.y + sin(a) * cell * 0.42),
                CGPoint(x: c.x + cos(next) * cell * 0.42, y: c.y + sin(next) * cell * 0.42),
            ]),
            with: .color(colour.opacity(0.85))
        )
    }
    ctx.fill(circle(c, cell * 0.42), with: .color(Color.white.opacity(0.14)))
    ctx.stroke(circle(c, cell * 0.42), with: .color(Color.white.opacity(0.7)), style: stroke(cell * 0.022))
    // The facet: a triangle of white catching the light off-centre.
    let f = rotated(ctx, degrees: -18, pivot: c)
    f.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.14, y: c.y + cell * 0.10),
            CGPoint(x: c.x, y: c.y - cell * 0.18),
            CGPoint(x: c.x + cell * 0.14, y: c.y + cell * 0.10),
        ]),
        with: .color(Color.white.opacity(0.55))
    )
    ctx.fill(circle(CGPoint(x: c.x, y: c.y - cell * 0.02), cell * 0.045), with: .color(.white))
}
