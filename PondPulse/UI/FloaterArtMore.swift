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

/// Four wings and a needle body - nothing else in the pond looks like it.
nonisolated func drawDragonfly(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x54D2C0))
    let dark = body.shaded()
    let wing = Color(hex: 0xEAF7FF).opacity(0.72)
    let vein = Color(hex: 0x9FC4D6).opacity(0.85)
    // Two pairs of wings, swept apart so the count reads.
    for dy in [-1.0, 1.0] as [CGFloat] {
        for dx in [-0.02, 0.20] as [CGFloat] {
            var rc = rotated(ctx, degrees: dy * 17, pivot: c)
            rc.fill(
                oval(
                    CGPoint(x: c.x + cell * (dx - 0.30), y: c.y + dy * cell * 0.05 - cell * 0.05),
                    CGSize(width: cell * 0.38, height: cell * 0.11)
                ),
                with: .color(wing)
            )
            rc.stroke(
                line(
                    CGPoint(x: c.x + cell * (dx - 0.28), y: c.y + dy * cell * 0.05 + cell * 0.005),
                    CGPoint(x: c.x + cell * (dx + 0.06), y: c.y + dy * cell * 0.05 + cell * 0.005)
                ),
                with: .color(vein),
                style: stroke(cell * 0.012)
            )
        }
    }
    // Segmented abdomen trailing to the left.
    for k in 0..<5 {
        ctx.fill(
            circle(
                CGPoint(x: c.x - cell * (0.10 + CGFloat(k) * 0.075), y: c.y + cell * 0.015),
                cell * (0.055 - CGFloat(k) * 0.006)
            ),
            with: .color(k % 2 == 0 ? body : dark)
        )
    }
    // Thorax and the big compound eyes.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.06, y: c.y - cell * 0.08), CGSize(width: cell * 0.24, height: cell * 0.16)), with: .color(body))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.24, y: c.y - cell * 0.02), cell * 0.115), with: .color(dark))
    for dy in [-1.0, 1.0] as [CGFloat] {
        ctx.fill(circle(CGPoint(x: c.x + cell * 0.29, y: c.y + dy * cell * 0.05), cell * 0.045), with: .color(ink))
        ctx.fill(circle(CGPoint(x: c.x + cell * 0.31, y: c.y + dy * cell * 0.06), cell * 0.016), with: .color(Color.white.opacity(0.7)))
    }
}

/// Folded paper, all straight edges - the companion piece to the paper boat.
nonisolated func drawPaperCrane(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let paper = bodyTint(palette, color, Color(hex: 0xF7F3E8))
    let fold = paper.shaded(0.86)
    let crease = paper.shaded(0.72)
    // Far wing, up and back.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.04, y: c.y - cell * 0.02),
            CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.34),
            CGPoint(x: c.x - cell * 0.08, y: c.y - cell * 0.30),
        ]),
        with: .color(fold)
    )
    // Tail, a straight paper spike.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.06, y: c.y + cell * 0.02),
            CGPoint(x: c.x - cell * 0.44, y: c.y - cell * 0.06),
            CGPoint(x: c.x - cell * 0.10, y: c.y + cell * 0.14),
        ]),
        with: .color(crease)
    )
    // Body: a folded diamond hull.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.10, y: c.y - cell * 0.02),
            CGPoint(x: c.x + cell * 0.16, y: c.y - cell * 0.14),
            CGPoint(x: c.x + cell * 0.22, y: c.y + cell * 0.10),
            CGPoint(x: c.x - cell * 0.14, y: c.y + cell * 0.18),
        ]),
        with: .color(paper)
    )
    // Near wing, catching the light.
    let nearWing = polygon([
        CGPoint(x: c.x + cell * 0.02, y: c.y - cell * 0.04),
        CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.36),
        CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.02),
    ])
    ctx.fill(nearWing, with: .color(paper.lightened(1.06)))
    ctx.stroke(nearWing, with: .color(crease), style: stroke(cell * 0.018))
    // Neck and head, folded to a point.
    let neck = polygon([
        CGPoint(x: c.x + cell * 0.14, y: c.y - cell * 0.10),
        CGPoint(x: c.x + cell * 0.42, y: c.y - cell * 0.30),
        CGPoint(x: c.x + cell * 0.20, y: c.y),
    ])
    ctx.fill(neck, with: .color(paper))
    ctx.stroke(neck, with: .color(crease), style: stroke(cell * 0.018))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.33, y: c.y - cell * 0.235), cell * 0.026), with: .color(ink))
}

