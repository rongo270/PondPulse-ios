//
//  PondArtMore.swift
//  PondPulse
//
//  The pond's second shelf: fourteen more decorations, four more skies, and -
//  new here - the water itself and the bank around it. A 1:1 port of the
//  Android ui/PondArtMore.kt.
//
//  PondArt.swift falls through to this file rather than growing a thirty-arm
//  switch. Everything obeys the same rule as the first shelf: drawn from the
//  equipped theme's palette, never from fixed colours, so a thing bought on the
//  dusk pond still belongs on the sakura one. The exceptions are the things
//  that are only themselves if they keep their colour - fire, gold, a rainbow -
//  and each says so where it is drawn.
//

import SwiftUI

// MARK: - Decorations

/// The second shelf of decorations. See `drawDecor` for the first.
nonisolated func drawDecorMore(
    _ ctx: inout GraphicsContext, _ id: String, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat
) {
    switch id {
    case "cattails": drawCattails(&ctx, rect, palette, phase)
    case "koi": drawKoiShoal(&ctx, rect, palette, phase)
    case "swans": drawSwanPair(&ctx, rect, palette, phase)
    case "fountain": drawFountain(&ctx, rect, palette, phase)
    case "canoe": drawCanoe(&ctx, rect, palette, phase)
    case "waterwheel": drawWaterWheel(&ctx, rect, palette, phase)
    case "hammock": drawHammock(&ctx, rect, palette, phase)
    case "picnic": drawPicnic(&ctx, rect, palette)
    case "firepit": drawFirePit(&ctx, rect, palette, phase)
    case "gnome": drawGnome(&ctx, rect, palette)
    case "mailbox": drawMailbox(&ctx, rect, palette)
    case "swing": drawTreeSwing(&ctx, rect, palette, phase)
    case "arch": drawFlowerArch(&ctx, rect, palette)
    case "pier": drawPier(&ctx, rect, palette)
    default: break
    }
}

/// Bulrushes: three tall stems with brown heads, leaning in the breeze.
nonisolated private func drawCattails(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let w = rect.width, h = rect.height
    let baseY = rect.maxY
    let stems: [(CGFloat, CGFloat)] = [(-0.24, 0.92), (0.02, 1.0), (0.26, 0.78)]
    for (i, stem) in stems.enumerated() {
        let sway = sin(phase * 1.1 + CGFloat(i) * 1.7) * w * 0.05
        let foot = CGPoint(x: rect.midX + w * stem.0, y: baseY)
        let head = CGPoint(x: foot.x + sway, y: baseY - h * stem.1)
        ctx.stroke(line(foot, head), with: .color(palette.padDark), style: stroke(w * 0.028))
        // A blade peeling off each stem, so it is not three straight lines.
        let side: CGFloat = i % 2 == 0 ? 1 : -1
        var blade = Path()
        blade.move(to: CGPoint(x: foot.x, y: foot.y - h * 0.08))
        blade.addQuadCurve(
            to: CGPoint(x: head.x + w * 0.05 * side, y: head.y + h * 0.30),
            control: CGPoint(x: foot.x + w * 0.22 * side, y: foot.y - h * 0.42)
        )
        blade.addQuadCurve(
            to: CGPoint(x: foot.x, y: foot.y - h * 0.08),
            control: CGPoint(x: foot.x + w * 0.10 * side, y: foot.y - h * 0.40)
        )
        blade.closeSubpath()
        ctx.fill(blade, with: .color(palette.pad.opacity(0.85)))
        // The head: brown whatever the theme, because a green cattail is a reed.
        let headColour = Color(hex: 0x6B4426).blended(palette.rockDark, 0.25)
        ctx.fill(
            Path(roundedRect: CGRect(x: head.x - w * 0.035, y: head.y, width: w * 0.07, height: h * 0.20),
                 cornerRadius: w * 0.035),
            with: .color(headColour)
        )
        ctx.stroke(
            line(head, CGPoint(x: head.x, y: head.y - h * 0.10)),
            with: .color(palette.padDark), style: stroke(w * 0.018)
        )
    }
}

/// Three koi cruising just under the surface, seen from above.
nonisolated private func drawKoiShoal(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    // Koi are orange-and-white; tinted toward the palette so they still belong,
    // but never all the way, or a blue pond gets blue koi and they read as
    // shadows rather than as fish.
    let body = Color(hex: 0xF07A2E).blended(palette.duck, 0.25)
    let pale = Color(hex: 0xFDEFE2).blended(palette.ripple, 0.25)
    let fish: [(CGFloat, CGFloat, CGFloat)] = [(0.28, 0.34, 0.9), (0.62, 0.52, 1.15), (0.40, 0.74, 0.75)]
    for (i, f) in fish.enumerated() {
        let drift = sin(phase * 0.5 + CGFloat(i) * 2.1) * rect.width * 0.06
        let cx = rect.minX + rect.width * f.0 + drift
        let cy = rect.minY + rect.height * f.1
        let len = rect.width * 0.30 * f.2
        let wide = len * 0.42
        var c = rotated(ctx, degrees: sin(phase * 0.8 + CGFloat(i)) * 14, pivot: CGPoint(x: cx, y: cy))
        // Tail first, so the body overlaps it.
        c.fill(
            polygon([
                CGPoint(x: cx - len * 0.42, y: cy),
                CGPoint(x: cx - len * 0.72, y: cy - wide * 0.55),
                CGPoint(x: cx - len * 0.62, y: cy),
                CGPoint(x: cx - len * 0.72, y: cy + wide * 0.55),
            ]),
            with: .color(body.opacity(0.85))
        )
        c.fill(oval(CGPoint(x: cx - len * 0.5, y: cy - wide * 0.5), CGSize(width: len, height: wide)), with: .color(body))
        c.fill(
            oval(CGPoint(x: cx - len * 0.20, y: cy - wide * 0.34), CGSize(width: len * 0.34, height: wide * 0.5)),
            with: .color(pale.opacity(0.9))
        )
        // The water closing over it.
        ctx.stroke(
            circle(CGPoint(x: cx, y: cy), len * 0.62),
            with: .color(palette.ripple.opacity(0.10)), style: stroke(rect.width * 0.006)
        )
    }
}

