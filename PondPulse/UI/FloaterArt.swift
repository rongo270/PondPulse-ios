//
//  FloaterArt.swift
//  PondPulse
//
//  All floater skins and pad styles, drawn cell-sized into a GraphicsContext -
//  a 1:1 port of the Android ui/FloaterArt.kt Canvas code. The same functions
//  render the shop previews. Skins keep the duckling's puzzle tint
//  (red/green/blue) so colored levels stay readable with any skin.
//

import SwiftUI

nonisolated let ink = Color(hex: 0x17303F)

extension Color {
    nonisolated private var rgba: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    nonisolated func shaded(_ f: CGFloat = 0.82) -> Color {
        let c = rgba
        return Color(red: c.r * f, green: c.g * f, blue: c.b * f).opacity(c.a)
    }

    nonisolated func lightened(_ f: CGFloat = 1.2) -> Color {
        let c = rgba
        return Color(red: min(c.r * f, 1), green: min(c.g * f, 1), blue: min(c.b * f, 1)).opacity(c.a)
    }
}

nonisolated func bodyTint(_ palette: PondPalette, _ color: DuckColor?, _ natural: Color) -> Color {
    color == nil ? natural : palette.duckTint(color)
}

// MARK: - Small path helpers
//
// Internal, not file-private: FloaterArtMore.swift draws its twenty friends and
// eight pads with exactly this vocabulary, the way Android's FloaterArtMore.kt
// shares FloaterArt.kt's helpers.

nonisolated func oval(_ topLeft: CGPoint, _ size: CGSize) -> Path {
    Path(ellipseIn: CGRect(origin: topLeft, size: size))
}

nonisolated func circle(_ center: CGPoint, _ radius: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
}

nonisolated func polygon(_ points: [CGPoint]) -> Path {
    var p = Path()
    p.move(to: points[0])
    for pt in points.dropFirst() { p.addLine(to: pt) }
    p.closeSubpath()
    return p
}

nonisolated func line(_ from: CGPoint, _ to: CGPoint) -> Path {
    var p = Path()
    p.move(to: from)
    p.addLine(to: to)
    return p
}

/// Compose-style drawArc: an arc of the ellipse inscribed in the rect,
/// degrees, 0° at 3 o'clock, positive sweep clockwise on screen.
nonisolated func ovalArc(
    _ topLeft: CGPoint, _ size: CGSize, start: Double, sweep: Double, useCenter: Bool
) -> Path {
    var unit = Path()
    let center = CGPoint.zero
    if useCenter { unit.move(to: center) }
    unit.addArc(
        center: center,
        radius: 0.5,
        startAngle: .degrees(start),
        endAngle: .degrees(start + sweep),
        clockwise: false
    )
    if useCenter { unit.closeSubpath() }
    let transform = CGAffineTransform(translationX: topLeft.x + size.width / 2, y: topLeft.y + size.height / 2)
        .scaledBy(x: size.width, y: size.height)
    return unit.applying(transform)
}

nonisolated func stroke(_ width: CGFloat, cap: CGLineCap = .butt) -> StrokeStyle {
    StrokeStyle(lineWidth: width, lineCap: cap)
}

nonisolated func rotated(_ ctx: GraphicsContext, degrees: CGFloat, pivot: CGPoint) -> GraphicsContext {
    var c = ctx
    c.translateBy(x: pivot.x, y: pivot.y)
    c.rotate(by: .degrees(degrees))
    c.translateBy(x: -pivot.x, y: -pivot.y)
    return c
}

// MARK: - Dispatch

/// Draws the equipped skin for a duckling floater.
nonisolated func drawFloaterSkin(_ ctx: inout GraphicsContext, skinId: String, rect: CGRect, palette: PondPalette, color: DuckColor?) {
    switch skinId {
    case "frog": drawFrog(&ctx, rect, palette, color)
    case "swan": drawSwan(&ctx, rect, palette, color)
    case "koi": drawKoi(&ctx, rect, palette, color)
    case "penguin": drawPenguin(&ctx, rect, palette, color)
    case "flamingo": drawFlamingo(&ctx, rect, palette, color)
    case "boat": drawBoat(&ctx, rect, palette, color)
    case "axolotl": drawAxolotl(&ctx, rect, palette, color)
    case "otter": drawOtter(&ctx, rect, palette, color)
    case "jelly": drawJellyfish(&ctx, rect, palette, color)
    case "robo": drawRoboDuck(&ctx, rect, palette, color)
    case "golden": drawGoldenDuck(&ctx, rect, palette, color)
    case "dragon": drawDragon(&ctx, rect, palette, color)
    case "narwhal": drawNarwhal(&ctx, rect, palette, color)
    case "beaver": drawBeaver(&ctx, rect, palette, color)
    case "gosling": drawGosling(&ctx, rect, palette, color)
    default: drawDuck(&ctx, rect, palette, tint: palette.duckTint(color))
    }
}

/// Draws the equipped pad style, plus the color ring for colored pads.
nonisolated func drawPadStyle(_ ctx: inout GraphicsContext, padId: String, rect: CGRect, palette: PondPalette, ring: Color?) {
    switch padId {
    case "lotus": drawLotusPad(&ctx, rect, palette)
    case "goldenlily": drawGoldenLilyPad(&ctx, rect)
    case "ice": drawIcePad(&ctx, rect)
    case "starlight": drawStarlightPad(&ctx, rect)
    case "shell": drawShellPad(&ctx, rect)
    case "rainbow": drawRainbowPad(&ctx, rect, palette)
    case "sunflower": drawSunflowerPad(&ctx, rect)
    case "clover": drawCloverPad(&ctx, rect)
    case "gem": drawGemPad(&ctx, rect)
    case "honey": drawHoneyPad(&ctx, rect)
    case "moon": drawMoonPad(&ctx, rect)
    case "crown": drawCrownPad(&ctx, rect)
    case "aurora": drawAuroraPad(&ctx, rect)
    default: drawLilyPad(&ctx, rect, palette)
    }
    if let ring {
        ctx.stroke(circle(CGPoint(x: rect.midX, y: rect.midY), rect.width * 0.46), with: .color(ring), style: stroke(rect.width * 0.06))
    }
}

// MARK: - Floaters

nonisolated func drawDuck(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, tint: Color) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let dark = tint.shaded()
    // Body.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y - cell * 0.10), CGSize(width: cell * 0.64, height: cell * 0.46)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y - cell * 0.14), CGSize(width: cell * 0.64, height: cell * 0.46)), with: .color(tint))
    // Head, facing right.
    let head = CGPoint(x: c.x + cell * 0.16, y: c.y - cell * 0.24)
    ctx.fill(circle(head, cell * 0.19), with: .color(tint))
    // Beak.
    ctx.fill(polygon([
        CGPoint(x: head.x + cell * 0.15, y: head.y - cell * 0.06),
        CGPoint(x: head.x + cell * 0.34, y: head.y + cell * 0.015),
        CGPoint(x: head.x + cell * 0.15, y: head.y + cell * 0.09),
    ]), with: .color(palette.beak))
    // Eye.
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.055, y: head.y - cell * 0.045), cell * 0.035), with: .color(ink))
    // Wing.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.05), CGSize(width: cell * 0.30, height: cell * 0.22)), with: .color(dark))
}

nonisolated func drawTurtle(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    // Flippers.
    for dx in [-1.0, 1.0] {
        for dy in [-1.0, 1.0] {
            ctx.fill(oval(
                CGPoint(x: c.x + dx * cell * 0.24 - cell * 0.09, y: c.y + dy * cell * 0.17 - cell * 0.06),
                CGSize(width: cell * 0.18, height: cell * 0.12)
            ), with: .color(palette.turtle))
        }
    }
    // Head.
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.32, y: c.y), cell * 0.10), with: .color(palette.turtle))
    // Shell.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.22), CGSize(width: cell * 0.56, height: cell * 0.44)), with: .color(palette.turtleShell))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.20, y: c.y - cell * 0.15), CGSize(width: cell * 0.40, height: cell * 0.30)), with: .color(palette.turtle))
    ctx.stroke(line(CGPoint(x: c.x - cell * 0.20, y: c.y), CGPoint(x: c.x + cell * 0.20, y: c.y)), with: .color(palette.turtleShell), style: stroke(cell * 0.03))
    ctx.stroke(line(CGPoint(x: c.x, y: c.y - cell * 0.15), CGPoint(x: c.x, y: c.y + cell * 0.15)), with: .color(palette.turtleShell), style: stroke(cell * 0.03))
}

