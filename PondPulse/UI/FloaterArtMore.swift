//
//  FloaterArtMore.swift
//  PondPulse
//
//  The second shelf of pond friends and lily pads - a 1:1 port of the Android
//  ui/FloaterArtMore.kt. Same rules as FloaterArt.swift, which owns the
//  dispatchers and the shared helpers: everything is laid out in multiples of
//  `cell` so one function serves both the pond board and the little shop tile,
//  and every body colour goes through `bodyTint` so a red, green or blue puzzle
//  duckling stays readable no matter which friend is equipped.
//
//  Silhouette is what has to carry: at one grid cell on a phone these are read
//  at a glance and never studied, so each one leans on a shape no other friend
//  has - a spiral, a coiled tail, a spiked ball, four wings - rather than on
//  detail that vanishes at that size.
//

import SwiftUI

// MARK: - Pond friends

/// Barely a duckling yet: a fat head and a flick of tail.
nonisolated func drawTadpole(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x4C6B57))
    let dark = body.shaded()
    // Tail, whipping out behind and thinning to a point.
    var tail = Path()
    tail.move(to: CGPoint(x: c.x - cell * 0.06, y: c.y - cell * 0.02))
    tail.addCurve(
        to: CGPoint(x: c.x - cell * 0.42, y: c.y + cell * 0.02),
        control1: CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.16),
        control2: CGPoint(x: c.x - cell * 0.34, y: c.y + cell * 0.14)
    )
    ctx.stroke(tail, with: .color(dark), style: stroke(cell * 0.08, cap: .round))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.07, y: c.y + cell * 0.03), cell * 0.23), with: .color(dark))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.06, y: c.y), cell * 0.23), with: .color(body))
    // A glossy back and one big eye - the whole face at this size.
    ctx.fill(circle(CGPoint(x: c.x, y: c.y - cell * 0.10), cell * 0.08), with: .color(body.lightened(1.25).opacity(0.5)))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.14, y: c.y - cell * 0.04), cell * 0.07), with: .color(.white))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.155, y: c.y - cell * 0.04), cell * 0.038), with: .color(ink))
}

/// A pond snail: the spiral does all the work.
nonisolated func drawSnail(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xEBD9C0))
    let shell = color == nil ? Color(hex: 0xD79B52) : body.shaded(0.7)
    let shellDark = shell.shaded(0.78)
    // Foot.
    ctx.fill(
        oval(CGPoint(x: c.x - cell * 0.36, y: c.y + cell * 0.08), CGSize(width: cell * 0.70, height: cell * 0.22)),
        with: .color(body)
    )
    // Head stalk and eye stalks, leaning forward.
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.26, y: c.y + cell * 0.06), cell * 0.11), with: .color(body))
    for dx in [0.20, 0.31] as [CGFloat] {
        ctx.stroke(
            line(
                CGPoint(x: c.x + cell * dx, y: c.y + cell * 0.04),
                CGPoint(x: c.x + cell * (dx + 0.04), y: c.y - cell * 0.20)
            ),
            with: .color(body),
            style: stroke(cell * 0.035, cap: .round)
        )
        ctx.fill(circle(CGPoint(x: c.x + cell * (dx + 0.04), y: c.y - cell * 0.21), cell * 0.032), with: .color(ink))
    }
    // Shell: three turns of a spiral, drawn as shrinking discs.
    let hub = CGPoint(x: c.x - cell * 0.06, y: c.y - cell * 0.08)
    ctx.fill(circle(hub, cell * 0.30), with: .color(shellDark))
    ctx.fill(circle(CGPoint(x: hub.x, y: hub.y - cell * 0.01), cell * 0.27), with: .color(shell))
    var spiral = Path()
    for k in 0...44 {
        let t = CGFloat(k) / 44
        let angle = t * 3.1 * 2 * .pi
        let r = cell * 0.245 * (1 - t * 0.86)
        let p = CGPoint(x: hub.x - cell * 0.0 + cos(angle) * r, y: hub.y - cell * 0.01 + sin(angle) * r)
        if k == 0 { spiral.move(to: p) } else { spiral.addLine(to: p) }
    }
    ctx.stroke(spiral, with: .color(shellDark), style: stroke(cell * 0.035, cap: .round))
}