/// Two swans facing each other, necks curved into the half of a heart each.
nonisolated private func drawSwanPair(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let white = Color.white.blended(palette.ripple, 0.18)
    let shade = white.blended(palette.waterDeep, 0.22)
    for side in [-1.0, 1.0] as [CGFloat] {
        let cx = rect.midX + rect.width * 0.19 * side
        let cy = rect.midY + rect.height * 0.16 + sin(phase * 0.9 + side) * rect.height * 0.012
        let bodyW = rect.width * 0.34
        let bodyH = rect.height * 0.24
        ctx.fill(oval(CGPoint(x: cx - bodyW * 0.5, y: cy - bodyH * 0.36), CGSize(width: bodyW, height: bodyH)), with: .color(shade))
        ctx.fill(oval(CGPoint(x: cx - bodyW * 0.5, y: cy - bodyH * 0.5), CGSize(width: bodyW, height: bodyH * 0.9)), with: .color(white))
        // The neck: an S from the shoulder up and in toward the other swan.
        let neckBase = CGPoint(x: cx - bodyW * 0.22 * side, y: cy - bodyH * 0.34)
        let headAt = CGPoint(x: cx + bodyW * 0.34 * side, y: cy - rect.height * 0.30)
        var neck = Path()
        neck.move(to: neckBase)
        neck.addCurve(
            to: headAt,
            control1: CGPoint(x: neckBase.x - bodyW * 0.34 * side, y: neckBase.y - rect.height * 0.16),
            control2: CGPoint(x: headAt.x - bodyW * 0.22 * side, y: headAt.y - rect.height * 0.02)
        )
        ctx.stroke(neck, with: .color(white), style: stroke(rect.width * 0.052))
        ctx.fill(circle(headAt, rect.width * 0.042), with: .color(white))
        // Beak and mask, orange and black, which is what makes it a swan.
        ctx.fill(
            polygon([
                CGPoint(x: headAt.x + rect.width * 0.03 * side, y: headAt.y),
                CGPoint(x: headAt.x + rect.width * 0.11 * side, y: headAt.y + rect.height * 0.016),
                CGPoint(x: headAt.x + rect.width * 0.03 * side, y: headAt.y + rect.height * 0.030),
            ]),
            with: .color(palette.beak)
        )
        ctx.fill(
            circle(CGPoint(x: headAt.x + rect.width * 0.012 * side, y: headAt.y - rect.height * 0.008), rect.width * 0.013),
            with: .color(palette.rockDark)
        )
    }
}

/// A tiered stone fountain, with water arcing out of the top bowl.
nonisolated private func drawFountain(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let stone = palette.rock, dark = palette.rockDark
    let cx = rect.midX
    let baseY = rect.maxY - rect.height * 0.06
    let w = rect.width, h = rect.height

    ctx.fill(oval(CGPoint(x: cx - w * 0.44, y: baseY - h * 0.13), CGSize(width: w * 0.88, height: h * 0.20)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: cx - w * 0.42, y: baseY - h * 0.16), CGSize(width: w * 0.84, height: h * 0.18)), with: .color(stone))
    // The pool inside the lower bowl.
    ctx.fill(oval(CGPoint(x: cx - w * 0.33, y: baseY - h * 0.145), CGSize(width: w * 0.66, height: h * 0.10)), with: .color(palette.waterDeep))
    // Column, then the upper bowl.
    ctx.fill(Path(CGRect(x: cx - w * 0.07, y: baseY - h * 0.44, width: w * 0.14, height: h * 0.30)), with: .color(stone))
    ctx.fill(oval(CGPoint(x: cx - w * 0.26, y: baseY - h * 0.50), CGSize(width: w * 0.52, height: h * 0.13)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: cx - w * 0.24, y: baseY - h * 0.52), CGSize(width: w * 0.48, height: h * 0.12)), with: .color(stone))
    // Four jets, each a parabola from the rim of the top bowl to the pool.
    for i in 0..<4 {
        let side: CGFloat = i % 2 == 0 ? -1 : 1
        let reach = w * (0.20 + 0.06 * CGFloat(i / 2))
        let lift = h * (0.10 + 0.03 * CGFloat(i / 2)) * (0.85 + 0.15 * sin(phase * 2.2 + CGFloat(i)))
        let from = CGPoint(x: cx + w * 0.04 * side, y: baseY - h * 0.52)
        var jet = Path()
        jet.move(to: from)
        jet.addQuadCurve(
            to: CGPoint(x: from.x + reach * 1.5 * side, y: baseY - h * 0.14),
            control: CGPoint(x: from.x + reach * side, y: from.y - lift)
        )
        ctx.stroke(jet, with: .color(palette.ripple.opacity(0.55)), style: stroke(w * 0.016))
    }
    ctx.fill(circle(CGPoint(x: cx, y: baseY - h * 0.55), w * 0.035), with: .color(palette.ripple.opacity(0.5)))
}

/// A birch canoe with a paddle laid across it.
nonisolated private func drawCanoe(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let bob = sin(phase * 1.1) * rect.height * 0.012
    let cy = rect.midY + bob
    let hull = Color(hex: 0xC8A278).blended(palette.rock, 0.3)
    let trim = Color(hex: 0x7A5231).blended(palette.rockDark, 0.3)
    let w = rect.width * 0.92
    let h = rect.height * 0.30

    func canoePath(_ inset: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX - w * 0.5 * (1 - inset), y: cy))
        p.addQuadCurve(
            to: CGPoint(x: rect.midX + w * 0.5 * (1 - inset), y: cy),
            control: CGPoint(x: rect.midX, y: cy + h * (1 - inset))
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.midX - w * 0.5 * (1 - inset), y: cy),
            control: CGPoint(x: rect.midX, y: cy - h * 0.42 * (1 - inset))
        )
        p.closeSubpath()
        return p
    }
    ctx.fill(canoePath(0), with: .color(trim))
    ctx.fill(canoePath(0.10), with: .color(hull))
    // The dark opening, and two thwarts across it.
    ctx.fill(canoePath(0.22), with: .color(trim.blended(.black, 0.35)))
    for dx in [-0.22, 0.22] as [CGFloat] {
        ctx.stroke(
            line(CGPoint(x: rect.midX + w * dx, y: cy - h * 0.16), CGPoint(x: rect.midX + w * dx, y: cy + h * 0.34)),
            with: .color(hull), style: stroke(rect.width * 0.024)
        )
    }
    // The paddle, resting across the gunwales at an angle.
    var c = rotated(ctx, degrees: -24, pivot: CGPoint(x: rect.midX, y: cy))
    c.stroke(
        line(CGPoint(x: rect.midX - w * 0.30, y: cy - h * 0.10), CGPoint(x: rect.midX + w * 0.26, y: cy - h * 0.10)),
        with: .color(trim), style: stroke(rect.width * 0.020)
    )
    c.fill(oval(CGPoint(x: rect.midX + w * 0.22, y: cy - h * 0.26), CGSize(width: w * 0.16, height: h * 0.32)), with: .color(hull))
}

/// A mill wheel on a stone footing, turning slowly and dripping.
nonisolated private func drawWaterWheel(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let wood = Color(hex: 0x8B5E34).blended(palette.rockDark, 0.28)
    let woodLit = wood.blended(palette.rock, 0.4)
    let centre = CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.04)
    let r = rect.width * 0.40
    let spin = phase * 0.55

    // The footing it turns against.
    ctx.fill(
        Path(CGRect(x: rect.midX - rect.width * 0.10, y: centre.y, width: rect.width * 0.20, height: rect.height * 0.50)),
        with: .color(palette.rockDark)
    )
    ctx.stroke(circle(centre, r), with: .color(woodLit), style: stroke(rect.width * 0.05))
    ctx.stroke(circle(centre, r * 0.30), with: .color(woodLit), style: stroke(rect.width * 0.035))

    for i in 0..<8 {
        let a = spin + CGFloat(i) * (2 * .pi / 8)
        let inner = CGPoint(x: centre.x + cos(a) * r * 0.30, y: centre.y + sin(a) * r * 0.30)
        let outer = CGPoint(x: centre.x + cos(a) * r, y: centre.y + sin(a) * r)
        ctx.stroke(line(inner, outer), with: .color(wood), style: stroke(rect.width * 0.026))
        // The paddle on the end of each spoke.
        let across = CGPoint(x: -sin(a), y: cos(a))
        ctx.stroke(
            line(
                CGPoint(x: outer.x - across.x * r * 0.20, y: outer.y - across.y * r * 0.20),
                CGPoint(x: outer.x + across.x * r * 0.20, y: outer.y + across.y * r * 0.20)
            ),
            with: .color(woodLit), style: stroke(rect.width * 0.045)
        )
        // Water falling off whichever paddle has just come over the top.
        if sin(a) < -0.6 {
            ctx.stroke(
                line(outer, CGPoint(x: outer.x, y: outer.y + rect.height * 0.16)),
                with: .color(palette.ripple.opacity(0.5)), style: stroke(rect.width * 0.012)
            )
        }
    }
    ctx.fill(circle(centre, rect.width * 0.05), with: .color(palette.rockDark))
}