nonisolated private func drawFrog(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x58C15B))
    let dark = body.shaded()
    // Haunches.
    for dx in [-1.0, 1.0] {
        ctx.fill(oval(
            CGPoint(x: c.x + dx * cell * 0.22 - cell * 0.12, y: c.y - cell * 0.02),
            CGSize(width: cell * 0.24, height: cell * 0.28)
        ), with: .color(dark))
    }
    // Body.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.26, y: c.y - cell * 0.20), CGSize(width: cell * 0.52, height: cell * 0.44)), with: .color(body))
    // Bulging eyes.
    for dx in [-1.0, 1.0] {
        let eye = CGPoint(x: c.x + dx * cell * 0.13, y: c.y - cell * 0.25)
        ctx.fill(circle(eye, cell * 0.10), with: .color(body))
        ctx.fill(circle(CGPoint(x: eye.x, y: eye.y - cell * 0.01), cell * 0.06), with: .color(.white))
        ctx.fill(circle(CGPoint(x: eye.x, y: eye.y - cell * 0.01), cell * 0.03), with: .color(ink))
    }
    // Smile.
    ctx.stroke(
        ovalArc(CGPoint(x: c.x - cell * 0.12, y: c.y - cell * 0.13), CGSize(width: cell * 0.24, height: cell * 0.16), start: 25, sweep: 130, useCenter: false),
        with: .color(ink.opacity(0.6)),
        style: stroke(cell * 0.025, cap: .round)
    )
    // Cheeks.
    for dx in [-1.0, 1.0] {
        ctx.fill(circle(CGPoint(x: c.x + dx * cell * 0.19, y: c.y - cell * 0.05), cell * 0.035), with: .color(Color(hex: 0xFF9EC4).opacity(0.55)))
    }
}

nonisolated private func drawSwan(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xF4F7FB))
    let shadow = body.shaded(0.88)
    // Body.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.31, y: c.y - cell * 0.04), CGSize(width: cell * 0.58, height: cell * 0.38)), with: .color(shadow))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.31, y: c.y - cell * 0.08), CGSize(width: cell * 0.58, height: cell * 0.38)), with: .color(body))
    // Folded wing.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.01), CGSize(width: cell * 0.30, height: cell * 0.20)), with: .color(shadow))
    // Graceful neck.
    var neck = Path()
    neck.move(to: CGPoint(x: c.x + cell * 0.15, y: c.y + cell * 0.04))
    neck.addCurve(
        to: CGPoint(x: c.x + cell * 0.26, y: c.y - cell * 0.34),
        control1: CGPoint(x: c.x + cell * 0.34, y: c.y - cell * 0.08),
        control2: CGPoint(x: c.x + cell * 0.10, y: c.y - cell * 0.24)
    )
    ctx.stroke(neck, with: .color(body), style: stroke(cell * 0.11, cap: .round))
    // Head and beak.
    let head = CGPoint(x: c.x + cell * 0.27, y: c.y - cell * 0.35)
    ctx.fill(circle(head, cell * 0.095), with: .color(body))
    ctx.fill(polygon([
        CGPoint(x: head.x + cell * 0.06, y: head.y - cell * 0.035),
        CGPoint(x: head.x + cell * 0.21, y: head.y + cell * 0.01),
        CGPoint(x: head.x + cell * 0.06, y: head.y + cell * 0.05),
    ]), with: .color(Color(hex: 0xFF8A3D)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.02, y: head.y - cell * 0.02), cell * 0.028), with: .color(ink))
}

nonisolated private func drawKoi(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xFF8A5C))
    let dark = body.shaded()
    // Tail, flicking left.
    ctx.fill(polygon([
        CGPoint(x: c.x - cell * 0.16, y: c.y),
        CGPoint(x: c.x - cell * 0.40, y: c.y - cell * 0.17),
        CGPoint(x: c.x - cell * 0.33, y: c.y + cell * 0.01),
        CGPoint(x: c.x - cell * 0.40, y: c.y + cell * 0.19),
    ]), with: .color(dark))
    // Dorsal fin.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.08, y: c.y - cell * 0.25), CGSize(width: cell * 0.20, height: cell * 0.13)), with: .color(dark))
    // Body.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.26, y: c.y - cell * 0.17), CGSize(width: cell * 0.60, height: cell * 0.35)), with: .color(body))
    // Koi patches.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.12, y: c.y - cell * 0.16), CGSize(width: cell * 0.22, height: cell * 0.14)), with: .color(.white.opacity(0.85)))
    ctx.fill(oval(CGPoint(x: c.x + cell * 0.08, y: c.y + cell * 0.02), CGSize(width: cell * 0.16, height: cell * 0.10)), with: .color(.white.opacity(0.65)))
    // Face.
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.23, y: c.y - cell * 0.06), cell * 0.035), with: .color(ink))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.335, y: c.y + cell * 0.01), cell * 0.032), with: .color(dark))
}

nonisolated private func drawPenguin(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x3B4A57))
    let dark = body.shaded()
    // Flippers.
    for dx in [-1.0, 1.0] {
        ctx.fill(oval(
            CGPoint(x: c.x + dx * cell * 0.26 - cell * 0.06, y: c.y - cell * 0.10),
            CGSize(width: cell * 0.12, height: cell * 0.28)
        ), with: .color(dark))
    }
    // Body.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.32), CGSize(width: cell * 0.44, height: cell * 0.62)), with: .color(body))
    // Belly.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.14, y: c.y - cell * 0.12), CGSize(width: cell * 0.28, height: cell * 0.38)), with: .color(Color(hex: 0xF6F9FB)))
    // Face.
    for dx in [-1.0, 1.0] {
        ctx.fill(circle(CGPoint(x: c.x + dx * cell * 0.075, y: c.y - cell * 0.20), cell * 0.045), with: .color(.white))
        ctx.fill(circle(CGPoint(x: c.x + dx * cell * 0.075, y: c.y - cell * 0.20), cell * 0.022), with: .color(ink))
    }
    ctx.fill(polygon([
        CGPoint(x: c.x - cell * 0.045, y: c.y - cell * 0.14),
        CGPoint(x: c.x + cell * 0.045, y: c.y - cell * 0.14),
        CGPoint(x: c.x, y: c.y - cell * 0.07),
    ]), with: .color(Color(hex: 0xFF9046)))
}

nonisolated private func drawFlamingo(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xFF7BA9))
    let dark = body.shaded()
    // Body.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y), CGSize(width: cell * 0.50, height: cell * 0.32)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.04), CGSize(width: cell * 0.50, height: cell * 0.32)), with: .color(body))
    // Wing.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.22, y: c.y + cell * 0.02), CGSize(width: cell * 0.26, height: cell * 0.16)), with: .color(dark))
    // Tall S neck.
    var neck = Path()
    neck.move(to: CGPoint(x: c.x + cell * 0.13, y: c.y + cell * 0.06))
    neck.addCurve(
        to: CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.38),
        control1: CGPoint(x: c.x + cell * 0.36, y: c.y - cell * 0.06),
        control2: CGPoint(x: c.x + cell * 0.06, y: c.y - cell * 0.24)
    )
    ctx.stroke(neck, with: .color(body), style: stroke(cell * 0.09, cap: .round))
    // Head with a drooping black-tipped beak.
    let head = CGPoint(x: c.x + cell * 0.235, y: c.y - cell * 0.385)
    ctx.fill(circle(head, cell * 0.085), with: .color(body))
    ctx.fill(polygon([
        CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.03),
        CGPoint(x: head.x + cell * 0.19, y: head.y + cell * 0.05),
        CGPoint(x: head.x + cell * 0.045, y: head.y + cell * 0.05),
    ]), with: .color(Color(hex: 0xF6F9FB)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.165, y: head.y + cell * 0.035), cell * 0.035), with: .color(ink))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.015, y: head.y - cell * 0.015), cell * 0.025), with: .color(ink))
}