/// A floating paper lantern, lit from inside.
nonisolated func drawLantern(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let shell = bodyTint(palette, color, Color(hex: 0xF8B25C))
    let warm = shell.lightened(1.22)
    let rib = shell.shaded(0.78)
    // The glow it throws on the water.
    ctx.fill(circle(c, cell * 0.46), with: .color(Color(hex: 0xFFD79A).opacity(0.22)))
    // Little float tray.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.26, y: c.y + cell * 0.22), CGSize(width: cell * 0.52, height: cell * 0.14)), with: .color(Color(hex: 0x8C6239)))
    // Body of the lantern.
    ctx.fill(
        Path(roundedRect: CGRect(x: c.x - cell * 0.22, y: c.y - cell * 0.28, width: cell * 0.44, height: cell * 0.52),
             cornerSize: CGSize(width: cell * 0.14, height: cell * 0.12)),
        with: .color(shell)
    )
    // Ribs.
    for dy in [-0.12, 0.02, 0.16] as [CGFloat] {
        ctx.stroke(
            line(CGPoint(x: c.x - cell * 0.21, y: c.y + cell * dy), CGPoint(x: c.x + cell * 0.21, y: c.y + cell * dy)),
            with: .color(rib.opacity(0.65)),
            style: stroke(cell * 0.022)
        )
    }
    // Candle glow behind the paper.
    ctx.fill(
        oval(CGPoint(x: c.x - cell * 0.09, y: c.y - cell * 0.10), CGSize(width: cell * 0.18, height: cell * 0.26)),
        with: .color(warm.opacity(0.85))
    )
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.02), cell * 0.05), with: .color(Color(hex: 0xFFF3CF)))
    // Cap and handle.
    ctx.fill(
        Path(roundedRect: CGRect(x: c.x - cell * 0.16, y: c.y - cell * 0.34, width: cell * 0.32, height: cell * 0.09),
             cornerSize: CGSize(width: cell * 0.04, height: cell * 0.04)),
        with: .color(rib)
    )
    ctx.stroke(
        ovalArc(
            CGPoint(x: c.x - cell * 0.10, y: c.y - cell * 0.46),
            CGSize(width: cell * 0.20, height: cell * 0.16),
            start: 200, sweep: 140, useCenter: false
        ),
        with: .color(rib),
        style: stroke(cell * 0.025, cap: .round)
    )
}

/// Puffed up and bristling - a ball of spikes.
nonisolated func drawPufferfish(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xF2C14E))
    let dark = body.shaded()
    // Tail.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.24, y: c.y),
            CGPoint(x: c.x - cell * 0.46, y: c.y - cell * 0.14),
            CGPoint(x: c.x - cell * 0.46, y: c.y + cell * 0.14),
        ]),
        with: .color(dark)
    )
    // Spikes all the way round, drawn before the body so they read as quills.
    for k in 0..<14 {
        let angle = CGFloat(k) * (360.0 / 14.0) * .pi / 180
        let dir = CGPoint(x: cos(angle), y: sin(angle))
        ctx.fill(
            polygon([
                CGPoint(x: c.x + dir.x * cell * 0.36, y: c.y + dir.y * cell * 0.36),
                CGPoint(x: c.x + dir.x * cell * 0.20 - dir.y * cell * 0.06,
                        y: c.y + dir.y * cell * 0.20 + dir.x * cell * 0.06),
                CGPoint(x: c.x + dir.x * cell * 0.20 + dir.y * cell * 0.06,
                        y: c.y + dir.y * cell * 0.20 - dir.x * cell * 0.06),
            ]),
            with: .color(dark)
        )
    }
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.03), cell * 0.27), with: .color(dark))
    ctx.fill(circle(c, cell * 0.27), with: .color(body))
    // Pale belly.
    ctx.fill(
        oval(CGPoint(x: c.x - cell * 0.16, y: c.y + cell * 0.07), CGSize(width: cell * 0.32, height: cell * 0.16)),
        with: .color(body.lightened(1.2))
    )
    // Wide-set eyes and a small round mouth.
    for dx in [0.03, 0.19] as [CGFloat] {
        ctx.fill(circle(CGPoint(x: c.x + cell * dx, y: c.y - cell * 0.08), cell * 0.062), with: .color(.white))
        ctx.fill(circle(CGPoint(x: c.x + cell * (dx + 0.012), y: c.y - cell * 0.08), cell * 0.035), with: .color(ink))
    }
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.22, y: c.y + cell * 0.05), cell * 0.045), with: .color(body.shaded(0.6)))
}