/// A hammock slung between two posts, dipping under nobody at all.
nonisolated private func drawHammock(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let post = Color(hex: 0x7A5231).blended(palette.rockDark, 0.3)
    let cloth = palette.accent.blended(.white, 0.30)
    let left = CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY - rect.height * 0.06)
    let right = CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.maxY - rect.height * 0.06)
    let top = rect.minY + rect.height * 0.26

    for foot in [left, right] {
        ctx.stroke(line(foot, CGPoint(x: foot.x, y: top)), with: .color(post), style: stroke(rect.width * 0.045))
        ctx.fill(
            oval(CGPoint(x: foot.x - rect.width * 0.08, y: foot.y - rect.height * 0.03),
                 CGSize(width: rect.width * 0.16, height: rect.height * 0.06)),
            with: .color(palette.padDark.opacity(0.5))
        )
    }
    let sag = rect.height * (0.34 + sin(phase * 0.8) * 0.02)
    var hang = Path()
    hang.move(to: CGPoint(x: left.x, y: top + rect.height * 0.04))
    hang.addQuadCurve(to: CGPoint(x: right.x, y: top + rect.height * 0.04), control: CGPoint(x: rect.midX, y: top + sag * 1.9))
    hang.addQuadCurve(to: CGPoint(x: left.x, y: top + rect.height * 0.04), control: CGPoint(x: rect.midX, y: top + sag * 1.35))
    hang.closeSubpath()
    ctx.fill(hang, with: .color(cloth))
    // Stripes along the weave, following the same curve.
    for i in 1..<5 {
        let t = CGFloat(i) / 5
        var s = Path()
        s.move(to: CGPoint(x: left.x, y: top + rect.height * 0.04))
        s.addQuadCurve(to: CGPoint(x: right.x, y: top + rect.height * 0.04), control: CGPoint(x: rect.midX, y: top + sag * (1.35 + 0.55 * t)))
        ctx.stroke(s, with: .color(palette.beak.opacity(0.5)), style: stroke(rect.width * 0.010))
    }
}

/// A checked blanket with a basket and two apples on it.
nonisolated private func drawPicnic(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let cloth = Color(hex: 0xE8564F).blended(palette.accent, 0.20)
    let pale = Color.white.blended(palette.ripple, 0.2)
    let b = CGRect(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.40,
                   width: rect.width * 0.92, height: rect.height * 0.46)
    // Drawn as a squashed diamond so it reads as lying flat on the ground.
    ctx.fill(
        polygon([
            CGPoint(x: b.minX + b.width * 0.14, y: b.minY),
            CGPoint(x: b.maxX, y: b.minY + b.height * 0.30),
            CGPoint(x: b.maxX - b.width * 0.14, y: b.maxY),
            CGPoint(x: b.minX, y: b.maxY - b.height * 0.30),
        ]),
        with: .color(cloth)
    )
    for i in 1..<4 {
        let t = CGFloat(i) / 4
        ctx.stroke(
            line(CGPoint(x: b.minX + b.width * (0.14 + 0.86 * t), y: b.minY + b.height * 0.30 * t),
                 CGPoint(x: b.minX + b.width * (0.86 * t), y: b.maxY - b.height * 0.30 * (1 - t))),
            with: .color(pale.opacity(0.65)), style: stroke(rect.width * 0.012)
        )
        ctx.stroke(
            line(CGPoint(x: b.minX + b.width * 0.14 * (1 - t), y: b.minY + b.height * t * 0.7),
                 CGPoint(x: b.maxX - b.width * 0.14 * t, y: b.minY + b.height * (0.30 + 0.7 * t))),
            with: .color(pale.opacity(0.65)), style: stroke(rect.width * 0.012)
        )
    }
    // The basket.
    let wicker = Color(hex: 0xC58E4A).blended(palette.rock, 0.25)
    let bx = rect.minX + rect.width * 0.30
    let by = rect.minY + rect.height * 0.44
    ctx.fill(
        Path(roundedRect: CGRect(x: bx, y: by, width: rect.width * 0.26, height: rect.height * 0.20), cornerRadius: rect.width * 0.03),
        with: .color(wicker)
    )
    ctx.stroke(
        ovalArc(CGPoint(x: bx + rect.width * 0.04, y: by - rect.height * 0.10),
                CGSize(width: rect.width * 0.18, height: rect.height * 0.20), start: 180, sweep: 180, useCenter: false),
        with: .color(wicker.blended(palette.rockDark, 0.4)), style: stroke(rect.width * 0.018)
    )
    // Two apples. Red because a green apple on grass is not an apple.
    for dx in [0.66, 0.76] as [CGFloat] {
        ctx.fill(
            circle(CGPoint(x: rect.minX + rect.width * dx, y: rect.minY + rect.height * 0.66), rect.width * 0.045),
            with: .color(Color(hex: 0xD8453C).blended(palette.danger, 0.3))
        )
    }
}

/// A ring of stones round a fire, with the flame licking up out of it.
nonisolated private func drawFirePit(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let cx = rect.midX
    let cy = rect.midY + rect.height * 0.16
    let rx = rect.width * 0.42
    let ry = rect.height * 0.20

    ctx.fill(
        oval(CGPoint(x: cx - rx * 0.78, y: cy - ry * 0.6), CGSize(width: rx * 1.56, height: ry * 1.2)),
        with: .color(palette.rockDark.blended(.black, 0.35))
    )
    // Logs, criss-crossed, before the stones so the ring sits in front.
    let log = Color(hex: 0x7A5231).blended(palette.rockDark, 0.25)
    for a in [-24.0, 22.0] as [CGFloat] {
        var c = rotated(ctx, degrees: a, pivot: CGPoint(x: cx, y: cy))
        c.fill(
            Path(roundedRect: CGRect(x: cx - rx * 0.62, y: cy - ry * 0.16, width: rx * 1.24, height: ry * 0.32),
                 cornerRadius: ry * 0.16),
            with: .color(log)
        )
    }
    // The flame keeps its own colours: a palette-tinted fire is not a fire.
    let lick = 0.85 + 0.15 * sin(phase * 3.4)
    let hues = [Color(hex: 0xFF6B2C), Color(hex: 0xFFA733), Color(hex: 0xFFE082)]
    for i in 0..<3 {
        let hgt = rect.height * (0.34 + 0.10 * CGFloat(i)) * lick
        let wid = rect.width * (0.26 - 0.06 * CGFloat(i))
        var f = Path()
        f.move(to: CGPoint(x: cx - wid * 0.5, y: cy - ry * 0.1))
        f.addQuadCurve(to: CGPoint(x: cx + sin(phase * 2.1 + CGFloat(i)) * wid * 0.16, y: cy - hgt),
                       control: CGPoint(x: cx - wid * 0.62, y: cy - hgt * 0.55))
        f.addQuadCurve(to: CGPoint(x: cx + wid * 0.5, y: cy - ry * 0.1),
                       control: CGPoint(x: cx + wid * 0.62, y: cy - hgt * 0.55))
        f.closeSubpath()
        ctx.fill(f, with: .color(hues[i].opacity(0.92)))
    }
    // The stone ring, drawn last so the fire sits inside it.
    for i in 0..<9 {
        let a = CGFloat(i) * (2 * .pi / 9)
        ctx.fill(
            circle(CGPoint(x: cx + cos(a) * rx, y: cy + sin(a) * ry), rect.width * 0.075),
            with: .color(i % 2 == 0 ? palette.rock : palette.rockDark)
        )
    }
    ctx.fill(circle(CGPoint(x: cx, y: cy), rect.width * 0.55), with: .color(Color(hex: 0xFF8A3D).opacity(0.18)))
}