nonisolated private func drawBoat(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let paper = bodyTint(palette, color, Color(hex: 0xF7F4EA))
    let crease = paper.shaded(0.86)
    // Sails.
    ctx.fill(polygon([
        CGPoint(x: c.x, y: c.y - cell * 0.36),
        CGPoint(x: c.x, y: c.y + cell * 0.02),
        CGPoint(x: c.x + cell * 0.24, y: c.y + cell * 0.02),
    ]), with: .color(paper))
    ctx.fill(polygon([
        CGPoint(x: c.x - cell * 0.03, y: c.y - cell * 0.26),
        CGPoint(x: c.x - cell * 0.03, y: c.y + cell * 0.02),
        CGPoint(x: c.x - cell * 0.22, y: c.y + cell * 0.02),
    ]), with: .color(crease))
    // Flag.
    ctx.fill(circle(CGPoint(x: c.x, y: c.y - cell * 0.38), cell * 0.035), with: .color(palette.accent))
    // Hull.
    ctx.fill(polygon([
        CGPoint(x: c.x - cell * 0.33, y: c.y + cell * 0.06),
        CGPoint(x: c.x + cell * 0.33, y: c.y + cell * 0.06),
        CGPoint(x: c.x + cell * 0.17, y: c.y + cell * 0.26),
        CGPoint(x: c.x - cell * 0.17, y: c.y + cell * 0.26),
    ]), with: .color(paper.shaded(0.92)))
    ctx.stroke(
        line(CGPoint(x: c.x - cell * 0.33, y: c.y + cell * 0.06), CGPoint(x: c.x + cell * 0.33, y: c.y + cell * 0.06)),
        with: .color(crease),
        style: stroke(cell * 0.025)
    )
}

nonisolated private func drawAxolotl(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xFFA9C6))
    let gillColor = color == nil ? Color(hex: 0xFF5E96) : body.shaded(0.7)
    // Tail with fin.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.42, y: c.y - cell * 0.12), CGSize(width: cell * 0.30, height: cell * 0.24)), with: .color(body.shaded(0.9)))
    // Gills: three fronds each side of the head.
    let head = CGPoint(x: c.x + cell * 0.18, y: c.y - cell * 0.04)
    for side in [-1.0, 1.0] {
        for i in -1...1 {
            let angle = (-70.0 + Double(i) * 38.0) * .pi / 180
            let from = CGPoint(x: head.x + side * cell * 0.10, y: head.y - cell * 0.04)
            let to = CGPoint(x: from.x + side * cos(angle) * cell * 0.15, y: from.y + sin(angle) * cell * 0.15)
            ctx.stroke(line(from, to), with: .color(gillColor), style: stroke(cell * 0.05, cap: .round))
        }
    }
    // Body.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.16), CGSize(width: cell * 0.56, height: cell * 0.32)), with: .color(body))
    // Face.
    for dx in [-1.0, 1.0] {
        ctx.fill(circle(CGPoint(x: head.x + dx * cell * 0.07, y: head.y - cell * 0.02), cell * 0.03), with: .color(ink))
    }
    ctx.stroke(
        ovalArc(CGPoint(x: head.x - cell * 0.05, y: head.y), CGSize(width: cell * 0.10, height: cell * 0.07), start: 30, sweep: 120, useCenter: false),
        with: .color(ink.opacity(0.55)),
        style: stroke(cell * 0.02, cap: .round)
    )
    for dx in [-1.0, 1.0] {
        ctx.fill(circle(CGPoint(x: head.x + dx * cell * 0.11, y: head.y + cell * 0.03), cell * 0.03), with: .color(gillColor.opacity(0.45)))
    }
}

nonisolated private func drawOtter(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let fur = bodyTint(palette, color, Color(hex: 0x8D6E4F))
    let belly = fur.lightened(1.35)
    // Floating on its back.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.32, y: c.y - cell * 0.08), CGSize(width: cell * 0.60, height: cell * 0.32)), with: .color(fur))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.03), CGSize(width: cell * 0.42, height: cell * 0.22)), with: .color(belly))
    // Paws resting on the belly.
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.10, y: c.y + cell * 0.02), cell * 0.05), with: .color(fur))
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.02), cell * 0.05), with: .color(fur))
    // Head.
    let head = CGPoint(x: c.x + cell * 0.24, y: c.y - cell * 0.15)
    ctx.fill(circle(CGPoint(x: head.x - cell * 0.10, y: head.y - cell * 0.11), cell * 0.045), with: .color(fur))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.07, y: head.y - cell * 0.12), cell * 0.045), with: .color(fur))
    ctx.fill(circle(head, cell * 0.145), with: .color(fur))
    // Muzzle and face.
    ctx.fill(circle(CGPoint(x: head.x, y: head.y + cell * 0.05), cell * 0.08), with: .color(belly))
    ctx.fill(circle(CGPoint(x: head.x, y: head.y + cell * 0.01), cell * 0.03), with: .color(Color(hex: 0x3A2A1C)))
    for dx in [-1.0, 1.0] {
        ctx.fill(circle(CGPoint(x: head.x + dx * cell * 0.06, y: head.y - cell * 0.045), cell * 0.025), with: .color(ink))
    }
}

nonisolated private func drawJellyfish(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xC48BE8))
    let glow = body.lightened(1.25)
    // Trailing tentacles first, so the bell overlaps them.
    for i in -2...2 {
        let x = c.x + CGFloat(i) * cell * 0.09
        let sway = CGFloat(i % 2) * cell * 0.05
        var tentacle = Path()
        tentacle.move(to: CGPoint(x: x, y: c.y + cell * 0.02))
        tentacle.addCurve(
            to: CGPoint(x: x + sway, y: c.y + cell * 0.34),
            control1: CGPoint(x: x - cell * 0.04 + sway, y: c.y + cell * 0.14),
            control2: CGPoint(x: x + cell * 0.05 - sway, y: c.y + cell * 0.24)
        )
        ctx.stroke(tentacle, with: .color(body.opacity(0.75)), style: stroke(cell * 0.03, cap: .round))
    }
    // Translucent bell.
    ctx.fill(
        ovalArc(CGPoint(x: c.x - cell * 0.33, y: c.y - cell * 0.30), CGSize(width: cell * 0.66, height: cell * 0.62), start: 180, sweep: 180, useCenter: true),
        with: .color(glow.opacity(0.45))
    )
    ctx.fill(
        ovalArc(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.25), CGSize(width: cell * 0.56, height: cell * 0.52), start: 180, sweep: 180, useCenter: true),
        with: .color(body)
    )
    // Skirt.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.05), CGSize(width: cell * 0.56, height: cell * 0.12)), with: .color(body))
    // Shine and sleepy face.
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.12, y: c.y - cell * 0.15), cell * 0.05), with: .color(.white.opacity(0.5)))
    for dx in [-1.0, 1.0] {
        ctx.fill(circle(CGPoint(x: c.x + dx * cell * 0.09, y: c.y - cell * 0.04), cell * 0.028), with: .color(ink))
    }
}