/// The coiled tail is the whole read.
nonisolated func drawSeahorse(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xF6A03C))
    let dark = body.shaded()
    // Dorsal fin behind the spine.
    ctx.fill(
        oval(CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.14), CGSize(width: cell * 0.14, height: cell * 0.28)),
        with: .color(dark.opacity(0.75))
    )
    // Body: an S from the head down into a curl.
    var spine = Path()
    spine.move(to: CGPoint(x: c.x + cell * 0.06, y: c.y - cell * 0.26))
    spine.addCurve(
        to: CGPoint(x: c.x - cell * 0.02, y: c.y + cell * 0.20),
        control1: CGPoint(x: c.x - cell * 0.12, y: c.y - cell * 0.10),
        control2: CGPoint(x: c.x + cell * 0.10, y: c.y + cell * 0.06)
    )
    spine.addCurve(
        to: CGPoint(x: c.x + cell * 0.10, y: c.y + cell * 0.18),
        control1: CGPoint(x: c.x - cell * 0.14, y: c.y + cell * 0.34),
        control2: CGPoint(x: c.x + cell * 0.18, y: c.y + cell * 0.34)
    )
    ctx.stroke(spine, with: .color(body), style: stroke(cell * 0.15, cap: .round))
    ctx.stroke(spine, with: .color(dark.opacity(0.5)), style: stroke(cell * 0.05, cap: .round))
    // Head with the long snout.
    let head = CGPoint(x: c.x + cell * 0.09, y: c.y - cell * 0.29)
    ctx.fill(circle(head, cell * 0.115), with: .color(body))
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.02),
            CGPoint(x: head.x + cell * 0.30, y: head.y + cell * 0.06),
            CGPoint(x: head.x + cell * 0.05, y: head.y + cell * 0.08),
        ]),
        with: .color(body)
    )
    // Coronet.
    for dx in [-0.05, 0.02, 0.08] as [CGFloat] {
        ctx.stroke(
            line(
                CGPoint(x: head.x + cell * dx, y: head.y - cell * 0.08),
                CGPoint(x: head.x + cell * (dx - 0.02), y: head.y - cell * 0.20)
            ),
            with: .color(dark),
            style: stroke(cell * 0.03, cap: .round)
        )
    }
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.02, y: head.y - cell * 0.005), cell * 0.032), with: .color(ink))
}

/// Dome and eight arms, spread wide.
nonisolated func drawOctopus(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xB56BD6))
    let dark = body.shaded()
    // Arms, curling out under the head.
    for k in 0..<6 {
        let t = CGFloat(k) / 5
        let x = c.x + (t - 0.5) * cell * 0.66
        let curl: CGFloat = k % 2 == 0 ? 1 : -1
        var arm = Path()
        arm.move(to: CGPoint(x: x, y: c.y + cell * 0.06))
        arm.addCurve(
            to: CGPoint(x: x + curl * cell * 0.05, y: c.y + cell * 0.40),
            control1: CGPoint(x: x + curl * cell * 0.06, y: c.y + cell * 0.22),
            control2: CGPoint(x: x - curl * cell * 0.10, y: c.y + cell * 0.30)
        )
        ctx.stroke(arm, with: .color(k % 2 == 0 ? body : dark), style: stroke(cell * 0.075, cap: .round))
    }
    // Mantle.
    ctx.fill(circle(CGPoint(x: c.x, y: c.y - cell * 0.06), cell * 0.30), with: .color(dark))
    ctx.fill(
        ovalArc(
            CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.40),
            CGSize(width: cell * 0.60, height: cell * 0.60),
            start: 180, sweep: 180, useCenter: true
        ),
        with: .color(body)
    )
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.16), CGSize(width: cell * 0.60, height: cell * 0.24)), with: .color(body))
    // Highlight and eyes.
    ctx.fill(
        oval(CGPoint(x: c.x - cell * 0.17, y: c.y - cell * 0.31), CGSize(width: cell * 0.16, height: cell * 0.10)),
        with: .color(body.lightened(1.25).opacity(0.55))
    )
    for dx in [-0.13, 0.13] as [CGFloat] {
        ctx.fill(circle(CGPoint(x: c.x + cell * dx, y: c.y - cell * 0.09), cell * 0.075), with: .color(.white))
        ctx.fill(circle(CGPoint(x: c.x + cell * (dx + 0.012), y: c.y - cell * 0.085), cell * 0.042), with: .color(ink))
    }
}

/// Duck bill on a swimming mammal - the joke is the point.
nonisolated func drawPlatypus(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x7E5A3D))
    let dark = body.shaded()
    let bill = color == nil ? Color(hex: 0x43301F) : body.shaded(0.55)
    // Flat paddle tail.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.48, y: c.y - cell * 0.06), CGSize(width: cell * 0.34, height: cell * 0.24)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y - cell * 0.08), CGSize(width: cell * 0.56, height: cell * 0.32)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y - cell * 0.12), CGSize(width: cell * 0.56, height: cell * 0.32)), with: .color(body))
    // Webbed foot breaking the surface.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.02, y: c.y + cell * 0.14),
            CGPoint(x: c.x + cell * 0.14, y: c.y + cell * 0.24),
            CGPoint(x: c.x - cell * 0.10, y: c.y + cell * 0.24),
        ]),
        with: .color(dark)
    )
    // Head.
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.19, y: c.y - cell * 0.13), cell * 0.165), with: .color(body))
    // The bill.
    ctx.fill(oval(CGPoint(x: c.x + cell * 0.24, y: c.y - cell * 0.13), CGSize(width: cell * 0.28, height: cell * 0.14)), with: .color(bill))
    ctx.stroke(
        line(CGPoint(x: c.x + cell * 0.26, y: c.y - cell * 0.06), CGPoint(x: c.x + cell * 0.50, y: c.y - cell * 0.06)),
        with: .color(bill.shaded(0.8)),
        style: stroke(cell * 0.016)
    )
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.19), cell * 0.03), with: .color(ink))
}