/// A garden gnome: red hat, white beard, arms folded.
nonisolated private func drawGnome(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let cx = rect.midX
    let bottom = rect.maxY - rect.height * 0.08
    let w = rect.width, h = rect.height
    let coat = Color(hex: 0x3B7BC8).blended(palette.waterRim, 0.25)
    let hat = Color(hex: 0xD8453C).blended(palette.danger, 0.25)
    let beard = Color.white.blended(palette.ripple, 0.15)
    let skin = Color(hex: 0xF2C6A0).blended(palette.duck, 0.12)

    var body = Path()
    body.move(to: CGPoint(x: cx - w * 0.26, y: bottom))
    body.addQuadCurve(to: CGPoint(x: cx, y: bottom - h * 0.40), control: CGPoint(x: cx - w * 0.22, y: bottom - h * 0.34))
    body.addQuadCurve(to: CGPoint(x: cx + w * 0.26, y: bottom), control: CGPoint(x: cx + w * 0.22, y: bottom - h * 0.34))
    body.closeSubpath()
    ctx.fill(body, with: .color(coat))
    ctx.fill(circle(CGPoint(x: cx, y: bottom - h * 0.46), w * 0.15), with: .color(skin))
    var bd = Path()
    bd.move(to: CGPoint(x: cx - w * 0.17, y: bottom - h * 0.44))
    bd.addQuadCurve(to: CGPoint(x: cx + w * 0.17, y: bottom - h * 0.44), control: CGPoint(x: cx, y: bottom - h * 0.12))
    bd.closeSubpath()
    ctx.fill(bd, with: .color(beard))
    ctx.fill(
        polygon([
            CGPoint(x: cx - w * 0.24, y: bottom - h * 0.50),
            CGPoint(x: cx, y: bottom - h * 0.96),
            CGPoint(x: cx + w * 0.24, y: bottom - h * 0.50),
        ]),
        with: .color(hat)
    )
    for dx in [-0.06, 0.06] as [CGFloat] {
        ctx.fill(circle(CGPoint(x: cx + w * dx, y: bottom - h * 0.50), w * 0.020), with: .color(palette.rockDark))
    }
    ctx.fill(circle(CGPoint(x: cx, y: bottom - h * 0.455), w * 0.038), with: .color(skin.blended(palette.beak, 0.35)))
}

/// A post box on a leaning post, flag up.
nonisolated private func drawMailbox(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let post = Color(hex: 0x7A5231).blended(palette.rockDark, 0.3)
    let box = palette.waterRim.blended(palette.rock, 0.35)
    let cx = rect.midX
    let bottom = rect.maxY - rect.height * 0.06
    let w = rect.width, h = rect.height

    ctx.stroke(
        line(CGPoint(x: cx, y: bottom), CGPoint(x: cx + w * 0.03, y: bottom - h * 0.52)),
        with: .color(post), style: stroke(w * 0.09)
    )
    let bx = cx - w * 0.30
    let by = bottom - h * 0.82
    let bw = w * 0.66
    let bh = h * 0.30
    ctx.fill(Path(CGRect(x: bx, y: by + bh * 0.42, width: bw, height: bh * 0.58)), with: .color(box))
    ctx.fill(ovalArc(CGPoint(x: bx, y: by), CGSize(width: bw, height: bh * 0.84), start: 180, sweep: 180, useCenter: true), with: .color(box))
    ctx.fill(
        Path(CGRect(x: bx + bw * 0.86, y: by + bh * 0.20, width: bw * 0.10, height: bh * 0.72)),
        with: .color(box.blended(.black, 0.30))
    )
    // The little flag, up, which is the whole joke of a mailbox.
    let red = Color(hex: 0xD8453C).blended(palette.danger, 0.25)
    ctx.stroke(
        line(CGPoint(x: bx + bw * 0.06, y: by + bh * 0.60), CGPoint(x: bx + bw * 0.06, y: by - bh * 0.30)),
        with: .color(red), style: stroke(w * 0.035)
    )
    ctx.fill(Path(CGRect(x: bx + bw * 0.06, y: by - bh * 0.30, width: bw * 0.22, height: bh * 0.24)), with: .color(red))
}

/// A plank swing on two ropes, hung from a bough that leaves the frame.
nonisolated private func drawTreeSwing(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let bough = Color(hex: 0x6B4426).blended(palette.rockDark, 0.3)
    let rope = Color(hex: 0xC9B189).blended(palette.rock, 0.3)
    let plank = Color(hex: 0x8B5E34).blended(palette.rockDark, 0.2)
    let w = rect.width, h = rect.height

    var b = Path()
    b.move(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.22))
    b.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.16), control: CGPoint(x: rect.midX, y: rect.minY + h * 0.06))
    ctx.stroke(b, with: .color(bough), style: stroke(w * 0.07))
    // Leaves along the bough, so it is a tree and not a beam.
    for i in 0..<7 {
        let t = CGFloat(i) / 6
        let lx = rect.minX + w * t
        let ly = rect.minY + h * (0.22 - 0.16 * (1 - (2 * t - 1) * (2 * t - 1)))
        ctx.fill(
            oval(CGPoint(x: lx - w * 0.06, y: ly - h * 0.09), CGSize(width: w * 0.12, height: h * 0.07)),
            with: .color(palette.pad.opacity(0.9))
        )
    }
    var c = rotated(ctx, degrees: sin(phase * 1.2) * 9, pivot: CGPoint(x: rect.midX, y: rect.minY + h * 0.12))
    let seatY = rect.minY + h * 0.74
    for dx in [-0.17, 0.17] as [CGFloat] {
        c.stroke(
            line(CGPoint(x: rect.midX + w * dx, y: rect.minY + h * 0.12), CGPoint(x: rect.midX + w * dx, y: seatY)),
            with: .color(rope), style: stroke(w * 0.018)
        )
    }
    c.fill(
        Path(roundedRect: CGRect(x: rect.midX - w * 0.24, y: seatY, width: w * 0.48, height: h * 0.075), cornerRadius: w * 0.02),
        with: .color(plank)
    )
}