nonisolated private func drawRoboDuck(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let metal = bodyTint(palette, color, Color(hex: 0x9FB4C7))
    let dark = metal.shaded(0.72)
    // Boxy hull.
    ctx.fill(Path(roundedRect: CGRect(x: c.x - cell * 0.30, y: c.y - cell * 0.08, width: cell * 0.60, height: cell * 0.40), cornerRadius: cell * 0.10), with: .color(dark))
    ctx.fill(Path(roundedRect: CGRect(x: c.x - cell * 0.30, y: c.y - cell * 0.12, width: cell * 0.60, height: cell * 0.40), cornerRadius: cell * 0.10), with: .color(metal))
    // Rivets.
    for i in 0...2 {
        ctx.fill(circle(CGPoint(x: c.x - cell * 0.18 + CGFloat(i) * cell * 0.14, y: c.y + cell * 0.12), cell * 0.025), with: .color(dark))
    }
    // Square head with a glowing visor.
    let head = CGPoint(x: c.x + cell * 0.14, y: c.y - cell * 0.26)
    ctx.fill(Path(roundedRect: CGRect(x: head.x - cell * 0.14, y: head.y - cell * 0.12, width: cell * 0.28, height: cell * 0.26), cornerRadius: cell * 0.06), with: .color(metal))
    ctx.fill(Path(roundedRect: CGRect(x: head.x - cell * 0.09, y: head.y - cell * 0.06, width: cell * 0.18, height: cell * 0.09), cornerRadius: cell * 0.03), with: .color(ink))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.035, y: head.y - cell * 0.015), cell * 0.033), with: .color(Color(hex: 0x6CF0FF)))
    // Beak vent.
    ctx.fill(polygon([
        CGPoint(x: head.x + cell * 0.13, y: head.y - cell * 0.02),
        CGPoint(x: head.x + cell * 0.28, y: head.y + cell * 0.035),
        CGPoint(x: head.x + cell * 0.13, y: head.y + cell * 0.09),
    ]), with: .color(palette.beak))
    // Antenna.
    ctx.stroke(
        line(CGPoint(x: head.x - cell * 0.05, y: head.y - cell * 0.12), CGPoint(x: head.x - cell * 0.05, y: head.y - cell * 0.22)),
        with: .color(dark),
        style: stroke(cell * 0.025)
    )
    ctx.fill(circle(CGPoint(x: head.x - cell * 0.05, y: head.y - cell * 0.24), cell * 0.035), with: .color(Color(hex: 0xFF5C6E)))
}

nonisolated private func drawGoldenDuck(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let gold = bodyTint(palette, color, Color(hex: 0xFFC928))
    // Trophy glow behind the classic duckling.
    ctx.fill(circle(c, cell * 0.46), with: .color(Color(hex: 0xFFE9A6).opacity(0.35)))
    drawDuck(&ctx, rect, palette, tint: gold)
    // Sparkles.
    for (offset, r) in [
        (CGPoint(x: -cell * 0.30, y: -cell * 0.28), cell * 0.05),
        (CGPoint(x: cell * 0.34, y: -cell * 0.34), cell * 0.04),
        (CGPoint(x: -cell * 0.36, y: cell * 0.16), cell * 0.035),
    ] {
        let at = CGPoint(x: c.x + offset.x, y: c.y + offset.y)
        ctx.stroke(line(CGPoint(x: at.x - r, y: at.y), CGPoint(x: at.x + r, y: at.y)), with: .color(.white), style: stroke(cell * 0.022, cap: .round))
        ctx.stroke(line(CGPoint(x: at.x, y: at.y - r), CGPoint(x: at.x, y: at.y + r)), with: .color(.white), style: stroke(cell * 0.022, cap: .round))
    }
}

nonisolated private func drawDragon(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x4FC978))
    let dark = body.shaded()
    let belly = body.lightened(1.3)
    // Spade-tipped tail curling out to the left.
    var tail = Path()
    tail.move(to: CGPoint(x: c.x - cell * 0.18, y: c.y + cell * 0.04))
    tail.addCurve(
        to: CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.20),
        control1: CGPoint(x: c.x - cell * 0.38, y: c.y + cell * 0.02),
        control2: CGPoint(x: c.x - cell * 0.42, y: c.y - cell * 0.14)
    )
    ctx.stroke(tail, with: .color(dark), style: stroke(cell * 0.06, cap: .round))
    ctx.fill(polygon([
        CGPoint(x: c.x - cell * 0.34, y: c.y - cell * 0.29),
        CGPoint(x: c.x - cell * 0.27, y: c.y - cell * 0.16),
        CGPoint(x: c.x - cell * 0.41, y: c.y - cell * 0.16),
    ]), with: .color(dark))
    // Body with back spikes and a folded wing.
    for i in 0...2 {
        let x = c.x - cell * 0.14 + CGFloat(i) * cell * 0.11
        ctx.fill(polygon([
            CGPoint(x: x, y: c.y - cell * 0.13),
            CGPoint(x: x + cell * 0.05, y: c.y - cell * 0.24),
            CGPoint(x: x + cell * 0.10, y: c.y - cell * 0.13),
        ]), with: .color(dark))
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.15), CGSize(width: cell * 0.58, height: cell * 0.42)), with: .color(body))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.18, y: c.y + cell * 0.02), CGSize(width: cell * 0.36, height: cell * 0.22)), with: .color(belly))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.20, y: c.y - cell * 0.10), CGSize(width: cell * 0.24, height: cell * 0.16)), with: .color(dark))
    // Horned head.
    let head = CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.22)
    for dx in [-1.0, 1.0] {
        ctx.fill(polygon([
            CGPoint(x: head.x + dx * cell * 0.045, y: head.y - cell * 0.12),
            CGPoint(x: head.x + dx * cell * 0.10, y: head.y - cell * 0.24),
            CGPoint(x: head.x + dx * cell * 0.115, y: head.y - cell * 0.10),
        ]), with: .color(Color(hex: 0xF2E4C8)))
    }
    ctx.fill(circle(head, cell * 0.16), with: .color(body))
    ctx.fill(oval(CGPoint(x: head.x + cell * 0.02, y: head.y - cell * 0.02), CGSize(width: cell * 0.16, height: cell * 0.12)), with: .color(belly))
    ctx.fill(circle(CGPoint(x: head.x - cell * 0.02, y: head.y - cell * 0.045), cell * 0.032), with: .color(ink))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.115, y: head.y + cell * 0.025), cell * 0.018), with: .color(ink))
    // A puff of flame in front of the snout.
    let flame = CGPoint(x: head.x + cell * 0.24, y: head.y + cell * 0.045)
    ctx.fill(circle(flame, cell * 0.05), with: .color(Color(hex: 0xFF8A3D)))
    ctx.fill(circle(CGPoint(x: flame.x + cell * 0.012, y: flame.y), cell * 0.028), with: .color(Color(hex: 0xFFD44D)))
}

nonisolated private func drawNarwhal(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x8FB6DE))
    let dark = body.shaded()
    let belly = body.lightened(1.25)
    // Tail flukes.
    ctx.fill(polygon([
        CGPoint(x: c.x - cell * 0.20, y: c.y + cell * 0.02),
        CGPoint(x: c.x - cell * 0.42, y: c.y - cell * 0.12),
        CGPoint(x: c.x - cell * 0.34, y: c.y + cell * 0.04),
        CGPoint(x: c.x - cell * 0.42, y: c.y + cell * 0.20),
    ]), with: .color(dark))
    // Rounded body, belly patch, little side fin.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.28, y: c.y - cell * 0.16), CGSize(width: cell * 0.60, height: cell * 0.38)), with: .color(body))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.16, y: c.y + cell * 0.02), CGSize(width: cell * 0.40, height: cell * 0.18)), with: .color(belly))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.10, y: c.y), CGSize(width: cell * 0.16, height: cell * 0.11)), with: .color(dark))
    // Mottled back, like a real narwhal.
    for (dx, dy) in [(-0.14, -0.10), (0.02, -0.12), (0.14, -0.06)] {
        ctx.fill(circle(CGPoint(x: c.x + cell * dx, y: c.y + cell * dy), cell * 0.025), with: .color(dark.opacity(0.5)))
    }
    // The legendary spiral tusk.
    let snout = CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.08)
    let tip = CGPoint(x: snout.x + cell * 0.20, y: snout.y - cell * 0.22)
    ctx.stroke(line(snout, tip), with: .color(Color(hex: 0xF4EEDC)), style: stroke(cell * 0.045, cap: .round))
    for i in 1...3 {
        let t = CGFloat(i) / 4
        let at = CGPoint(x: snout.x + (tip.x - snout.x) * t, y: snout.y + (tip.y - snout.y) * t)
        ctx.stroke(
            line(CGPoint(x: at.x - cell * 0.02, y: at.y - cell * 0.012), CGPoint(x: at.x + cell * 0.02, y: at.y + cell * 0.012)),
            with: .color(Color(hex: 0xD9CDA8)),
            style: stroke(cell * 0.016)
        )
    }
    // Face.
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.17, y: c.y - cell * 0.05), cell * 0.032), with: .color(ink))
    ctx.stroke(
        ovalArc(CGPoint(x: c.x + cell * 0.16, y: c.y + cell * 0.01), CGSize(width: cell * 0.12, height: cell * 0.08), start: 20, sweep: 120, useCenter: false),
        with: .color(ink.opacity(0.55)),
        style: stroke(cell * 0.02, cap: .round)
    )
}