/// A wind-up bath sub: porthole, periscope, one fin.
nonisolated func drawSubmarine(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let hull = bodyTint(palette, color, Color(hex: 0xFFC93C))
    let dark = hull.shaded()
    let metal = Color(hex: 0x5A6B78)
    // Rear fin.
    ctx.fill(
        polygon([
            CGPoint(x: c.x - cell * 0.26, y: c.y),
            CGPoint(x: c.x - cell * 0.46, y: c.y - cell * 0.20),
            CGPoint(x: c.x - cell * 0.40, y: c.y + cell * 0.12),
        ]),
        with: .color(dark)
    )
    // Hull.
    ctx.fill(
        Path(roundedRect: CGRect(x: c.x - cell * 0.34, y: c.y - cell * 0.12, width: cell * 0.66, height: cell * 0.30),
             cornerSize: CGSize(width: cell * 0.15, height: cell * 0.15)),
        with: .color(dark)
    )
    ctx.fill(
        Path(roundedRect: CGRect(x: c.x - cell * 0.34, y: c.y - cell * 0.16, width: cell * 0.66, height: cell * 0.30),
             cornerSize: CGSize(width: cell * 0.15, height: cell * 0.15)),
        with: .color(hull)
    )
    // Conning tower and periscope.
    ctx.fill(
        Path(roundedRect: CGRect(x: c.x - cell * 0.06, y: c.y - cell * 0.32, width: cell * 0.20, height: cell * 0.18),
             cornerSize: CGSize(width: cell * 0.05, height: cell * 0.05)),
        with: .color(hull)
    )
    ctx.stroke(
        line(CGPoint(x: c.x + cell * 0.03, y: c.y - cell * 0.30), CGPoint(x: c.x + cell * 0.03, y: c.y - cell * 0.44)),
        with: .color(metal),
        style: stroke(cell * 0.035, cap: .round)
    )
    ctx.stroke(
        line(CGPoint(x: c.x + cell * 0.03, y: c.y - cell * 0.43), CGPoint(x: c.x + cell * 0.13, y: c.y - cell * 0.43)),
        with: .color(metal),
        style: stroke(cell * 0.035, cap: .round)
    )
    // Porthole.
    let port = CGPoint(x: c.x + cell * 0.14, y: c.y - cell * 0.01)
    ctx.fill(circle(port, cell * 0.095), with: .color(metal))
    ctx.fill(circle(port, cell * 0.065), with: .color(Color(hex: 0xBFEAF7)))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.12, y: c.y - cell * 0.035), cell * 0.022), with: .color(Color.white.opacity(0.8)))
    // Rivets.
    for dx in [-0.22, -0.14, -0.06] as [CGFloat] {
        ctx.fill(circle(CGPoint(x: c.x + cell * dx, y: c.y + cell * 0.06), cell * 0.018), with: .color(dark.opacity(0.7)))
    }
}

/// The duckling as 8-bit sprite: every shape is a square.
nonisolated func drawPixelDuck(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let body = bodyTint(palette, color, palette.duckTint(nil))
    let dark = body.shaded()
    let beak = Color(hex: 0xFF9E2C)
    // A 10x10 sprite grid centred in the cell, so nothing lands on a half pixel.
    let px = cell * 0.082
    let origin = CGPoint(x: rect.midX - px * 5, y: rect.midY - px * 5)
    func blk(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ c: Color) {
        ctx.fill(
            Path(CGRect(x: origin.x + px * CGFloat(x), y: origin.y + px * CGFloat(y),
                        width: px * CGFloat(w), height: px * CGFloat(h))),
            with: .color(c)
        )
    }
    // Head.
    blk(4, 1, 4, 1, body); blk(3, 2, 5, 3, body)
    // Beak, two pixels proud of the face.
    blk(8, 3, 2, 1, beak); blk(8, 4, 1, 1, beak.shaded())
    // Eye.
    blk(6, 3, 1, 1, ink)
    // Neck and body.
    blk(4, 5, 3, 1, body); blk(1, 6, 8, 3, body)
    // Wing and tail shading.
    blk(3, 7, 3, 2, dark); blk(0, 6, 1, 2, dark)
    // Waterline.
    blk(1, 9, 8, 1, dark)
}