/// A rose arch: two uprights, a curved top, flowers along it.
nonisolated private func drawFlowerArch(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let frame = Color(hex: 0xE9E2D2).blended(palette.rock, 0.35)
    let w = rect.width, h = rect.height
    let leftX = rect.minX + w * 0.20
    let rightX = rect.maxX - w * 0.20
    let bottom = rect.maxY - h * 0.05
    let springY = rect.minY + h * 0.34

    var arch = Path()
    arch.move(to: CGPoint(x: leftX, y: bottom))
    arch.addLine(to: CGPoint(x: leftX, y: springY))
    arch.addQuadCurve(to: CGPoint(x: rightX, y: springY), control: CGPoint(x: rect.midX, y: rect.minY + h * 0.02))
    arch.addLine(to: CGPoint(x: rightX, y: bottom))
    ctx.stroke(arch, with: .color(frame), style: stroke(w * 0.055))
    // Cross bars in the arch's head.
    for i in 1..<4 {
        let t = CGFloat(i) / 4
        let y = springY - h * 0.18 * (1 - (2 * t - 1) * (2 * t - 1))
        ctx.stroke(
            line(CGPoint(x: leftX + (rightX - leftX) * (t - 0.16), y: y),
                 CGPoint(x: leftX + (rightX - leftX) * (t + 0.16), y: y)),
            with: .color(frame.opacity(0.8)), style: stroke(w * 0.016)
        )
    }
    // Climbing roses. Two tones so the arch has depth rather than dots.
    for i in 0..<14 {
        let t = CGFloat(i) / 13
        let onArch = t < 0.34 || t > 0.66
        var x: CGFloat, y: CGFloat
        if t < 0.34 {
            x = leftX; y = bottom - (bottom - springY) * (t / 0.34)
        } else if t > 0.66 {
            x = rightX; y = springY + (bottom - springY) * ((t - 0.66) / 0.34)
        } else {
            let u = (t - 0.34) / 0.32
            x = leftX + (rightX - leftX) * u
            y = springY - h * 0.32 * (1 - (2 * u - 1) * (2 * u - 1))
        }
        let jitter: CGFloat = i % 2 == 0 ? w * 0.045 : -w * 0.045
        ctx.fill(circle(CGPoint(x: x + jitter * 0.6, y: y + jitter * 0.4), w * 0.035), with: .color(palette.pad))
        let bloom = i % 3 == 0 ? palette.accent.blended(.white, 0.4) : Color(hex: 0xE05A82).blended(palette.accent, 0.25)
        ctx.fill(circle(CGPoint(x: x + jitter, y: y), w * (onArch ? 0.030 : 0.036)), with: .color(bloom))
    }
}

/// A plank jetty on piles, running out over the shoreline.
nonisolated private func drawPier(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let plank = Color(hex: 0xB08856).blended(palette.rock, 0.28)
    let dark = Color(hex: 0x6B4426).blended(palette.rockDark, 0.30)
    let w = rect.width, h = rect.height
    let deckTop = rect.minY + h * 0.34
    let deckH = h * 0.20

    // Piles first, so the deck lands on top of them.
    for i in 0..<4 {
        let x = rect.minX + w * (0.14 + 0.24 * CGFloat(i))
        ctx.stroke(
            line(CGPoint(x: x, y: deckTop + deckH * 0.6), CGPoint(x: x, y: rect.maxY - h * 0.06)),
            with: .color(dark), style: stroke(w * 0.045)
        )
    }
    ctx.fill(Path(CGRect(x: rect.minX, y: deckTop + deckH * 0.72, width: w, height: deckH * 0.22)), with: .color(dark))
    ctx.fill(Path(CGRect(x: rect.minX, y: deckTop, width: w, height: deckH * 0.80)), with: .color(plank))
    for i in 0..<8 {
        let x = rect.minX + w * (CGFloat(i) / 8)
        ctx.stroke(
            line(CGPoint(x: x, y: deckTop), CGPoint(x: x, y: deckTop + deckH * 0.80)),
            with: .color(dark.opacity(0.45)), style: stroke(w * 0.008)
        )
    }
    // A rail down one side, which is what makes it a pier and not a raft.
    for i in 0..<4 {
        let x = rect.minX + w * (0.14 + 0.24 * CGFloat(i))
        ctx.stroke(line(CGPoint(x: x, y: deckTop), CGPoint(x: x, y: deckTop - h * 0.20)), with: .color(dark), style: stroke(w * 0.028))
    }
    ctx.stroke(
        line(CGPoint(x: rect.minX + w * 0.10, y: deckTop - h * 0.18), CGPoint(x: rect.maxX - w * 0.10, y: deckTop - h * 0.18)),
        with: .color(plank), style: stroke(w * 0.026)
    )
}

// MARK: - Skies