nonisolated private func drawBeaver(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let fur = bodyTint(palette, color, Color(hex: 0x9A6B3F))
    let dark = fur.shaded(0.75)
    let muzzle = fur.lightened(1.3)
    // Flat cross-hatched tail sweeping back-left.
    var tailCtx = rotated(ctx, degrees: -28, pivot: CGPoint(x: c.x - cell * 0.30, y: c.y + cell * 0.10))
    tailCtx.fill(
        Path(roundedRect: CGRect(x: c.x - cell * 0.52, y: c.y + cell * 0.02, width: cell * 0.30, height: cell * 0.17), cornerRadius: cell * 0.08),
        with: .color(dark)
    )
    for i in 0...2 {
        let x = c.x - cell * 0.48 + CGFloat(i) * cell * 0.08
        tailCtx.stroke(
            line(CGPoint(x: x, y: c.y + cell * 0.03), CGPoint(x: x + cell * 0.05, y: c.y + cell * 0.18)),
            with: .color(dark.shaded(0.8)),
            style: stroke(cell * 0.014)
        )
    }
    // Chubby body.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.10), CGSize(width: cell * 0.58, height: cell * 0.40)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.14), CGSize(width: cell * 0.58, height: cell * 0.40)), with: .color(fur))
    // Head with round ears.
    let head = CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.20)
    for dx in [-1.0, 1.0] {
        ctx.fill(circle(CGPoint(x: head.x + dx * cell * 0.10, y: head.y - cell * 0.115), cell * 0.05), with: .color(fur))
        ctx.fill(circle(CGPoint(x: head.x + dx * cell * 0.10, y: head.y - cell * 0.115), cell * 0.025), with: .color(dark))
    }
    ctx.fill(circle(head, cell * 0.155), with: .color(fur))
    // Muzzle, nose, and the trademark buck teeth.
    ctx.fill(oval(CGPoint(x: head.x - cell * 0.075, y: head.y - cell * 0.01), CGSize(width: cell * 0.15, height: cell * 0.12)), with: .color(muzzle))
    ctx.fill(circle(CGPoint(x: head.x, y: head.y + cell * 0.015), cell * 0.032), with: .color(Color(hex: 0x3A2A1C)))
    for dx in [-1.0, 1.0] {
        ctx.fill(
            Path(roundedRect: CGRect(
                x: head.x + dx * cell * 0.026 - cell * 0.022,
                y: head.y + cell * 0.065,
                width: cell * 0.044,
                height: cell * 0.06
            ), cornerRadius: cell * 0.012),
            with: .color(Color(hex: 0xFFF8E7))
        )
    }
    for dx in [-1.0, 1.0] {
        ctx.fill(circle(CGPoint(x: head.x + dx * cell * 0.07, y: head.y - cell * 0.05), cell * 0.026), with: .color(ink))
    }
    // A freshly gnawed twig hugged to the chest.
    let twig = Color(hex: 0x7A5230)
    ctx.stroke(
        line(CGPoint(x: c.x - cell * 0.06, y: c.y + cell * 0.16), CGPoint(x: c.x + cell * 0.26, y: c.y + cell * 0.04)),
        with: .color(twig),
        style: stroke(cell * 0.045, cap: .round)
    )
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.26, y: c.y + cell * 0.04), cell * 0.026), with: .color(Color(hex: 0xC9A876)))
}

// MARK: - Pads

nonisolated private func drawLilyPad(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let radius = cell * 0.38
    // The notch toward the top-right is cut out of the leaf, not painted over
    // it, so whatever is underneath shows through - board water or the home
    // pond gradient - and nothing flickers while the pad bobs.
    func leaf(_ at: CGPoint) -> Path {
        let disc = circle(at, radius)
        let notch = polygon([
            at,
            CGPoint(x: at.x + radius * 1.15, y: at.y - radius * 0.75),
            CGPoint(x: at.x + radius * 0.55, y: at.y - radius * 1.15),
        ])
        return disc.subtracting(notch)
    }
    ctx.fill(leaf(CGPoint(x: c.x, y: c.y + cell * 0.03)), with: .color(palette.padDark))
    ctx.fill(leaf(c), with: .color(palette.pad))
    ctx.stroke(
        circle(CGPoint(x: c.x - radius * 0.2, y: c.y + radius * 0.15), radius * 0.45),
        with: .color(palette.padDark.opacity(0.6)),
        style: stroke(cell * 0.035)
    )
}

nonisolated private func drawLotusPad(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    // Leaf underneath.
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.03), cell * 0.40), with: .color(palette.padDark))
    ctx.fill(circle(c, cell * 0.40), with: .color(palette.pad))
    // Outer petals.
    for i in 0..<6 {
        let rc = rotated(ctx, degrees: CGFloat(i) * 60 + 15, pivot: c)
        rc.fill(oval(CGPoint(x: c.x - cell * 0.055, y: c.y - cell * 0.31), CGSize(width: cell * 0.11, height: cell * 0.27)), with: .color(Color(hex: 0xF48FB6)))
    }
    // Inner petals.
    for i in 0..<6 {
        let rc = rotated(ctx, degrees: CGFloat(i) * 60 - 15, pivot: c)
        rc.fill(oval(CGPoint(x: c.x - cell * 0.05, y: c.y - cell * 0.24), CGSize(width: cell * 0.10, height: cell * 0.21)), with: .color(Color(hex: 0xFFB9D4)))
    }
    // Golden heart.
    ctx.fill(circle(c, cell * 0.075), with: .color(Color(hex: 0xFFE082)))
}

nonisolated private func drawIcePad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let ice = Color(hex: 0xEAF7FF)
    let iceShade = Color(hex: 0xB5DCF0)
    func floe(_ at: CGPoint) -> Path {
        // A slightly irregular hexagon reads as a floe, not a wheel.
        var path = Path()
        for k in 0..<6 {
            let angle = (Double(k) * 60 - 22) * .pi / 180
            let r = cell * (k % 2 == 0 ? 0.42 : 0.36)
            let p = CGPoint(x: at.x + cos(angle) * r, y: at.y + sin(angle) * r)
            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
    ctx.fill(floe(CGPoint(x: c.x, y: c.y + cell * 0.035)), with: .color(iceShade))
    ctx.fill(floe(c), with: .color(ice))
    // Cracks.
    ctx.stroke(line(CGPoint(x: c.x - cell * 0.16, y: c.y - cell * 0.06), CGPoint(x: c.x + cell * 0.02, y: c.y + cell * 0.04)), with: .color(iceShade), style: stroke(cell * 0.022))
    ctx.stroke(line(CGPoint(x: c.x + cell * 0.02, y: c.y + cell * 0.04), CGPoint(x: c.x + cell * 0.18, y: c.y - cell * 0.02)), with: .color(iceShade), style: stroke(cell * 0.022))
    // Sparkle.
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.10, y: c.y - cell * 0.16), cell * 0.045), with: .color(.white))
}