/// Premium: a duckling made of fire, with a flame crest and burning tail.
nonisolated func drawPhoenix(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xFF7A29))
    let ember = color == nil ? Color(hex: 0xFFD24A) : body.lightened(1.35)
    let deep = color == nil ? Color(hex: 0xD8391C) : body.shaded(0.7)
    // Heat haze.
    ctx.fill(circle(c, cell * 0.48), with: .color(ember.opacity(0.16)))
    // Three tail flames.
    for (k, spread) in [-0.30, -0.14, 0.02].enumerated() {
        let spread = CGFloat(spread)
        var flame = Path()
        flame.move(to: CGPoint(x: c.x - cell * 0.16, y: c.y + cell * 0.06))
        flame.addCurve(
            to: CGPoint(x: c.x - cell * (0.44 - CGFloat(k) * 0.04), y: c.y + cell * (spread - 0.10)),
            control1: CGPoint(x: c.x - cell * 0.34, y: c.y + cell * spread),
            control2: CGPoint(x: c.x - cell * 0.30, y: c.y + cell * (spread - 0.18))
        )
        flame.addCurve(
            to: CGPoint(x: c.x - cell * 0.16, y: c.y + cell * 0.06),
            control1: CGPoint(x: c.x - cell * 0.26, y: c.y + cell * (spread + 0.04)),
            control2: CGPoint(x: c.x - cell * 0.24, y: c.y + cell * 0.10)
        )
        ctx.fill(flame, with: .color(k == 1 ? ember : deep))
    }
    // Body.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.26, y: c.y - cell * 0.06), CGSize(width: cell * 0.52, height: cell * 0.34)), with: .color(deep))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.26, y: c.y - cell * 0.10), CGSize(width: cell * 0.52, height: cell * 0.34)), with: .color(body))
    // Wing, lifted.
    var wing = Path()
    wing.move(to: CGPoint(x: c.x - cell * 0.14, y: c.y + cell * 0.02))
    wing.addCurve(
        to: CGPoint(x: c.x + cell * 0.12, y: c.y + cell * 0.04),
        control1: CGPoint(x: c.x - cell * 0.04, y: c.y - cell * 0.26),
        control2: CGPoint(x: c.x + cell * 0.14, y: c.y - cell * 0.20)
    )
    wing.closeSubpath()
    ctx.fill(wing, with: .color(ember))
    // Head.
    let head = CGPoint(x: c.x + cell * 0.18, y: c.y - cell * 0.22)
    ctx.fill(circle(head, cell * 0.155), with: .color(body))
    // Crest of three flames.
    for dx in [-0.06, 0.02, 0.09] as [CGFloat] {
        ctx.fill(
            polygon([
                CGPoint(x: head.x + cell * (dx - 0.05), y: head.y - cell * 0.10),
                CGPoint(x: head.x + cell * dx, y: head.y - cell * 0.34),
                CGPoint(x: head.x + cell * (dx + 0.05), y: head.y - cell * 0.10),
            ]),
            with: .color(ember)
        )
    }
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.10, y: head.y - cell * 0.05),
            CGPoint(x: head.x + cell * 0.32, y: head.y + cell * 0.015),
            CGPoint(x: head.x + cell * 0.10, y: head.y + cell * 0.08),
        ]),
        with: .color(Color(hex: 0xFFC93C))
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.04, y: head.y - cell * 0.04), cell * 0.032), with: .color(ink))
}