/// Claws out, eyes up: the one friend that reads sideways.
nonisolated func drawCrab(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xE8593A))
    let dark = body.shaded()
    // Legs.
    for dx in [-1.0, 1.0] as [CGFloat] {
        for k in 0..<3 {
            let from = CGPoint(x: c.x + dx * cell * 0.20, y: c.y + cell * 0.06 + CGFloat(k) * cell * 0.08)
            ctx.stroke(
                line(from, CGPoint(x: from.x + dx * cell * 0.20, y: from.y + cell * 0.10)),
                with: .color(dark),
                style: stroke(cell * 0.045, cap: .round)
            )
        }
    }
    // Claws, held high.
    for dx in [-1.0, 1.0] as [CGFloat] {
        let claw = CGPoint(x: c.x + dx * cell * 0.34, y: c.y - cell * 0.12)
        ctx.stroke(
            line(CGPoint(x: c.x + dx * cell * 0.19, y: c.y + cell * 0.02), claw),
            with: .color(dark),
            style: stroke(cell * 0.055, cap: .round)
        )
        ctx.fill(circle(claw, cell * 0.11), with: .color(body))
        // The pincer gap, cut out so the water shows through it.
        ctx.stroke(
            line(
                CGPoint(x: claw.x + dx * cell * 0.02, y: claw.y - cell * 0.02),
                CGPoint(x: claw.x + dx * cell * 0.11, y: claw.y - cell * 0.07)
            ),
            with: .color(dark),
            style: stroke(cell * 0.03, cap: .round)
        )
    }
    // Shell.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.14), CGSize(width: cell * 0.56, height: cell * 0.36)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.18), CGSize(width: cell * 0.56, height: cell * 0.36)), with: .color(body))
    // Eyes on stalks.
    for dx in [-1.0, 1.0] as [CGFloat] {
        let eye = CGPoint(x: c.x + dx * cell * 0.11, y: c.y - cell * 0.26)
        ctx.stroke(
            line(CGPoint(x: eye.x, y: eye.y + cell * 0.09), eye),
            with: .color(body),
            style: stroke(cell * 0.035, cap: .round)
        )
        ctx.fill(circle(eye, cell * 0.055), with: .color(.white))
        ctx.fill(circle(eye, cell * 0.03), with: .color(ink))
    }
}

/// All neck and dagger beak - the tallest silhouette on the pond.
nonisolated func drawHeron(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x97AFC4))
    let dark = body.shaded()
    // Body low in the water.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y + cell * 0.02), CGSize(width: cell * 0.58, height: cell * 0.30)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y - cell * 0.02), CGSize(width: cell * 0.58, height: cell * 0.30)), with: .color(body))
    // Folded wing.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.24, y: c.y + cell * 0.03), CGSize(width: cell * 0.30, height: cell * 0.16)), with: .color(dark.opacity(0.8)))
    // The long S-curved neck.
    var neck = Path()
    neck.move(to: CGPoint(x: c.x + cell * 0.12, y: c.y + cell * 0.06))
    neck.addCurve(
        to: CGPoint(x: c.x + cell * 0.18, y: c.y - cell * 0.36),
        control1: CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.06),
        control2: CGPoint(x: c.x + cell * 0.02, y: c.y - cell * 0.22)
    )
    ctx.stroke(neck, with: .color(body), style: stroke(cell * 0.085, cap: .round))
    let head = CGPoint(x: c.x + cell * 0.19, y: c.y - cell * 0.38)
    ctx.fill(circle(head, cell * 0.085), with: .color(body))
    // Black crest plume trailing back.
    ctx.stroke(
        line(
            CGPoint(x: head.x - cell * 0.02, y: head.y - cell * 0.04),
            CGPoint(x: head.x - cell * 0.17, y: head.y - cell * 0.10)
        ),
        with: .color(ink.opacity(0.75)),
        style: stroke(cell * 0.028, cap: .round)
    )
    // Spear of a beak.
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.035),
            CGPoint(x: head.x + cell * 0.32, y: head.y + cell * 0.02),
            CGPoint(x: head.x + cell * 0.05, y: head.y + cell * 0.045),
        ]),
        with: .color(Color(hex: 0xF2C14E))
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.015, y: head.y - cell * 0.02), cell * 0.026), with: .color(ink))
}