nonisolated private func drawStarlightPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let gold = Color(hex: 0xFFD76E)
    // Soft glow, base, then a five-point star.
    ctx.fill(circle(c, cell * 0.47), with: .color(gold.opacity(0.28)))
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.03), cell * 0.37), with: .color(Color(hex: 0xB8862E)))
    ctx.fill(circle(c, cell * 0.37), with: .color(gold))
    var star = Path()
    for k in 0..<10 {
        let angle = (Double(k) * 36 - 90) * .pi / 180
        let r = cell * (k % 2 == 0 ? 0.26 : 0.11)
        let p = CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r)
        if k == 0 { star.move(to: p) } else { star.addLine(to: p) }
    }
    star.closeSubpath()
    ctx.fill(star, with: .color(Color(hex: 0xFFF6DA)))
}

nonisolated private func drawShellPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let shell = Color(hex: 0xF7CBA8)
    let shellDeep = Color(hex: 0xDB9E72)
    let hinge = CGPoint(x: c.x, y: c.y + cell * 0.30)
    // Scallop fan: shaded base, lighter top, ribs meeting at the hinge.
    ctx.fill(
        ovalArc(CGPoint(x: hinge.x - cell * 0.40, y: hinge.y - cell * 0.37), CGSize(width: cell * 0.80, height: cell * 0.74), start: 180, sweep: 180, useCenter: true),
        with: .color(shellDeep)
    )
    ctx.fill(
        ovalArc(CGPoint(x: hinge.x - cell * 0.36, y: hinge.y - cell * 0.33), CGSize(width: cell * 0.72, height: cell * 0.66), start: 180, sweep: 180, useCenter: true),
        with: .color(shell)
    )
    for i in 0...4 {
        let angle = (200.0 + Double(i) * 35) * .pi / 180
        let tip = CGPoint(x: hinge.x + cos(angle) * cell * 0.34, y: hinge.y + sin(angle) * cell * 0.32)
        ctx.stroke(line(hinge, tip), with: .color(shellDeep.opacity(0.7)), style: stroke(cell * 0.025, cap: .round))
    }
    // Pearl.
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.06), cell * 0.075), with: .color(Color(hex: 0xFDF3F8)))
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.025, y: c.y + cell * 0.035), cell * 0.028), with: .color(.white))
}

nonisolated private func drawRainbowPad(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    // Leaf base so it still reads as a dock.
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.03), cell * 0.38), with: .color(palette.padDark))
    ctx.fill(circle(c, cell * 0.38), with: .color(palette.pad))
    // Concentric rainbow rings.
    let colors: [Color] = [
        Color(hex: 0xFF6B6B), Color(hex: 0xFFB84D), Color(hex: 0xFFE14D),
        Color(hex: 0x6FDD8B), Color(hex: 0x6FB9FF), Color(hex: 0xB48BE8),
    ]
    for (i, ring) in colors.enumerated() {
        ctx.stroke(circle(c, cell * (0.33 - CGFloat(i) * 0.045)), with: .color(ring), style: stroke(cell * 0.038))
    }
    ctx.fill(circle(c, cell * 0.05), with: .color(.white.opacity(0.85)))
}

nonisolated private func drawSunflowerPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let petal = Color(hex: 0xFFC53D)
    let petalDeep = Color(hex: 0xEF9F26)
    // Two rings of petals, the back ring darker and offset for depth.
    for i in 0..<12 {
        let rc = rotated(ctx, degrees: CGFloat(i) * 30 + 15, pivot: c)
        rc.fill(oval(CGPoint(x: c.x - cell * 0.055, y: c.y - cell * 0.43), CGSize(width: cell * 0.11, height: cell * 0.26)), with: .color(petalDeep))
    }
    for i in 0..<12 {
        let rc = rotated(ctx, degrees: CGFloat(i) * 30, pivot: c)
        rc.fill(oval(CGPoint(x: c.x - cell * 0.06, y: c.y - cell * 0.45), CGSize(width: cell * 0.12, height: cell * 0.30)), with: .color(petal))
    }
    // Seed head with a sunflower spiral of seeds.
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.015), cell * 0.225), with: .color(Color(hex: 0x5C3A1E)))
    ctx.fill(circle(c, cell * 0.215), with: .color(Color(hex: 0x6E4526)))
    for k in 0..<12 {
        let angle = Double(k) * 137.5 * .pi / 180
        let r = cell * 0.045 + CGFloat(k) * cell * 0.0125
        ctx.fill(circle(CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r), cell * 0.019), with: .color(Color(hex: 0x8F5E33)))
    }
    ctx.fill(circle(c, cell * 0.035), with: .color(Color(hex: 0xA9743F)))
}

nonisolated private func drawCloverPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let green = Color(hex: 0x4CBB5E)
    let greenDeep = Color(hex: 0x37944A)
    let greenLight = Color(hex: 0x6FD37F)
    // Four heart-shaped leaflets - each is two lobes and a wedge to the middle.
    for i in 0..<4 {
        let rc = rotated(ctx, degrees: CGFloat(i) * 90 + 45, pivot: c)
        let leafletCenter = CGPoint(x: c.x, y: c.y - cell * 0.235)
        rc.fill(circle(CGPoint(x: leafletCenter.x - cell * 0.085, y: leafletCenter.y + cell * 0.02), cell * 0.135), with: .color(greenDeep))
        rc.fill(circle(CGPoint(x: leafletCenter.x + cell * 0.085, y: leafletCenter.y + cell * 0.02), cell * 0.135), with: .color(greenDeep))
        rc.fill(circle(CGPoint(x: leafletCenter.x - cell * 0.08, y: leafletCenter.y), cell * 0.13), with: .color(green))
        rc.fill(circle(CGPoint(x: leafletCenter.x + cell * 0.08, y: leafletCenter.y), cell * 0.13), with: .color(green))
        rc.fill(polygon([
            CGPoint(x: leafletCenter.x - cell * 0.11, y: leafletCenter.y + cell * 0.055),
            c,
            CGPoint(x: leafletCenter.x + cell * 0.11, y: leafletCenter.y + cell * 0.055),
        ]), with: .color(green))
        // Center vein of the leaflet.
        rc.stroke(
            line(CGPoint(x: c.x, y: c.y - cell * 0.09), CGPoint(x: leafletCenter.x, y: leafletCenter.y - cell * 0.09)),
            with: .color(greenLight.opacity(0.8)),
            style: stroke(cell * 0.018, cap: .round)
        )
    }
    // Dew drop for luck.
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.14, y: c.y - cell * 0.17), cell * 0.045), with: .color(.white.opacity(0.75)))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.125, y: c.y - cell * 0.185), cell * 0.018), with: .color(.white))
}