/// Premium: a white duckling with a rainbow mane and a gold horn.
nonisolated func drawUnicornDuck(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xFDFBFF))
    let dark = body.shaded(0.9)
    let mane = [
        Color(hex: 0xFF6B8A), Color(hex: 0xFFB347), Color(hex: 0xFFE066),
        Color(hex: 0x6BD98B), Color(hex: 0x5AB9F0), Color(hex: 0xB07BE8),
    ]
    // Rainbow tail, one stripe per colour.
    for (k, stripe) in mane.enumerated() {
        let t = CGFloat(k) / CGFloat(mane.count - 1)
        ctx.stroke(
            line(
                CGPoint(x: c.x - cell * 0.22, y: c.y + cell * 0.02),
                CGPoint(x: c.x - cell * (0.40 + t * 0.06), y: c.y + cell * (0.16 - t * 0.34))
            ),
            with: .color(stripe),
            style: stroke(cell * 0.055, cap: .round)
        )
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.04), CGSize(width: cell * 0.54, height: cell * 0.34)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.08), CGSize(width: cell * 0.54, height: cell * 0.34)), with: .color(body))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.20, y: c.y), CGSize(width: cell * 0.28, height: cell * 0.18)), with: .color(dark))
    let head = CGPoint(x: c.x + cell * 0.17, y: c.y - cell * 0.22)
    ctx.fill(circle(head, cell * 0.16), with: .color(body))
    // Rainbow forelock over the brow.
    for (k, stripe) in mane.prefix(4).enumerated() {
        ctx.stroke(
            line(
                CGPoint(x: head.x - cell * (0.02 + CGFloat(k) * 0.03), y: head.y - cell * 0.10),
                CGPoint(x: head.x - cell * (0.14 + CGFloat(k) * 0.03), y: head.y + cell * 0.06)
            ),
            with: .color(stripe),
            style: stroke(cell * 0.035, cap: .round)
        )
    }
    // Spiral horn.
    ctx.fill(
        polygon([
            CGPoint(x: head.x - cell * 0.02, y: head.y - cell * 0.12),
            CGPoint(x: head.x + cell * 0.09, y: head.y - cell * 0.42),
            CGPoint(x: head.x + cell * 0.08, y: head.y - cell * 0.10),
        ]),
        with: .color(Color(hex: 0xFFD24A))
    )
    for k in 0..<3 {
        ctx.stroke(
            line(
                CGPoint(x: head.x + cell * (CGFloat(k) * 0.012), y: head.y - cell * (0.17 + CGFloat(k) * 0.08)),
                CGPoint(x: head.x + cell * (0.075 - CGFloat(k) * 0.004), y: head.y - cell * (0.20 + CGFloat(k) * 0.08))
            ),
            with: .color(Color(hex: 0xC7920F)),
            style: stroke(cell * 0.018, cap: .round)
        )
    }
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.11, y: head.y - cell * 0.04),
            CGPoint(x: head.x + cell * 0.33, y: head.y + cell * 0.025),
            CGPoint(x: head.x + cell * 0.11, y: head.y + cell * 0.09),
        ]),
        with: .color(Color(hex: 0xFFB0C8))
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.045, y: head.y - cell * 0.045), cell * 0.032), with: .color(ink))
    // One sparkle, tucked against the horn. Floated off in the empty corner it
    // read as a stray plus sign rather than as part of the friend.
    let twinkle = CGPoint(x: head.x + cell * 0.20, y: head.y - cell * 0.34)
    for rotation in [0.0, 90.0] as [CGFloat] {
        let rc = rotated(ctx, degrees: rotation, pivot: twinkle)
        rc.stroke(
            line(CGPoint(x: twinkle.x - cell * 0.06, y: twinkle.y), CGPoint(x: twinkle.x + cell * 0.06, y: twinkle.y)),
            with: .color(Color(hex: 0xFFF7D6)),
            style: stroke(cell * 0.022, cap: .round)
        )
    }
}

// MARK: - Lily pads

/// An autumn maple leaf, floating on its own reflection.
nonisolated func drawLeafPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let leafTop = Color(hex: 0xE8813A)
    let leafDeep = Color(hex: 0xB4501F)
    func maple(_ at: CGPoint) -> Path {
        // Five lobes swept round a centre, each a spike with a notch beside it.
        var p = Path()
        for k in 0..<5 {
            let a = (CGFloat(k) * 72 - 90) * .pi / 180
            let b = ((CGFloat(k) + 0.5) * 72 - 90) * .pi / 180
            let tip = CGPoint(x: at.x + cos(a) * cell * 0.42, y: at.y + sin(a) * cell * 0.42)
            let notch = CGPoint(x: at.x + cos(b) * cell * 0.17, y: at.y + sin(b) * cell * 0.17)
            if k == 0 { p.move(to: tip) } else { p.addLine(to: tip) }
            p.addLine(to: notch)
        }
        p.closeSubpath()
        return p
    }
    ctx.fill(maple(CGPoint(x: c.x, y: c.y + cell * 0.035)), with: .color(leafDeep))
    ctx.fill(maple(c), with: .color(leafTop))
    // Veins out to three of the lobes.
    for k in [0, 1, 4] {
        let a = (CGFloat(k) * 72 - 90) * .pi / 180
        ctx.stroke(
            line(c, CGPoint(x: c.x + cos(a) * cell * 0.32, y: c.y + sin(a) * cell * 0.32)),
            with: .color(leafDeep.opacity(0.6)),
            style: stroke(cell * 0.025, cap: .round)
        )
    }
}