/// Canada goose: pale body, black neck, white chinstrap.
nonisolated func drawGoose(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xB6A88F))
    let dark = body.shaded()
    let neckInk = color == nil ? Color(hex: 0x2A2E33) : body.shaded(0.55)
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.02), CGSize(width: cell * 0.62, height: cell * 0.36)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.06), CGSize(width: cell * 0.62, height: cell * 0.36)), with: .color(body))
    // Tail flick.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.02),
            CGPoint(x: c.x - cell * 0.44, y: c.y - cell * 0.14),
            CGPoint(x: c.x - cell * 0.26, y: c.y + cell * 0.06),
        ]),
        with: .color(dark)
    )
    // Upright black neck.
    ctx.stroke(
        line(
            CGPoint(x: c.x + cell * 0.16, y: c.y + cell * 0.02),
            CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.28)
        ),
        with: .color(neckInk),
        style: stroke(cell * 0.115, cap: .round)
    )
    let head = CGPoint(x: c.x + cell * 0.23, y: c.y - cell * 0.31)
    ctx.fill(circle(head, cell * 0.105), with: .color(neckInk))
    // The chinstrap that names the bird.
    ctx.fill(
        oval(CGPoint(x: head.x - cell * 0.02, y: head.y - cell * 0.005), CGSize(width: cell * 0.09, height: cell * 0.13)),
        with: .color(Color(hex: 0xF6F4EE))
    )
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.07, y: head.y - cell * 0.035),
            CGPoint(x: head.x + cell * 0.22, y: head.y + cell * 0.015),
            CGPoint(x: head.x + cell * 0.07, y: head.y + cell * 0.06),
        ]),
        with: .color(color == nil ? Color(hex: 0x23262A) : body.shaded(0.5))
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.035, y: head.y - cell * 0.035), cell * 0.024), with: .color(.white))
}

/// A contented brown loaf with a blunt snout.
nonisolated func drawCapybara(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x9C6B44))
    let dark = body.shaded()
    // Body, mostly submerged.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.36, y: c.y - cell * 0.04), CGSize(width: cell * 0.60, height: cell * 0.34)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.36, y: c.y - cell * 0.09), CGSize(width: cell * 0.60, height: cell * 0.34)), with: .color(body))
    // Blocky head.
    ctx.fill(oval(CGPoint(x: c.x + cell * 0.04, y: c.y - cell * 0.26), CGSize(width: cell * 0.40, height: cell * 0.32)), with: .color(body))
    // Little round ears.
    for dy in [-0.30, -0.24] as [CGFloat] {
        ctx.fill(circle(CGPoint(x: c.x + cell * 0.11, y: c.y + cell * dy), cell * 0.055), with: .color(dark))
    }
    // Blunt muzzle.
    ctx.fill(
        oval(CGPoint(x: c.x + cell * 0.26, y: c.y - cell * 0.13), CGSize(width: cell * 0.19, height: cell * 0.15)),
        with: .color(body.lightened(1.12))
    )
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.40, y: c.y - cell * 0.075), cell * 0.028), with: .color(ink.opacity(0.8)))
    // The famous half-shut eye.
    ctx.stroke(
        ovalArc(
            CGPoint(x: c.x + cell * 0.13, y: c.y - cell * 0.19),
            CGSize(width: cell * 0.10, height: cell * 0.08),
            start: 190, sweep: 160, useCenter: false
        ),
        with: .color(ink),
        style: stroke(cell * 0.03, cap: .round)
    )
}

/// Baby seal: round, pale and whiskered.
nonisolated func drawSeal(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xC3CEDA))
    let dark = body.shaded(0.88)
    // Back flipper.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.24, y: c.y + cell * 0.02),
            CGPoint(x: c.x - cell * 0.46, y: c.y - cell * 0.14),
            CGPoint(x: c.x - cell * 0.40, y: c.y + cell * 0.12),
        ]),
        with: .color(dark)
    )
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.06), CGSize(width: cell * 0.60, height: cell * 0.36)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.11), CGSize(width: cell * 0.60, height: cell * 0.36)), with: .color(body))
    // Side flipper.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.10, y: c.y + cell * 0.06), CGSize(width: cell * 0.22, height: cell * 0.12)), with: .color(dark))
    // Head and snout.
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.17, y: c.y - cell * 0.16), cell * 0.20), with: .color(body))
    let snout = CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.11)
    ctx.fill(
        oval(CGPoint(x: snout.x - cell * 0.08, y: snout.y - cell * 0.05), CGSize(width: cell * 0.16, height: cell * 0.11)),
        with: .color(body.lightened(1.1))
    )
    ctx.fill(circle(CGPoint(x: snout.x + cell * 0.02, y: snout.y - cell * 0.015), cell * 0.03), with: .color(ink))
    // Two big dark eyes and a whisker or two.
    for dx in [0.06, 0.21] as [CGFloat] {
        ctx.fill(circle(CGPoint(x: c.x + cell * dx, y: c.y - cell * 0.21), cell * 0.042), with: .color(ink))
    }
    for dy in [-0.02, 0.02] as [CGFloat] {
        ctx.stroke(
            line(
                CGPoint(x: snout.x + cell * 0.04, y: snout.y + cell * dy),
                CGPoint(x: snout.x + cell * 0.18, y: snout.y + cell * (dy * 2.2))
            ),
            with: .color(ink.opacity(0.35)),
            style: stroke(cell * 0.016, cap: .round)
        )
    }
}