nonisolated private func drawGemPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let gem = Color(hex: 0x3ED8C3)
    let gemDeep = Color(hex: 0x1FA394)
    let gemLight = Color(hex: 0x9FF4E7)
    func hex(_ at: CGPoint, _ radius: CGFloat) -> Path {
        var path = Path()
        for k in 0..<6 {
            let angle = (Double(k) * 60 - 90) * .pi / 180
            let p = CGPoint(x: at.x + cos(angle) * radius, y: at.y + sin(angle) * radius)
            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
    // Cool glow, cut hexagon, then facet lines meeting the table.
    ctx.fill(circle(c, cell * 0.47), with: .color(gem.opacity(0.22)))
    ctx.fill(hex(CGPoint(x: c.x, y: c.y + cell * 0.035), cell * 0.40), with: .color(gemDeep))
    ctx.fill(hex(c, cell * 0.40), with: .color(gem))
    ctx.fill(hex(c, cell * 0.20), with: .color(gemLight))
    for k in 0..<6 {
        let angle = (Double(k) * 60 - 90) * .pi / 180
        ctx.stroke(
            line(
                CGPoint(x: c.x + cos(angle) * cell * 0.20, y: c.y + sin(angle) * cell * 0.20),
                CGPoint(x: c.x + cos(angle) * cell * 0.40, y: c.y + sin(angle) * cell * 0.40)
            ),
            with: .color(gemDeep.opacity(0.75)),
            style: stroke(cell * 0.02)
        )
    }
    // Sparkle.
    let at = CGPoint(x: c.x - cell * 0.10, y: c.y - cell * 0.13)
    ctx.stroke(line(CGPoint(x: at.x - cell * 0.055, y: at.y), CGPoint(x: at.x + cell * 0.055, y: at.y)), with: .color(.white), style: stroke(cell * 0.022, cap: .round))
    ctx.stroke(line(CGPoint(x: at.x, y: at.y - cell * 0.055), CGPoint(x: at.x, y: at.y + cell * 0.055)), with: .color(.white), style: stroke(cell * 0.022, cap: .round))
}

nonisolated private func drawHoneyPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let comb = Color(hex: 0xF2B234)
    let combDeep = Color(hex: 0xC98A18)
    let honey = Color(hex: 0xFFD968)
    func hex(_ at: CGPoint, _ radius: CGFloat) -> Path {
        var path = Path()
        for k in 0..<6 {
            let angle = Double(k) * 60 * .pi / 180
            let p = CGPoint(x: at.x + cos(angle) * radius, y: at.y + sin(angle) * radius)
            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
    // The comb tile with its shadow.
    ctx.fill(hex(CGPoint(x: c.x, y: c.y + cell * 0.035), cell * 0.42), with: .color(combDeep))
    ctx.fill(hex(c, cell * 0.42), with: .color(comb))
    // Seven cells: one in the middle, six around it.
    ctx.stroke(hex(c, cell * 0.115), with: .color(combDeep), style: stroke(cell * 0.025))
    for k in 0..<6 {
        let angle = (Double(k) * 60 + 30) * .pi / 180
        let at = CGPoint(x: c.x + cos(angle) * cell * 0.22, y: c.y + sin(angle) * cell * 0.22)
        ctx.stroke(hex(at, cell * 0.115), with: .color(combDeep), style: stroke(cell * 0.025))
    }
    // Two cells brimming with honey, plus a glossy drip.
    ctx.fill(circle(c, cell * 0.075), with: .color(honey))
    let filledAngle = 30.0 * .pi / 180
    let filled = CGPoint(x: c.x + cos(filledAngle) * cell * 0.22, y: c.y + sin(filledAngle) * cell * 0.22)
    ctx.fill(circle(filled, cell * 0.075), with: .color(honey))
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.025, y: c.y - cell * 0.025), cell * 0.022), with: .color(.white.opacity(0.6)))
    ctx.fill(circle(CGPoint(x: filled.x - cell * 0.025, y: filled.y - cell * 0.025), cell * 0.022), with: .color(.white.opacity(0.6)))
}

nonisolated private func drawMoonPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let moon = Color(hex: 0xE3ECF7)
    let moonShade = Color(hex: 0xA9BCD3)
    let crater = Color(hex: 0xBFCFE1)
    // Silver halo, shaded base, then the moon face.
    ctx.fill(circle(c, cell * 0.47), with: .color(moon.opacity(0.25)))
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.03), cell * 0.375), with: .color(moonShade))
    ctx.fill(circle(c, cell * 0.375), with: .color(moon))
    // Craters of different sizes, each with a rim shadow.
    for (dx, dy, r) in [
        (-0.13, -0.10, 0.085),
        (0.13, 0.02, 0.06),
        (-0.02, 0.17, 0.05),
        (0.08, -0.20, 0.04),
    ] {
        let at = CGPoint(x: c.x + cell * dx, y: c.y + cell * dy)
        ctx.fill(circle(at, cell * r), with: .color(crater))
        ctx.stroke(circle(at, cell * r), with: .color(moonShade.opacity(0.7)), style: stroke(cell * 0.014))
    }
    // Two tiny companion stars.
    for (dx, dy) in [(-0.36, -0.30), (0.38, 0.24)] {
        let at = CGPoint(x: c.x + cell * dx, y: c.y + cell * dy)
        ctx.stroke(line(CGPoint(x: at.x - cell * 0.035, y: at.y), CGPoint(x: at.x + cell * 0.035, y: at.y)), with: .color(.white), style: stroke(cell * 0.018, cap: .round))
        ctx.stroke(line(CGPoint(x: at.x, y: at.y - cell * 0.035), CGPoint(x: at.x, y: at.y + cell * 0.035)), with: .color(.white), style: stroke(cell * 0.018, cap: .round))
    }
}

nonisolated private func drawCrownPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let velvet = Color(hex: 0x8E2F47)
    let velvetDeep = Color(hex: 0x6E2136)
    let gold = Color(hex: 0xF2C94C)
    let goldDeep = Color(hex: 0xC79A2A)
    // Velvet cushion with a golden trim.
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.03), cell * 0.40), with: .color(velvetDeep))
    ctx.fill(circle(c, cell * 0.40), with: .color(velvet))
    ctx.stroke(circle(c, cell * 0.40), with: .color(gold), style: stroke(cell * 0.035))
    // The crown: band, three points with a pearl on each tip.
    let bandTop = c.y + cell * 0.06
    ctx.fill(
        Path(roundedRect: CGRect(x: c.x - cell * 0.22, y: bandTop + cell * 0.02, width: cell * 0.44, height: cell * 0.12), cornerRadius: cell * 0.03),
        with: .color(goldDeep)
    )
    ctx.fill(
        Path(roundedRect: CGRect(x: c.x - cell * 0.22, y: bandTop, width: cell * 0.44, height: cell * 0.12), cornerRadius: cell * 0.03),
        with: .color(gold)
    )
    ctx.fill(polygon([
        CGPoint(x: c.x - cell * 0.22, y: bandTop),
        CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.20),
        CGPoint(x: c.x - cell * 0.11, y: bandTop - cell * 0.055),
        CGPoint(x: c.x, y: c.y - cell * 0.26),
        CGPoint(x: c.x + cell * 0.11, y: bandTop - cell * 0.055),
        CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.20),
        CGPoint(x: c.x + cell * 0.22, y: bandTop),
    ]), with: .color(gold))
    for (dx, dy) in [(-0.22, -0.20), (0.0, -0.26), (0.22, -0.20)] {
        ctx.fill(circle(CGPoint(x: c.x + cell * dx, y: c.y + cell * dy), cell * 0.032), with: .color(Color(hex: 0xFDF3F8)))
    }
    // A ruby set in the band.
    ctx.fill(circle(CGPoint(x: c.x, y: bandTop + cell * 0.06), cell * 0.042), with: .color(Color(hex: 0xE84560)))
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.015, y: bandTop + cell * 0.045), cell * 0.015), with: .color(.white.opacity(0.7)))
}

nonisolated private func drawAuroraPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let night = Color(hex: 0x232B5C)
    let nightDeep = Color(hex: 0x181E44)
    // Polar night disc.
    ctx.fill(circle(CGPoint(x: c.x, y: c.y + cell * 0.03), cell * 0.40), with: .color(nightDeep))
    ctx.fill(circle(c, cell * 0.40), with: .color(night))
    // Three aurora ribbons waving across the sky.
    let ribbons: [(Color, CGFloat)] = [
        (Color(hex: 0x5CE8A4), -0.14),
        (Color(hex: 0x63C7FF), 0.0),
        (Color(hex: 0xB388FF), 0.14),
    ]
    for (tint, dy) in ribbons {
        var ribbon = Path()
        ribbon.move(to: CGPoint(x: c.x - cell * 0.30, y: c.y + cell * (dy + 0.06)))
        ribbon.addCurve(
            to: CGPoint(x: c.x + cell * 0.30, y: c.y + cell * (dy - 0.05)),
            control1: CGPoint(x: c.x - cell * 0.10, y: c.y + cell * (dy - 0.14)),
            control2: CGPoint(x: c.x + cell * 0.10, y: c.y + cell * (dy + 0.16))
        )
        ctx.stroke(ribbon, with: .color(tint.opacity(0.9)), style: stroke(cell * 0.075, cap: .round))
    }
    // Scattered stars.
    for (dx, dy) in [(-0.22, -0.26), (0.24, -0.22), (0.05, 0.28), (-0.28, 0.18)] {
        ctx.fill(circle(CGPoint(x: c.x + cell * dx, y: c.y + cell * dy), cell * 0.018), with: .color(.white.opacity(0.9)))
    }
}