/// A toadstool cap, upturned like a little boat.
nonisolated func drawMushroomPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let cap = Color(hex: 0xE0473C)
    let capDark = Color(hex: 0x9E2A24)
    let gills = Color(hex: 0xF6E7CE)
    // Underside showing at the waterline.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.40, y: c.y + cell * 0.04), CGSize(width: cell * 0.80, height: cell * 0.22)), with: .color(gills))
    for dx in -3...3 {
        ctx.stroke(
            line(
                CGPoint(x: c.x + CGFloat(dx) * cell * 0.10, y: c.y + cell * 0.07),
                CGPoint(x: c.x + CGFloat(dx) * cell * 0.10, y: c.y + cell * 0.19)
            ),
            with: .color(capDark.opacity(0.25)),
            style: stroke(cell * 0.018)
        )
    }
    // Cap.
    ctx.fill(
        ovalArc(CGPoint(x: c.x - cell * 0.42, y: c.y - cell * 0.30), CGSize(width: cell * 0.84, height: cell * 0.72),
                start: 180, sweep: 180, useCenter: true),
        with: .color(capDark)
    )
    ctx.fill(
        ovalArc(CGPoint(x: c.x - cell * 0.42, y: c.y - cell * 0.34), CGSize(width: cell * 0.84, height: cell * 0.72),
                start: 180, sweep: 180, useCenter: true),
        with: .color(cap)
    )
    // Spots.
    for (dx, dy, r) in [(-0.20, -0.10, 0.075), (0.06, -0.18, 0.065), (0.24, -0.02, 0.05)] as [(CGFloat, CGFloat, CGFloat)] {
        ctx.fill(circle(CGPoint(x: c.x + cell * dx, y: c.y + cell * dy), cell * r), with: .color(Color(hex: 0xFFF6E8)))
    }
}

/// A flat river stone with a carved ring - the quiet one.
nonisolated func drawStonePad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let stone = Color(hex: 0x9AA5AC)
    let stoneDark = Color(hex: 0x6B767D)
    func slab(_ at: CGPoint) -> Path {
        // A worn heptagon: no two edges the same, so it reads as river stone.
        let radii: [CGFloat] = [0.42, 0.38, 0.41, 0.35, 0.40, 0.36, 0.39]
        var p = Path()
        for k in radii.indices {
            let a = (CGFloat(k) * (360 / CGFloat(radii.count)) - 18) * .pi / 180
            let pt = CGPoint(x: at.x + cos(a) * cell * radii[k], y: at.y + sin(a) * cell * radii[k])
            if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
    ctx.fill(slab(CGPoint(x: c.x, y: c.y + cell * 0.04)), with: .color(stoneDark))
    ctx.fill(slab(c), with: .color(stone))
    // Carved ring and a highlight.
    ctx.stroke(circle(c, cell * 0.20), with: .color(stoneDark.opacity(0.7)), style: stroke(cell * 0.035))
    ctx.stroke(circle(c, cell * 0.09), with: .color(stoneDark.opacity(0.5)), style: stroke(cell * 0.025))
    ctx.fill(
        oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.27), CGSize(width: cell * 0.20, height: cell * 0.09)),
        with: .color(Color.white.opacity(0.28))
    )
}

/// A cloud puff that drifted down onto the water.
nonisolated func drawCloudPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let cloud = Color(hex: 0xFBFDFF)
    let shadowed = Color(hex: 0xCBDCEA)
    let lobes: [(CGFloat, CGFloat, CGFloat)] = [
        (-0.22, 0.02, 0.21),
        (0.00, -0.10, 0.25),
        (0.23, 0.01, 0.19),
        (-0.08, 0.10, 0.20),
        (0.11, 0.11, 0.18),
    ]
    for (dx, dy, r) in lobes {
        ctx.fill(circle(CGPoint(x: c.x + cell * dx, y: c.y + cell * (dy + 0.05)), cell * r), with: .color(shadowed))
    }
    for (dx, dy, r) in lobes {
        ctx.fill(circle(CGPoint(x: c.x + cell * dx, y: c.y + cell * dy), cell * r), with: .color(cloud))
    }
    // A hint of sky-blue in the hollow.
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.02, y: c.y + cell * 0.10), cell * 0.09), with: .color(shadowed.opacity(0.5)))
}

/// A woven nest of twigs, the cosiest dock in the pond.
nonisolated func drawNestPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let twig = Color(hex: 0x9A7346)
    let twigDark = Color(hex: 0x6B4E2E)
    let downy = Color(hex: 0xE3CDA6)
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.42, y: c.y - cell * 0.26), CGSize(width: cell * 0.84, height: cell * 0.60)), with: .color(twigDark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.42, y: c.y - cell * 0.30), CGSize(width: cell * 0.84, height: cell * 0.60)), with: .color(twig))
    // Soft lining.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.26, y: c.y - cell * 0.18), CGSize(width: cell * 0.52, height: cell * 0.34)), with: .color(downy))
    // Twigs crossing the rim, drawn as short chords around the oval.
    for k in 0..<9 {
        let a = (CGFloat(k) * 40 + 12) * .pi / 180
        let b = a + 0.75
        ctx.stroke(
            line(
                CGPoint(x: c.x + cos(a) * cell * 0.40, y: c.y + sin(a) * cell * 0.28),
                CGPoint(x: c.x + cos(b) * cell * 0.40, y: c.y + sin(b) * cell * 0.28)
            ),
            with: .color(k % 2 == 0 ? twigDark : twig.lightened(1.12)),
            style: stroke(cell * 0.045, cap: .round)
        )
    }
}