/// The four newer skies. See `drawWeather` for the first six.
nonisolated func drawWeatherMore(
    _ ctx: inout GraphicsContext, _ id: String, _ size: CGSize, _ palette: PondPalette, _ time: CGFloat
) {
    let w = size.width, h = size.height
    let full = Path(CGRect(origin: .zero, size: size))
    switch id {
    case "aurora":
        ctx.fill(full, with: .linearGradient(
            Gradient(colors: [Color(hex: 0x041427).opacity(0.55), Color(hex: 0x07223A).opacity(0.34)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)
        ))
        // Three curtains, each a wide band whose height breathes on its own
        // clock, fading out downward instead of ending on a hard line.
        let hues = [Color(hex: 0x5BE7B6), Color(hex: 0x7BD1FF), Color(hex: 0xC08BFF)]
        for i in 0..<3 {
            let drift = sin(time * (0.13 + 0.04 * CGFloat(i)) + CGFloat(i) * 2.1)
            let cx = w * (0.30 + 0.20 * CGFloat(i)) + drift * w * 0.10
            let band = w * (0.30 + 0.06 * CGFloat(i))
            let top = h * (0.02 + 0.03 * CGFloat(i))
            let tall = h * (0.30 + 0.10 * sin(time * 0.5 + CGFloat(i)))
            var curtain = Path()
            curtain.move(to: CGPoint(x: cx - band * 0.5, y: top))
            curtain.addQuadCurve(to: CGPoint(x: cx - band * 0.22, y: top + tall), control: CGPoint(x: cx, y: top + tall * 0.4))
            curtain.addLine(to: CGPoint(x: cx + band * 0.30, y: top + tall))
            curtain.addQuadCurve(to: CGPoint(x: cx + band * 0.5, y: top), control: CGPoint(x: cx + band * 0.16, y: top + tall * 0.4))
            curtain.closeSubpath()
            ctx.fill(curtain, with: .linearGradient(
                Gradient(colors: [hues[i].opacity(0.34), hues[i].opacity(0.02)]),
                startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: top + tall)
            ))
        }
        for i in 0..<18 {
            let sx = (CGFloat(i) * 0.0917 * 7).truncatingRemainder(dividingBy: 1) * w
            let sy = (CGFloat(i) * 0.163).truncatingRemainder(dividingBy: 0.5) * h
            ctx.fill(circle(CGPoint(x: sx, y: sy), w * 0.0035), with: .color(Color.white.opacity(0.5)))
        }

    case "storm":
        ctx.fill(full, with: .linearGradient(
            Gradient(colors: [Color(hex: 0x1A2430).opacity(0.58), Color(hex: 0x2C3D4A).opacity(0.36)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)
        ))
        // Rain, harder and more slanted than the rain sky's.
        for i in 0..<64 {
            let fx = (CGFloat(i) * 0.0217 * 11).truncatingRemainder(dividingBy: 1)
            let fy = (CGFloat(i) * 0.137 + time * 1.9).truncatingRemainder(dividingBy: 1.1) - 0.05
            ctx.stroke(
                line(CGPoint(x: fx * w, y: fy * h), CGPoint(x: fx * w - w * 0.030, y: fy * h + h * 0.060)),
                with: .color(palette.ripple.opacity(0.42)), style: stroke(w * 0.004)
            )
        }
        // Lightning: a whole-screen flash on a slow, uneven cycle, with the
        // bolt drawn only during it. A bolt that is always there is wire.
        let beat = (time * 0.55).truncatingRemainder(dividingBy: 4)
        var flash: CGFloat = 0
        if beat < 0.10 { flash = 1 - beat / 0.10 }
        else if beat >= 0.22 && beat <= 0.34 { flash = 1 - (beat - 0.22) / 0.12 }
        if flash > 0 {
            ctx.fill(full, with: .color(Color.white.opacity(0.30 * flash)))
            var x = w * 0.62
            var y: CGFloat = 0
            var bolt = Path()
            bolt.move(to: CGPoint(x: x, y: y))
            for step in 0..<5 {
                x += w * (step % 2 == 0 ? -0.06 : 0.045)
                y += h * 0.11
                bolt.addLine(to: CGPoint(x: x, y: y))
            }
            ctx.stroke(bolt, with: .color(Color(hex: 0xFFF6C0).opacity(0.9 * flash)), style: stroke(w * 0.010))
        }

    case "rainbow":
        ctx.fill(full, with: .linearGradient(
            Gradient(colors: [Color(hex: 0xCFE9F5).opacity(0.20), Color(hex: 0xFFF2CF).opacity(0.10)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)
        ))
        // A rainbow keeps its own seven colours. There is no version of this
        // tinted to a palette that is still a rainbow.
        let arc: [Color] = [
            Color(hex: 0xE64A4A), Color(hex: 0xF08A2E), Color(hex: 0xF5D13B),
            Color(hex: 0x57BF6A), Color(hex: 0x3E8BE0), Color(hex: 0x5B54C4), Color(hex: 0x8E51C4),
        ]
        let cx = w * 0.5, cy = h * 0.86
        for (i, colour) in arc.enumerated() {
            let r = w * (0.72 - CGFloat(i) * 0.038)
            ctx.stroke(
                ovalArc(CGPoint(x: cx - r, y: cy - r), CGSize(width: r * 2, height: r * 2), start: 200, sweep: 140, useCenter: false),
                with: .color(colour.opacity(0.30)), style: stroke(w * 0.030)
            )
        }
        // A few drifting clouds, so the arc has weather to belong to.
        for i in 0..<3 {
            let drift = ((time * (0.014 + 0.006 * CGFloat(i))).truncatingRemainder(dividingBy: 1.5) - 0.25) * w
            let y = h * (0.10 + 0.09 * CGFloat(i))
            ctx.fill(oval(CGPoint(x: drift, y: y), CGSize(width: w * 0.42, height: h * 0.09)), with: .color(Color.white.opacity(0.24)))
        }

    case "starry":
        ctx.fill(full, with: .linearGradient(
            Gradient(colors: [Color(hex: 0x050B22).opacity(0.66), Color(hex: 0x0D1738).opacity(0.48)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)
        ))
        // A band of milky way across the top third.
        var band = Path()
        band.move(to: CGPoint(x: 0, y: h * 0.30))
        band.addQuadCurve(to: CGPoint(x: w, y: h * 0.22), control: CGPoint(x: w * 0.5, y: h * 0.02))
        band.addLine(to: CGPoint(x: w, y: h * 0.36))
        band.addQuadCurve(to: CGPoint(x: 0, y: h * 0.44), control: CGPoint(x: w * 0.5, y: h * 0.16))
        band.closeSubpath()
        ctx.fill(band, with: .color(Color(hex: 0x9BB6FF).opacity(0.13)))
        for i in 0..<54 {
            let sx = (CGFloat(i) * 0.0731 * 13).truncatingRemainder(dividingBy: 1) * w
            let sy = (CGFloat(i) * 0.191).truncatingRemainder(dividingBy: 0.72) * h
            let twinkle = (sin(time * (0.9 + CGFloat(i % 5) * 0.35) + CGFloat(i)) + 1) / 2
            ctx.fill(
                circle(CGPoint(x: sx, y: sy), w * (0.0022 + 0.0026 * CGFloat(i % 3) / 2) * (0.7 + twinkle * 0.5)),
                with: .color(Color.white.opacity(0.30 + twinkle * 0.55))
            )
        }
        // One shooting star, on a long enough cycle to be a surprise.
        let streak = (time * 0.16).truncatingRemainder(dividingBy: 1)
        if streak < 0.13 {
            let p = streak / 0.13
            let sx = w * (0.15 + p * 0.7)
            let sy = h * (0.08 + p * 0.30)
            ctx.stroke(
                line(CGPoint(x: sx, y: sy), CGPoint(x: sx - w * 0.11, y: sy - h * 0.05)),
                with: .color(Color.white.opacity((1 - p) * 0.8)), style: stroke(w * 0.004)
            )
        }

    default:
        break
    }
}

// MARK: - Water

/// The two ends of the water's gradient, before the sky tints it.
///
/// Each bought surface leans the theme's own water somewhere rather than
/// replacing it, so the sakura pond's emerald water is still recognisably the
/// sakura pond.
nonisolated func waterColours(_ waterId: String, _ palette: PondPalette) -> (Color, Color) {
    switch waterId {
    case "deep":
        return (palette.water.blended(Color(hex: 0x071E2C), 0.52), palette.waterDeep.blended(Color(hex: 0x03121C), 0.58))
    case "emerald":
        return (palette.water.blended(Color(hex: 0x1E7A5E), 0.48), palette.waterDeep.blended(Color(hex: 0x0E4C3A), 0.52))
    case "mirror":
        return (palette.water.blended(palette.ripple, 0.24), palette.waterDeep.blended(palette.waterRim, 0.28))
    case "sparkle":
        return (palette.water.blended(palette.ripple, 0.12), palette.waterDeep)
    case "reedy":
        return (palette.water.blended(palette.padDark, 0.22), palette.waterDeep.blended(palette.padDark, 0.30))
    default:
        return (palette.water, palette.waterDeep)
    }
}

/// Whatever the bought surface puts *on* the water, over the standing swell.
nonisolated func drawWaterDetail(
    _ ctx: inout GraphicsContext, _ waterId: String, _ size: CGSize, _ palette: PondPalette, _ time: CGFloat
) {
    let w = size.width, h = size.height
    switch waterId {
    case "reedy":
        // Weed fronds seen through the surface: soft, dark, slowly waving.
        for i in 0..<11 {
            let x = (CGFloat(i) * 0.0917 * 7).truncatingRemainder(dividingBy: 1) * w
            let y = h * (0.30 + (CGFloat(i) * 0.157).truncatingRemainder(dividingBy: 0.66))
            let sway = sin(time * 0.5 + CGFloat(i)) * w * 0.02
            var frond = Path()
            frond.move(to: CGPoint(x: x, y: y))
            frond.addQuadCurve(to: CGPoint(x: x + sway * 1.6, y: y - h * 0.20), control: CGPoint(x: x + sway, y: y - h * 0.10))
            ctx.stroke(frond, with: .color(palette.padDark.opacity(0.30)), style: stroke(w * 0.012))
        }

    case "emerald":
        // Algae: flat blotches, no outline, so it reads as pondweed rather
        // than as lily pads with the edges rubbed off.
        for i in 0..<9 {
            let x = (CGFloat(i) * 0.113 * 5).truncatingRemainder(dividingBy: 1) * w
            let y = h * (0.16 + (CGFloat(i) * 0.181).truncatingRemainder(dividingBy: 0.74))
            let r = w * (0.05 + 0.035 * (CGFloat(i % 3) / 2))
            ctx.fill(oval(CGPoint(x: x - r, y: y - r * 0.55), CGSize(width: r * 2, height: r * 1.1)), with: .color(palette.pad.opacity(0.16)))
        }

    case "sparkle":
        // Sun glints. Fixed positions, each blinking on its own clock: a glint
        // that moves is a firefly, and there is already a sky for that.
        for i in 0..<26 {
            let x = (CGFloat(i) * 0.0713 * 11).truncatingRemainder(dividingBy: 1) * w
            let y = h * (0.10 + (CGFloat(i) * 0.149).truncatingRemainder(dividingBy: 0.80))
            let blink = (sin(time * (1.6 + CGFloat(i % 4) * 0.4) + CGFloat(i) * 1.3) + 1) / 2
            if blink < 0.55 { continue }
            let a = (blink - 0.55) * 2.0
            let r = w * 0.013 * a
            ctx.stroke(line(CGPoint(x: x - r, y: y), CGPoint(x: x + r, y: y)), with: .color(Color.white.opacity(a * 0.8)), style: stroke(w * 0.004))
            ctx.stroke(line(CGPoint(x: x, y: y - r), CGPoint(x: x, y: y + r)), with: .color(Color.white.opacity(a * 0.8)), style: stroke(w * 0.004))
        }

    case "mirror":
        // Still water: broad, almost flat bands of sky reflected in it.
        for i in 0..<5 {
            let y = h * (0.16 + 0.17 * CGFloat(i)) + sin(time * 0.22 + CGFloat(i)) * h * 0.004
            ctx.fill(Path(CGRect(x: 0, y: y, width: w, height: h * 0.045)), with: .color(Color.white.opacity(0.055)))
        }

    case "deep":
        // Depth: a soft dark pool toward the middle, so the eye reads down
        // rather than across.
        ctx.fill(
            oval(CGPoint(x: w * 0.02, y: h * 0.14), CGSize(width: w * 0.96, height: h * 0.78)),
            with: .radialGradient(
                Gradient(colors: [Color.black.opacity(0.22), .clear]),
                center: CGPoint(x: w * 0.5, y: h * 0.55), startRadius: 0, endRadius: w * 0.55
            )
        )

    default:
        break
    }
}

// MARK: - Shores

/// The two tones a bank's ground is built from: light at the top and bottom of
/// the frame, dark through the middle.
///
/// One function rather than a pair of constants inside each drawing, because
/// the strip painted behind the notch and the home indicator has to be the
/// *same* colour the ground gradient starts and ends on - if it is a shade out,
/// the seam is a line across the grass.
nonisolated func shoreTones(_ shoreId: String, _ palette: PondPalette) -> (light: Color, dark: Color) {
    switch shoreId {
    case "sand":
        return (Color(hex: 0xF0DDB4).blended(palette.rock, 0.14),
                Color(hex: 0xDCC08C).blended(palette.rock, 0.18))
    case "pebbles":
        return (palette.rock.blended(Color(hex: 0xB8BFC4), 0.35),
                palette.rockDark.blended(Color(hex: 0x6E767C), 0.35))
    case "moss":
        return (palette.pad.blended(Color(hex: 0x4E7A3A), 0.45),
                palette.padDark.blended(Color(hex: 0x23401F), 0.45))
    case "snow":
        return (Color.white.blended(palette.ripple, 0.10),
                Color(hex: 0xD7E6F0).blended(palette.waterRim, 0.16))
    case "autumn":
        return (Color(hex: 0x8A6236).blended(palette.rockDark, 0.30),
                Color(hex: 0x5E4224).blended(palette.rockDark, 0.35))
    default:
        let grass = palette.padDark.blended(Color(hex: 0x2E4A22), 0.35)
        return (palette.pad.blended(grass, 0.45), grass)
    }
}

/// The bank the pond sits in.
///
/// Every one of them paints a ground gradient and then scatters something over
/// it, thickest at the water's edge - because the edge is where the eye goes,
/// and a bank that is a flat colour field everywhere except its outline reads
/// as a background rather than as ground.
nonisolated func drawShore(
    _ ctx: inout GraphicsContext, _ shoreId: String, _ size: CGSize, _ palette: PondPalette, _ time: CGFloat
) {
    switch shoreId {
    case "sand": drawSandShore(&ctx, size, palette)
    case "pebbles": drawPebbleShore(&ctx, size, palette)
    case "moss": drawMossShore(&ctx, size, palette, time)
    case "snow": drawSnowShore(&ctx, size, palette)
    case "autumn": drawAutumnShore(&ctx, size, palette, time)
    default: drawMeadowShore(&ctx, size, palette, time)
    }
}

/// The ground itself: a vertical gradient, lighter at the two edges of the
/// frame so the bank does not read as one flat slab.
nonisolated private func drawGround(_ ctx: inout GraphicsContext, _ size: CGSize, _ light: Color, _ dark: Color) {
    ctx.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .linearGradient(
            Gradient(stops: [
                .init(color: light, location: 0),
                .init(color: dark, location: 0.5),
                .init(color: light, location: 1),
            ]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)
        )
    )
}

/// How far from the shoreline a scattered thing is placed, given its index.
nonisolated private func scatterAt(_ i: Int, _ spread: CGFloat) -> (CGFloat, CGFloat) {
    let x = CGFloat((i * 37) % 100) / 100
    let near = i % 2 == 0
    let off = CGFloat((i * 53) % 100) / 100 * spread + 0.012
    let edge = near ? shoreBottomAt(x) : shoreTopAt(x)
    return (x, near ? edge + off : edge - off)
}

/// Pale sand, with drift ripples and a scatter of shells.
nonisolated private func drawSandShore(_ ctx: inout GraphicsContext, _ size: CGSize, _ palette: PondPalette) {
    let (light, dark) = shoreTones("sand", palette)
    drawGround(&ctx, size, light, dark)
    let w = size.width, h = size.height

    // Wind ripples: shallow arcs following the shoreline rather than the frame.
    for i in 0..<10 {
        let near = i % 2 == 0
        let depth = 0.02 + 0.026 * CGFloat(i / 2)
        var ripple = Path()
        for step in 0...24 {
            let x = CGFloat(step) / 24
            let edge = near ? shoreBottomAt(x) + depth : shoreTopAt(x) - depth
            let pt = CGPoint(x: x * w, y: edge * h)
            if step == 0 { ripple.move(to: pt) } else { ripple.addLine(to: pt) }
        }
        ctx.stroke(ripple, with: .color(dark.blended(.black, 0.10).opacity(0.20)), style: stroke(w * 0.005))
    }
    for i in 0..<18 {
        let (x, y) = scatterAt(i, 0.085)
        if y < 0 || y > 1 { continue }
        ctx.fill(
            oval(CGPoint(x: x * w - w * 0.010, y: y * h - h * 0.006), CGSize(width: w * 0.020, height: h * 0.011)),
            with: .color(Color.white.blended(palette.ripple, 0.25).opacity(0.75))
        )
    }
}

/// Grey shingle: two sizes of stone, packed tightest at the waterline.
nonisolated private func drawPebbleShore(_ ctx: inout GraphicsContext, _ size: CGSize, _ palette: PondPalette) {
    let (light, dark) = shoreTones("pebbles", palette)
    drawGround(&ctx, size, light, dark)
    let w = size.width, h = size.height
    for i in 0..<88 {
        let (x, y) = scatterAt(i, 0.115)
        if y < 0 || y > 1 { continue }
        let r = w * (0.008 + 0.011 * CGFloat((i * 17) % 100) / 100)
        let tone: Color
        switch i % 3 {
        case 0: tone = light.blended(.white, 0.30)
        case 1: tone = dark
        default: tone = palette.rock
        }
        ctx.fill(
            oval(CGPoint(x: x * w - r, y: y * h - r * 0.68), CGSize(width: r * 2, height: r * 1.36)),
            with: .color(tone.opacity(0.9))
        )
    }
}

/// Deep moss, with fern fronds and a few cushions.
nonisolated private func drawMossShore(_ ctx: inout GraphicsContext, _ size: CGSize, _ palette: PondPalette, _ time: CGFloat) {
    let (light, dark) = shoreTones("moss", palette)
    drawGround(&ctx, size, light, dark)
    let w = size.width, h = size.height

    // Cushions of moss: overlapping soft blobs, no outlines.
    for i in 0..<34 {
        let (x, y) = scatterAt(i, 0.13)
        if y < 0 || y > 1 { continue }
        let r = w * (0.030 + 0.030 * CGFloat((i * 23) % 100) / 100)
        ctx.fill(
            oval(CGPoint(x: x * w - r, y: y * h - r * 0.5), CGSize(width: r * 2, height: r)),
            with: .color(light.blended(Color(hex: 0x6FA84C), 0.5).opacity(0.35))
        )
    }
    // Fronds, leaning with the same slow clock the meadow's tufts use.
    for i in 0..<20 {
        let (x, y) = scatterAt(i * 3, 0.10)
        if y < 0 || y > 1 { continue }
        let lean = sin(time * 0.5 + CGFloat(i)) * w * 0.010
        var spine = Path()
        spine.move(to: CGPoint(x: x * w, y: y * h))
        spine.addQuadCurve(
            to: CGPoint(x: x * w + lean * 2.4, y: y * h - h * 0.055),
            control: CGPoint(x: x * w + lean, y: y * h - h * 0.030)
        )
        ctx.stroke(spine, with: .color(dark.opacity(0.75)), style: stroke(w * 0.006))
        for leaf in 1...3 {
            let t = CGFloat(leaf) / 4
            ctx.fill(
                oval(CGPoint(x: x * w + lean * t * 2.4 - w * 0.014, y: y * h - h * 0.055 * t),
                     CGSize(width: w * 0.028, height: h * 0.010)),
                with: .color(light.blended(.white, 0.10).opacity(0.55))
            )
        }
    }
}

/// Fresh snow, drifted against the shoreline, with bare twigs poking through.
nonisolated private func drawSnowShore(_ ctx: inout GraphicsContext, _ size: CGSize, _ palette: PondPalette) {
    let (light, dark) = shoreTones("snow", palette)
    drawGround(&ctx, size, light, dark)
    let w = size.width, h = size.height

    // A drift banked up along each shoreline: the snow is deepest where it has
    // nowhere further to blow.
    for near in [true, false] {
        var drift = Path()
        for step in 0...28 {
            let x = CGFloat(step) / 28
            let edge = near ? shoreBottomAt(x) : shoreTopAt(x)
            let y = near ? edge + 0.055 : edge - 0.055
            let pt = CGPoint(x: x * w, y: y * h)
            if step == 0 { drift.move(to: pt) } else { drift.addLine(to: pt) }
        }
        for step in stride(from: 28, through: 0, by: -1) {
            let x = CGFloat(step) / 28
            let edge = near ? shoreBottomAt(x) : shoreTopAt(x)
            drift.addLine(to: CGPoint(x: x * w, y: edge * h))
        }
        drift.closeSubpath()
        ctx.fill(drift, with: .color(Color.white.opacity(0.55)))
    }
    // Sparkle, and a few twigs so the bank is not a blank sheet.
    for i in 0..<26 {
        let (x, y) = scatterAt(i, 0.10)
        if y < 0 || y > 1 { continue }
        ctx.fill(circle(CGPoint(x: x * w, y: y * h), w * 0.004), with: .color(.white))
    }
    for i in 0..<7 {
        let (x, y) = scatterAt(i * 6 + 1, 0.12)
        if y < 0 || y > 1 { continue }
        ctx.stroke(
            line(CGPoint(x: x * w, y: y * h), CGPoint(x: x * w + w * 0.014, y: y * h - h * 0.045)),
            with: .color(Color(hex: 0x6B5540).blended(palette.rockDark, 0.4)), style: stroke(w * 0.006)
        )
    }
}

/// Fallen leaves over dark earth, drifting a little where they lie.
nonisolated private func drawAutumnShore(_ ctx: inout GraphicsContext, _ size: CGSize, _ palette: PondPalette, _ time: CGFloat) {
    let (light, dark) = shoreTones("autumn", palette)
    drawGround(&ctx, size, light, dark)
    let w = size.width, h = size.height
    // Leaves keep their own reds and golds: an autumn bank tinted to a blue
    // palette is a bank of blue leaves, which is a different season entirely.
    let leaves = [Color(hex: 0xC0562C), Color(hex: 0xE08A2A), Color(hex: 0xD9B23A), Color(hex: 0x8E4A25)]
    for i in 0..<62 {
        let (x, y) = scatterAt(i, 0.13)
        if y < 0 || y > 1 { continue }
        let r = w * (0.014 + 0.010 * CGFloat((i * 29) % 100) / 100)
        let turn = CGFloat((i * 47) % 180) + sin(time * 0.25 + CGFloat(i)) * 5
        var c = rotated(ctx, degrees: turn, pivot: CGPoint(x: x * w, y: y * h))
        var leaf = Path()
        leaf.move(to: CGPoint(x: x * w - r, y: y * h))
        leaf.addQuadCurve(to: CGPoint(x: x * w + r, y: y * h), control: CGPoint(x: x * w, y: y * h - r * 0.9))
        leaf.addQuadCurve(to: CGPoint(x: x * w - r, y: y * h), control: CGPoint(x: x * w, y: y * h + r * 0.9))
        leaf.closeSubpath()
        c.fill(leaf, with: .color(leaves[i % leaves.count].opacity(0.9)))
        c.stroke(
            line(CGPoint(x: x * w - r, y: y * h), CGPoint(x: x * w + r, y: y * h)),
            with: .color(dark.opacity(0.5)), style: stroke(w * 0.003)
        )
    }
}