/// That beak. Nothing else on the pond has a pouch.
nonisolated func drawPelican(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xF1EDE2))
    let dark = body.shaded(0.9)
    let bill = color == nil ? Color(hex: 0xF9A03F) : body.shaded(0.72)
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.33, y: c.y - cell * 0.02), CGSize(width: cell * 0.60, height: cell * 0.34)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.33, y: c.y - cell * 0.06), CGSize(width: cell * 0.60, height: cell * 0.34)), with: .color(body))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.24, y: c.y), CGSize(width: cell * 0.30, height: cell * 0.17)), with: .color(dark))
    // Short thick neck.
    ctx.stroke(
        line(CGPoint(x: c.x + cell * 0.14, y: c.y), CGPoint(x: c.x + cell * 0.18, y: c.y - cell * 0.20)),
        with: .color(body),
        style: stroke(cell * 0.13, cap: .round)
    )
    let head = CGPoint(x: c.x + cell * 0.18, y: c.y - cell * 0.25)
    ctx.fill(circle(head, cell * 0.115), with: .color(body))
    // The pouch hanging under a long bill.
    var pouch = Path()
    pouch.move(to: CGPoint(x: head.x + cell * 0.03, y: head.y + cell * 0.02))
    pouch.addCurve(
        to: CGPoint(x: head.x + cell * 0.34, y: head.y - cell * 0.02),
        control1: CGPoint(x: head.x + cell * 0.14, y: head.y + cell * 0.26),
        control2: CGPoint(x: head.x + cell * 0.32, y: head.y + cell * 0.18)
    )
    pouch.closeSubpath()
    ctx.fill(pouch, with: .color(bill.lightened(1.1)))
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.04, y: head.y - cell * 0.06),
            CGPoint(x: head.x + cell * 0.37, y: head.y - cell * 0.03),
            CGPoint(x: head.x + cell * 0.34, y: head.y + cell * 0.03),
            CGPoint(x: head.x + cell * 0.04, y: head.y + cell * 0.02),
        ]),
        with: .color(bill)
    )
    ctx.fill(circle(CGPoint(x: head.x, y: head.y - cell * 0.045), cell * 0.028), with: .color(ink))
}

/// A jewel: teal back, rust belly, and a beak longer than its head.
nonisolated func drawKingfisher(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x27B0C7))
    let dark = body.shaded()
    let belly = color == nil ? Color(hex: 0xE07A3E) : body.lightened(1.25)
    // Belly first, back over it.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.20, y: c.y - cell * 0.06), CGSize(width: cell * 0.44, height: cell * 0.32)), with: .color(belly))
    var back = Path()
    back.move(to: CGPoint(x: c.x - cell * 0.34, y: c.y + cell * 0.02))
    back.addCurve(
        to: CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.14),
        control1: CGPoint(x: c.x - cell * 0.20, y: c.y - cell * 0.24),
        control2: CGPoint(x: c.x + cell * 0.14, y: c.y - cell * 0.26)
    )
    back.addLine(to: CGPoint(x: c.x + cell * 0.06, y: c.y + cell * 0.06))
    back.closeSubpath()
    ctx.fill(back, with: .color(body))
    // Stubby tail.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.02),
            CGPoint(x: c.x - cell * 0.45, y: c.y + cell * 0.04),
            CGPoint(x: c.x - cell * 0.28, y: c.y + cell * 0.12),
        ]),
        with: .color(dark)
    )
    let head = CGPoint(x: c.x + cell * 0.16, y: c.y - cell * 0.20)
    ctx.fill(circle(head, cell * 0.145), with: .color(body))
    // White cheek flash.
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.01, y: head.y + cell * 0.075), cell * 0.045), with: .color(Color(hex: 0xF7FAFB)))
    // Dagger beak.
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.08, y: head.y - cell * 0.045),
            CGPoint(x: head.x + cell * 0.40, y: head.y + cell * 0.02),
            CGPoint(x: head.x + cell * 0.08, y: head.y + cell * 0.055),
        ]),
        with: .color(ink.opacity(0.85))
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.045, y: head.y - cell * 0.045), cell * 0.032), with: .color(ink))
}