/// A ring of coral branches.
nonisolated func drawCoralRingPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let coral = Color(hex: 0xFF7F6B)
    let coralDeep = Color(hex: 0xD1503F)
    let bloom = Color(hex: 0xFFC2B0)
    ctx.stroke(circle(CGPoint(x: c.x, y: c.y + cell * 0.035), cell * 0.36), with: .color(coralDeep), style: stroke(cell * 0.15))
    ctx.stroke(circle(c, cell * 0.36), with: .color(coral), style: stroke(cell * 0.15))
    // Branches budding off the ring.
    for k in 0..<8 {
        let a = (CGFloat(k) * 45 + 20) * .pi / 180
        let dir = CGPoint(x: cos(a), y: sin(a))
        let from = CGPoint(x: c.x + dir.x * cell * 0.40, y: c.y + dir.y * cell * 0.40)
        let to = CGPoint(x: c.x + dir.x * cell * 0.49, y: c.y + dir.y * cell * 0.49)
        ctx.stroke(line(from, to), with: .color(coral), style: stroke(cell * 0.055, cap: .round))
        ctx.fill(circle(to, cell * 0.035), with: .color(bloom))
    }
    // Inner pool of water reads through the ring; a couple of polyps on the rim.
    for k in 0..<4 {
        let a = (CGFloat(k) * 90 + 55) * .pi / 180
        ctx.fill(
            circle(CGPoint(x: c.x + cos(a) * cell * 0.34, y: c.y + sin(a) * cell * 0.34), cell * 0.045),
            with: .color(bloom.opacity(0.9))
        )
    }
}

/// A soap bubble holding its shape just long enough to stand on.
nonisolated func drawBubblePad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let film = Color(hex: 0xBFE9F7)
    // Iridescent film: three offset rings rather than a gradient, so it stays
    // crisp at one cell wide.
    ctx.fill(circle(c, cell * 0.42), with: .color(film.opacity(0.30)))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.03, y: c.y + cell * 0.03), cell * 0.38), with: .color(Color(hex: 0xCDB6F0).opacity(0.35)))
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.03, y: c.y + cell * 0.02), cell * 0.34), with: .color(Color(hex: 0xB6F0DC).opacity(0.35)))
    ctx.stroke(circle(c, cell * 0.42), with: .color(Color(hex: 0xEAF9FF).opacity(0.55)), style: stroke(cell * 0.045))
    ctx.stroke(circle(c, cell * 0.42), with: .color(Color.white.opacity(0.8)), style: stroke(cell * 0.016))
    // Two highlights, the classic bubble read.
    ctx.fill(
        oval(CGPoint(x: c.x - cell * 0.26, y: c.y - cell * 0.28), CGSize(width: cell * 0.16, height: cell * 0.10)),
        with: .color(Color.white.opacity(0.85))
    )
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.16), cell * 0.035), with: .color(Color.white.opacity(0.6)))
    // Smaller bubbles clinging to it.
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.33, y: c.y + cell * 0.24), cell * 0.08), with: .color(Color(hex: 0xEAF9FF).opacity(0.6)))
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.34, y: c.y + cell * 0.26), cell * 0.05), with: .color(Color(hex: 0xEAF9FF).opacity(0.5)))
}

/// Premium: a little sun on the water.
nonisolated func drawSunburstPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let gold = Color(hex: 0xFFC53D)
    let deep = Color(hex: 0xE08A12)
    let hot = Color(hex: 0xFFF0BC)
    ctx.fill(circle(c, cell * 0.49), with: .color(gold.opacity(0.22)))
    // Long and short rays alternating.
    for k in 0..<16 {
        let a = CGFloat(k) * 22.5 * .pi / 180
        let dir = CGPoint(x: cos(a), y: sin(a))
        let len: CGFloat = k % 2 == 0 ? 0.48 : 0.40
        ctx.fill(
            polygon([
                CGPoint(x: c.x + dir.x * cell * len, y: c.y + dir.y * cell * len),
                CGPoint(x: c.x + dir.x * cell * 0.26 - dir.y * cell * 0.06,
                        y: c.y + dir.y * cell * 0.26 + dir.x * cell * 0.06),
                CGPoint(x: c.x + dir.x * cell * 0.26 + dir.y * cell * 0.06,
                        y: c.y + dir.y * cell * 0.26 - dir.x * cell * 0.06),
            ]),
            with: .color(k % 2 == 0 ? gold : deep)
        )
    }
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.03), cell * 0.30), with: .color(deep))
    ctx.fill(circle(c, cell * 0.30), with: .color(gold))
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.03, y: c.y - cell * 0.03), cell * 0.18), with: .color(hot))
    // A single cut-out glint so the disc does not read as flat paint.
    let glint = circle(c, cell * 0.22)
        .subtracting(circle(CGPoint(x: c.x + cell * 0.06, y: c.y - cell * 0.06), cell * 0.22))
    ctx.fill(glint, with: .color(Color.white.opacity(0.45)))
}