// MARK: - Board tiles (rim, current, rock)

nonisolated func drawWaterRim(
    _ ctx: inout GraphicsContext, pos: Pos, rect: CGRect, palette: PondPalette,
    isBank: (Pos) -> Bool
) {
    let strokeWidth = rect.width * 0.07
    let rim = palette.waterRim.opacity(0.75)
    if isBank(Pos(x: pos.x, y: pos.y - 1)) {
        ctx.stroke(line(CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY)), with: .color(rim), style: stroke(strokeWidth))
    }
    if isBank(Pos(x: pos.x, y: pos.y + 1)) {
        ctx.stroke(line(CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY)), with: .color(rim), style: stroke(strokeWidth))
    }
    if isBank(Pos(x: pos.x - 1, y: pos.y)) {
        ctx.stroke(line(CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.minX, y: rect.maxY)), with: .color(rim), style: stroke(strokeWidth))
    }
    if isBank(Pos(x: pos.x + 1, y: pos.y)) {
        ctx.stroke(line(CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.maxY)), with: .color(rim), style: stroke(strokeWidth))
    }
}

nonisolated func drawCurrent(_ ctx: inout GraphicsContext, rect: CGRect, dir: Dir, phase: CGFloat, palette: PondPalette) {
    let cell = rect.width
    let shift = (phase - 0.5) * cell * 0.22
    let center = CGPoint(x: rect.midX + CGFloat(dir.dx) * shift, y: rect.midY + CGFloat(dir.dy) * shift)
    let alpha = 0.3 + 0.25 * max(sin(phase * 2 * .pi), 0)
    let ahead = CGVector(dx: CGFloat(dir.dx) * cell * 0.18, dy: CGFloat(dir.dy) * cell * 0.18)
    let side = CGVector(dx: CGFloat(dir.dy) * cell * 0.16, dy: CGFloat(dir.dx) * cell * 0.16)
    for i in [-1.0, 0.0] {
        let tip = CGPoint(x: center.x + ahead.dx * (1 + i * 1.4), y: center.y + ahead.dy * (1 + i * 1.4))
        var path = Path()
        path.move(to: CGPoint(x: tip.x - ahead.dx - side.dx, y: tip.y - ahead.dy - side.dy))
        path.addLine(to: tip)
        path.addLine(to: CGPoint(x: tip.x - ahead.dx + side.dx, y: tip.y - ahead.dy + side.dy))
        ctx.stroke(path, with: .color(palette.current.opacity(alpha)), style: stroke(cell * 0.09))
    }
}

nonisolated func drawRock(_ ctx: inout GraphicsContext, rect: CGRect, palette: PondPalette) {
    let cell = rect.width
    let inset = cell * 0.08
    ctx.fill(
        Path(roundedRect: CGRect(x: rect.minX + inset, y: rect.minY + inset * 1.6, width: cell - inset * 2, height: cell - inset * 2), cornerRadius: cell * 0.32),
        with: .color(palette.rockDark)
    )
    ctx.fill(
        Path(roundedRect: CGRect(x: rect.minX + inset, y: rect.minY + inset, width: cell - inset * 2, height: cell - inset * 2.4), cornerRadius: cell * 0.32),
        with: .color(palette.rock)
    )
    ctx.fill(
        circle(CGPoint(x: rect.midX - cell * 0.15, y: rect.midY - cell * 0.18), cell * 0.09),
        with: .color(.white.opacity(0.18))
    )
}


/// A fluffy hatchling: rounder and smaller than the duckling, with down tufts.
nonisolated private func drawGosling(
    _ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?
) {
    let cell = rect.width
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let down = bodyTint(palette, color, Color(hex: 0xFFE08A))
    let dark = down.shaded(0.86)
    // Body: one soft ball with a smaller head, so it reads as a baby.
    ctx.fill(circle(CGPoint(x: center.x - cell * 0.05, y: center.y + cell * 0.07), cell * 0.25), with: .color(dark))
    let belly = CGPoint(x: center.x - cell * 0.05, y: center.y + cell * 0.04)
    ctx.fill(circle(belly, cell * 0.25), with: .color(down))
    // Down tufts around the back.
    for i in 0..<5 {
        let angle = (110 + Double(i) * 35) * .pi / 180
        let at = CGPoint(x: belly.x + cos(angle) * cell * 0.25, y: belly.y + sin(angle) * cell * 0.25)
        ctx.fill(circle(at, cell * 0.045), with: .color(down))
    }
    let head = CGPoint(x: center.x + cell * 0.13, y: center.y - cell * 0.16)
    ctx.fill(circle(head, cell * 0.155), with: .color(down))
    // Two tiny head feathers.
    for dx in [-0.03, 0.03] as [CGFloat] {
        ctx.stroke(
            line(
                CGPoint(x: head.x + cell * dx, y: head.y - cell * 0.13),
                CGPoint(x: head.x + cell * dx * 2.5, y: head.y - cell * 0.24)
            ),
            with: .color(dark),
            style: StrokeStyle(lineWidth: cell * 0.022, lineCap: .round)
        )
    }
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.12, y: head.y - cell * 0.04),
            CGPoint(x: head.x + cell * 0.26, y: head.y + cell * 0.01),
            CGPoint(x: head.x + cell * 0.12, y: head.y + cell * 0.07),
        ]),
        with: .color(palette.beak)
    )
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.035), cell * 0.032), with: .color(ink))
}

/// The golden lily: the plain pad's silhouette in gold, with a prize twinkle.
nonisolated private func drawGoldenLilyPad(_ ctx: inout GraphicsContext, _ rect: CGRect) {
    let cell = rect.width
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = cell * 0.38
    let gold = Color(hex: 0xFFD24A)
    let deepGold = Color(hex: 0xC7920F)

    func leaf(_ at: CGPoint) -> Path {
        let disc = circle(at, radius)
        let notch = polygon([
            at,
            CGPoint(x: at.x + radius * 1.15, y: at.y - radius * 0.75),
            CGPoint(x: at.x + radius * 0.55, y: at.y - radius * 1.15),
        ])
        return disc.subtracting(notch)
    }
    ctx.fill(leaf(CGPoint(x: center.x, y: center.y + cell * 0.03)), with: .color(deepGold))
    ctx.fill(leaf(center), with: .color(gold))
    // Veins radiating from the notch.
    for i in 0..<5 {
        let angle = (140 + Double(i) * 42) * .pi / 180
        ctx.stroke(
            line(center, CGPoint(x: center.x + cos(angle) * radius * 0.9, y: center.y + sin(angle) * radius * 0.9)),
            with: .color(deepGold.opacity(0.55)),
            style: StrokeStyle(lineWidth: cell * 0.025, lineCap: .round)
        )
    }
    // A four-point twinkle so the pad reads as a prize.
    let twinkle = CGPoint(x: center.x - radius * 0.35, y: center.y - radius * 0.3)
    let arm = cell * 0.12
    for rotation in [0.0, 90.0] as [CGFloat] {
        let rc = rotated(ctx, degrees: rotation, pivot: twinkle)
        rc.stroke(
            line(CGPoint(x: twinkle.x - arm, y: twinkle.y), CGPoint(x: twinkle.x + arm, y: twinkle.y)),
            with: .color(Color(hex: 0xFFF7D6)),
            style: StrokeStyle(lineWidth: cell * 0.03, lineCap: .round)
        )
    }
}
