//
//  PondArt.swift
//  PondPulse
//
//  The pond's scenery - a 1:1 port of the Android ui/PondArt.kt: the sixteen
//  decorations it sells, the six skies, and the basin they all sit in.
//
//  Everything here is drawn from the equipped theme's palette rather than from
//  fixed colours, so a decoration bought on the dusk pond still belongs on the
//  sakura one. The one exception is the lantern's flame, which has to stay warm
//  to read as a flame at all.
//
//  Compose's DrawScope knows its own size; GraphicsContext does not, so the
//  functions that filled the whole canvas take an explicit `size`.
//

import SwiftUI

// MARK: - Decorations

/// One decoration, sized to `rect` and bobbing by whatever the caller passes.
nonisolated func drawDecor(_ ctx: inout GraphicsContext, id: String, rect: CGRect, palette: PondPalette, phase: CGFloat) {
    switch id {
    case "reeds": drawReeds(&ctx, rect, palette, phase)
    case "flowers": drawFlowers(&ctx, rect, palette, phase)
    case "rock": drawMossyRock(&ctx, rect, palette)
    case "log": drawLog(&ctx, rect, palette)
    case "dock": drawDock(&ctx, rect, palette)
    case "lantern": drawFloatingLantern(&ctx, rect, palette, phase)
    case "spring": drawSpring(&ctx, rect, palette, phase)
    case "lilies": drawLilies(&ctx, rect, palette, phase)
    case "stones": drawSteppingStones(&ctx, rect, palette)
    case "boat": drawRowBoat(&ctx, rect, palette, phase)
    case "buoy": drawBuoy(&ctx, rect, palette, phase)
    case "bench": drawBench(&ctx, rect, palette)
    case "willow": drawWillow(&ctx, rect, palette, phase)
    case "birdhouse": drawBirdhouse(&ctx, rect, palette)
    case "toadstools": drawToadstools(&ctx, rect, palette)
    case "fence": drawFence(&ctx, rect, palette)
    // The second shelf lives in PondArtMore.swift.
    default: drawDecorMore(&ctx, id, rect, palette, phase)
    }
}

/// A raft of lily pads with one flower open on it.
nonisolated private func drawLilies(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let r = rect.width * 0.19
    let spots: [(CGPoint, CGFloat)] = [
        (CGPoint(x: -0.28, y: -0.10), 1.0),
        (CGPoint(x: 0.10, y: 0.16), 1.15),
        (CGPoint(x: 0.32, y: -0.18), 0.85),
    ]
    for (spot, scale) in spots {
        let at = CGPoint(
            x: rect.midX + spot.x * rect.width,
            y: rect.midY + spot.y * rect.height + sin(phase * 0.9 + spot.x * 8) * r * 0.10
        )
        ctx.fill(circle(CGPoint(x: at.x, y: at.y + r * 0.16), r * scale), with: .color(palette.padDark.opacity(0.45)))
        ctx.fill(circle(at, r * scale), with: .color(palette.pad))
        // The notch every lily pad has, cut with the water behind it.
        ctx.fill(
            ovalArc(
                CGPoint(x: at.x - r * scale, y: at.y - r * scale),
                CGSize(width: r * scale * 2, height: r * scale * 2),
                start: -24, sweep: 48, useCenter: true
            ),
            with: .color(palette.waterDeep.opacity(0.35))
        )
    }
    let bloom = CGPoint(x: rect.midX + 0.10 * rect.width, y: rect.midY + 0.16 * rect.height)
    for petal in 0..<8 {
        let a = CGFloat(petal) / 8 * 2 * .pi
        ctx.fill(
            circle(CGPoint(x: bloom.x + cos(a) * r * 0.28, y: bloom.y + sin(a) * r * 0.28), r * 0.20),
            with: .color(Color(hex: 0xF3C9DF))
        )
    }
    ctx.fill(circle(bloom, r * 0.20), with: .color(palette.star))
}

/// Three flat stones you could cross on, half sunk.
nonisolated private func drawSteppingStones(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let n = 3
    for i in 0..<n {
        let t = (CGFloat(i) + 0.5) / CGFloat(n)
        let at = CGPoint(
            x: rect.minX + rect.width * t,
            y: rect.midY + (i % 2 == 0 ? -1 : 1) * rect.height * 0.12
        )
        let w = rect.width * (0.30 - CGFloat(i) * 0.02)
        ctx.fill(
            oval(CGPoint(x: at.x - w / 2, y: at.y - w * 0.24 + w * 0.10), CGSize(width: w, height: w * 0.52)),
            with: .color(palette.waterDeep.opacity(0.40))
        )
        ctx.fill(
            oval(CGPoint(x: at.x - w / 2, y: at.y - w * 0.28), CGSize(width: w, height: w * 0.52)),
            with: .color(palette.rock)
        )
        ctx.fill(
            oval(CGPoint(x: at.x - w * 0.34, y: at.y - w * 0.20), CGSize(width: w * 0.44, height: w * 0.20)),
            with: .color(palette.rockDark.opacity(0.55))
        )
    }
}

/// A little rowboat with two oars shipped.
nonisolated private func drawRowBoat(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let w = rect.width
    let tilt = sin(phase * 0.8) * 0.035
    let cy = rect.midY + sin(phase * 0.9) * rect.height * 0.03
    var hull = Path()
    hull.move(to: CGPoint(x: rect.minX + w * 0.04, y: cy - w * 0.10))
    hull.addQuadCurve(
        to: CGPoint(x: rect.maxX - w * 0.04, y: cy - w * 0.10),
        control: CGPoint(x: rect.midX, y: cy + w * 0.26 + tilt * w)
    )
    hull.closeSubpath()
    ctx.fill(hull, with: .color(palette.waterDeep.opacity(0.35)))
    var lifted = ctx
    lifted.translateBy(x: 0, y: -w * 0.02)
    lifted.fill(hull, with: .color(Color(hex: 0x9E6B45)))
    ctx.stroke(
        line(CGPoint(x: rect.minX + w * 0.04, y: cy - w * 0.11), CGPoint(x: rect.maxX - w * 0.04, y: cy - w * 0.11)),
        with: .color(Color(hex: 0xC79268)),
        style: stroke(w * 0.055)
    )
    // Two thwarts and a pair of oars laid across them.
    for t in [0.35, 0.62] as [CGFloat] {
        ctx.stroke(
            line(CGPoint(x: rect.minX + w * t, y: cy - w * 0.08), CGPoint(x: rect.minX + w * t, y: cy + w * 0.05)),
            with: .color(Color(hex: 0x7C5233)),
            style: stroke(w * 0.03)
        )
    }
    ctx.stroke(
        line(CGPoint(x: rect.minX + w * 0.16, y: cy + w * 0.02), CGPoint(x: rect.maxX - w * 0.12, y: cy - w * 0.06)),
        with: .color(Color(hex: 0xD8B48C)),
        style: stroke(w * 0.022)
    )
}

/// A moored marker buoy, bobbing.
nonisolated private func drawBuoy(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let r = rect.width * 0.30
    let at = CGPoint(x: rect.midX, y: rect.midY + sin(phase * 1.6) * r * 0.22)
    ctx.fill(
        oval(CGPoint(x: at.x - r * 1.05, y: at.y + r * 0.30), CGSize(width: r * 2.1, height: r * 0.60)),
        with: .color(palette.waterDeep.opacity(0.35))
    )
    ctx.fill(circle(at, r), with: .color(Color(hex: 0xE45C5C)))
    ctx.fill(
        ovalArc(CGPoint(x: at.x - r, y: at.y - r), CGSize(width: r * 2, height: r * 2),
                start: 180, sweep: 180, useCenter: true),
        with: .color(Color(hex: 0xFFF3E0))
    )
    ctx.stroke(
        line(CGPoint(x: at.x, y: at.y - r), CGPoint(x: at.x, y: at.y - r * 1.7)),
        with: .color(palette.rockDark),
        style: stroke(r * 0.14)
    )
    ctx.fill(circle(CGPoint(x: at.x, y: at.y - r * 1.75), r * 0.20), with: .color(palette.star))
}

/// A park bench, side on.
nonisolated private func drawBench(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let w = rect.width
    let seatY = rect.midY + rect.height * 0.10
    let wood = Color(hex: 0xA9743F)
    let dark = Color(hex: 0x7B5228)
    for leg in [0.16, 0.84] as [CGFloat] {
        ctx.fill(
            Path(CGRect(x: rect.minX + w * leg - w * 0.035, y: seatY, width: w * 0.07, height: rect.height * 0.30)),
            with: .color(dark)
        )
    }
    ctx.fill(
        Path(CGRect(x: rect.minX + w * 0.08, y: seatY - w * 0.05, width: w * 0.84, height: w * 0.06)),
        with: .color(wood)
    )
    for slat in 0..<3 {
        ctx.fill(
            Path(CGRect(x: rect.minX + w * 0.10, y: seatY - w * (0.16 + CGFloat(slat) * 0.09),
                        width: w * 0.80, height: w * 0.055)),
            with: .color(slat == 1 ? dark : wood)
        )
    }
    for post in [0.12, 0.88] as [CGFloat] {
        ctx.fill(
            Path(CGRect(x: rect.minX + w * post - w * 0.025, y: seatY - w * 0.36,
                        width: w * 0.05, height: w * 0.36)),
            with: .color(dark)
        )
    }
}

/// A weeping willow: trunk, canopy, and strands that sway.
nonisolated private func drawWillow(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let w = rect.width
    let baseY = rect.maxY - rect.height * 0.06
    ctx.fill(
        Path(CGRect(x: rect.midX - w * 0.045, y: baseY - rect.height * 0.46,
                    width: w * 0.09, height: rect.height * 0.46)),
        with: .color(Color(hex: 0x6B4A2E))
    )
    let canopy = CGPoint(x: rect.midX, y: baseY - rect.height * 0.56)
    for blob in 0..<5 {
        let a = CGFloat(blob) / 5 * 2 * .pi
        ctx.fill(
            circle(CGPoint(x: canopy.x + cos(a) * w * 0.20, y: canopy.y + sin(a) * w * 0.10), w * 0.24),
            with: .color(palette.pad.blended(.black, 0.18))
        )
    }
    ctx.fill(circle(canopy, w * 0.24), with: .color(palette.pad))
    // The strands are what makes it a willow rather than a lollipop.
    for strand in 0..<9 {
        let t = CGFloat(strand) / 8
        let x = canopy.x + (t - 0.5) * w * 0.72
        let sway = sin(phase * 0.7 + CGFloat(strand)) * w * 0.035
        let wobble = sin(CGFloat(strand) * 1.7)
        let len = rect.height * (0.20 + 0.16 * wobble * wobble)
        var p = Path()
        p.move(to: CGPoint(x: x, y: canopy.y + w * 0.08))
        p.addQuadCurve(
            to: CGPoint(x: x + sway * 1.8, y: canopy.y + len),
            control: CGPoint(x: x + sway, y: canopy.y + len * 0.6)
        )
        ctx.stroke(p, with: .color(palette.pad.blended(palette.padDark, 0.35)), style: stroke(w * 0.022))
    }
}

/// A birdhouse on a post.
nonisolated private func drawBirdhouse(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let w = rect.width
    let boxTop = rect.minY + rect.height * 0.20
    let boxH = rect.height * 0.42
    ctx.fill(
        Path(CGRect(x: rect.midX - w * 0.05, y: boxTop + boxH, width: w * 0.10, height: rect.height * 0.38)),
        with: .color(Color(hex: 0x7B5228))
    )
    ctx.fill(
        Path(CGRect(x: rect.midX - w * 0.30, y: boxTop, width: w * 0.60, height: boxH)),
        with: .color(Color(hex: 0xE9DCC3))
    )
    ctx.fill(
        polygon([
            CGPoint(x: rect.midX - w * 0.38, y: boxTop),
            CGPoint(x: rect.midX, y: boxTop - rect.height * 0.18),
            CGPoint(x: rect.midX + w * 0.38, y: boxTop),
        ]),
        with: .color(Color(hex: 0xC0553F))
    )
    ctx.fill(circle(CGPoint(x: rect.midX, y: boxTop + boxH * 0.42), w * 0.11), with: .color(palette.rockDark))
    ctx.stroke(
        line(CGPoint(x: rect.midX, y: boxTop + boxH * 0.72), CGPoint(x: rect.midX, y: boxTop + boxH * 0.95)),
        with: .color(Color(hex: 0x7B5228)),
        style: stroke(w * 0.04)
    )
}

/// A clump of toadstools on the bank.
nonisolated private func drawToadstools(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let w = rect.width
    let caps: [(CGFloat, CGFloat, CGFloat)] = [(0.28, 0.72, 0.34), (0.58, 0.55, 0.44), (0.80, 0.78, 0.26)]
    for (fx, fy, scale) in caps {
        let at = CGPoint(x: rect.minX + w * fx, y: rect.minY + rect.height * fy)
        let capR = w * scale * 0.5
        ctx.fill(
            Path(CGRect(x: at.x - capR * 0.28, y: at.y, width: capR * 0.56, height: rect.height * 0.28)),
            with: .color(Color(hex: 0xF4EADB))
        )
        ctx.fill(
            ovalArc(CGPoint(x: at.x - capR, y: at.y - capR * 0.9), CGSize(width: capR * 2, height: capR * 1.8),
                    start: 180, sweep: 180, useCenter: true),
            with: .color(Color(hex: 0xD2504A))
        )
        ctx.fill(circle(CGPoint(x: at.x - capR * 0.34, y: at.y - capR * 0.34), capR * 0.16), with: .color(Color(hex: 0xFBEFE2)))
        ctx.fill(circle(CGPoint(x: at.x + capR * 0.36, y: at.y - capR * 0.26), capR * 0.12), with: .color(Color(hex: 0xFBEFE2)))
    }
}

/// A short run of picket fence.
nonisolated private func drawFence(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let w = rect.width
    let pickets = 6
    let top = rect.minY + rect.height * 0.24
    let bottom = rect.maxY - rect.height * 0.14
    let wood = Color(hex: 0xE4D7BC)
    let shade = Color(hex: 0xB9A582)
    for rail in [0.34, 0.68] as [CGFloat] {
        ctx.fill(
            Path(CGRect(x: rect.minX, y: top + (bottom - top) * rail, width: w, height: (bottom - top) * 0.11)),
            with: .color(shade)
        )
    }
    for i in 0..<pickets {
        let x = rect.minX + w * (CGFloat(i) + 0.5) / CGFloat(pickets)
        let pw = w / CGFloat(pickets) * 0.46
        ctx.fill(Path(CGRect(x: x - pw / 2, y: top, width: pw, height: bottom - top)), with: .color(wood))
        ctx.fill(
            polygon([
                CGPoint(x: x - pw / 2, y: top),
                CGPoint(x: x, y: top - (bottom - top) * 0.22),
                CGPoint(x: x + pw / 2, y: top),
            ]),
            with: .color(wood)
        )
    }
}

nonisolated private func drawReeds(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let stalks = 5
    for i in 0..<stalks {
        let x = rect.minX + rect.width * (0.15 + 0.18 * CGFloat(i))
        let height = rect.height * (0.55 + 0.11 * CGFloat(i % 3))
        // Each stalk leans on its own beat, so the clump sways rather than
        // tipping over together.
        let lean = sin(phase + CGFloat(i) * 0.8) * rect.width * 0.05
        let top = CGPoint(x: x + lean, y: rect.maxY - height)
        var path = Path()
        path.move(to: CGPoint(x: x, y: rect.maxY))
        path.addQuadCurve(to: top, control: CGPoint(x: x + lean * 0.4, y: rect.maxY - height * 0.6))
        ctx.stroke(path, with: .color(palette.padDark), style: stroke(rect.width * 0.035))
        ctx.fill(circle(top, rect.width * 0.045), with: .color(palette.turtleShell))
    }
}

nonisolated private func drawFlowers(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    for i in 0..<3 {
        let at = CGPoint(
            x: rect.minX + rect.width * (0.22 + 0.30 * CGFloat(i)),
            y: rect.minY + rect.height * (0.35 + 0.22 * CGFloat(i % 2)) + sin(phase + CGFloat(i)) * rect.height * 0.04
        )
        let r = rect.width * 0.13
        for petal in 0..<6 {
            let a = CGFloat(petal) * (2 * .pi / 6) + CGFloat(i)
            ctx.fill(
                circle(CGPoint(x: at.x + cos(a) * r * 0.7, y: at.y + sin(a) * r * 0.7), r * 0.55),
                with: .color(palette.ripple.opacity(0.85))
            )
        }
        ctx.fill(circle(at, r * 0.45), with: .color(palette.accent))
    }
}

nonisolated private func drawMossyRock(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    ctx.fill(
        polygon([
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.32),
            CGPoint(x: rect.minX + rect.width * 0.55, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.45),
            CGPoint(x: rect.maxX, y: rect.maxY),
        ]),
        with: .color(palette.rock)
    )
    ctx.fill(
        polygon([
            CGPoint(x: rect.minX + rect.width * 0.55, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.45),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX + rect.width * 0.6, y: rect.maxY),
        ]),
        with: .color(palette.rockDark)
    )
    // Moss on the sunny side only - a rock mossy all over reads as a bush.
    ctx.fill(
        circle(CGPoint(x: rect.minX + rect.width * 0.32, y: rect.minY + rect.height * 0.34), rect.width * 0.17),
        with: .color(palette.pad.opacity(0.75))
    )
}

nonisolated private func drawLog(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let body = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.28, width: rect.width, height: rect.height * 0.44)
    ctx.fill(Path(roundedRect: body, cornerRadius: body.height / 2), with: .color(palette.rockDark))
    ctx.fill(
        oval(CGPoint(x: body.maxX - body.height * 0.55, y: body.minY), CGSize(width: body.height * 0.55, height: body.height)),
        with: .color(palette.rock)
    )
    for i in 0..<3 {
        ctx.fill(
            circle(CGPoint(x: body.minX + body.width * (0.2 + 0.22 * CGFloat(i)), y: body.minY), body.height * 0.22),
            with: .color(palette.pad.opacity(0.7))
        )
    }
}

nonisolated private func drawDock(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette) {
    let plank = rect.height * 0.16
    for i in 0..<4 {
        ctx.fill(
            Path(roundedRect: CGRect(x: rect.minX, y: rect.minY + CGFloat(i) * plank * 1.15, width: rect.width, height: plank),
                 cornerRadius: plank * 0.3),
            with: .color(i % 2 == 0 ? palette.rock : palette.rockDark)
        )
    }
    for x in [0.08, 0.92] as [CGFloat] {
        ctx.fill(
            Path(roundedRect: CGRect(x: rect.minX + rect.width * x - rect.width * 0.03, y: rect.minY,
                                     width: rect.width * 0.06, height: rect.height * 0.8),
                 cornerRadius: rect.width * 0.03),
            with: .color(palette.rockDark)
        )
    }
}

nonisolated private func drawFloatingLantern(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let glow = 0.55 + 0.25 * sin(phase * 2)
    ctx.fill(
        circle(CGPoint(x: rect.midX, y: rect.midY), rect.width * 1.1),
        with: .color(Color(hex: 0xFFC061).opacity(0.22 * glow))
    )
    ctx.fill(
        Path(roundedRect: CGRect(x: rect.minX, y: rect.midY + rect.height * 0.2, width: rect.width, height: rect.height * 0.18),
             cornerRadius: rect.width * 0.08),
        with: .color(palette.rockDark)
    )
    ctx.fill(
        Path(roundedRect: CGRect(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.14,
                                 width: rect.width * 0.72, height: rect.height * 0.5),
             cornerRadius: rect.width * 0.16),
        with: .color(Color(hex: 0xFFE1A8).opacity(0.9))
    )
    ctx.fill(
        circle(CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.4), rect.width * 0.16),
        with: .color(Color(hex: 0xFF9E3D).opacity(glow))
    )
}

nonisolated private func drawSpring(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ phase: CGFloat) {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    // Three rings breathing out of one point, plus the bubbles they carry.
    for ring in 0..<3 {
        let p = ((phase / (2 * .pi)) + CGFloat(ring) / 3).truncatingRemainder(dividingBy: 1)
        ctx.stroke(
            circle(center, rect.width * (0.12 + p * 0.5)),
            with: .color(palette.ripple.opacity((1 - p) * 0.4)),
            style: stroke(rect.width * 0.035)
        )
    }
    for i in 0..<5 {
        let p = ((phase / (2 * .pi)) + CGFloat(i) * 0.2).truncatingRemainder(dividingBy: 1)
        ctx.fill(
            circle(
                CGPoint(
                    x: center.x + sin(CGFloat(i) * 1.7 + phase) * rect.width * 0.16,
                    y: center.y - rect.height * 0.5 * p
                ),
                rect.width * (0.06 - 0.03 * p)
            ),
            with: .color(palette.ripple.opacity((1 - p) * 0.6))
        )
    }
}

// MARK: - Sky

/// The sky, painted over everything else.
///
/// Weather is a wash plus particles rather than a second palette. A theme the
/// player bought has to stay recognisable under rain, and swapping its colours
/// out for a weather set would mean the sakura pond is only sakura on a clear
/// day.
nonisolated func drawWeather(_ ctx: inout GraphicsContext, id: String, size: CGSize, palette: PondPalette, time: CGFloat) {
    let w = size.width
    let h = size.height
    let full = Path(CGRect(origin: .zero, size: size))
    switch id {
    case "sunset":
        ctx.fill(full, with: .linearGradient(
            Gradient(stops: [
                .init(color: Color(hex: 0xFF9A5B).opacity(0.42), location: 0),
                .init(color: Color(hex: 0xE0567F).opacity(0.20), location: 0.55),
                .init(color: Color(hex: 0x2C2350).opacity(0.30), location: 1),
            ]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)
        ))

    case "fog":
        ctx.fill(full, with: .color(Color(hex: 0xDCE9EE).opacity(0.22)))
        // Four slow bands at different speeds; the pond shows through.
        for i in 0..<4 {
            let y = h * (0.16 + 0.22 * CGFloat(i))
            let drift = ((time * (0.02 + 0.01 * CGFloat(i))).truncatingRemainder(dividingBy: 1.4) - 0.2) * w
            ctx.fill(
                oval(CGPoint(x: drift, y: y), CGSize(width: w * 0.8, height: h * 0.10)),
                with: .color(Color.white.opacity(0.13))
            )
        }

    case "night":
        ctx.fill(full, with: .linearGradient(
            Gradient(stops: [
                .init(color: Color(hex: 0x060F26).opacity(0.62), location: 0),
                .init(color: Color(hex: 0x0B1B33).opacity(0.46), location: 1),
            ]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)
        ))
        // Fireflies: fixed lanes, each blinking on its own clock, so they read
        // as insects rather than as noise.
        for i in 0..<14 {
            let fx = (CGFloat(i) * 0.137 + time * 0.012 * CGFloat(1 + i % 3)).truncatingRemainder(dividingBy: 1)
            let fy = 0.12 + (CGFloat(i) * 0.271 + time * 0.008).truncatingRemainder(dividingBy: 0.74)
            let blink = (sin(time * (1.4 + CGFloat(i % 5) * 0.3) + CGFloat(i)) + 1) / 2
            if blink > 0.35 {
                let at = CGPoint(x: fx * w, y: fy * h)
                ctx.fill(circle(at, w * 0.006 * blink), with: .color(Color(hex: 0xCBFF7A).opacity((blink - 0.35) * 1.1)))
                ctx.fill(circle(at, w * 0.02 * blink), with: .color(Color(hex: 0xCBFF7A).opacity((blink - 0.35) * 0.22)))
            }
        }

    case "rain":
        ctx.fill(full, with: .color(Color(hex: 0x2A4A5C).opacity(0.28)))
        for i in 0..<46 {
            let fx = (CGFloat(i) * 0.0217 * 7).truncatingRemainder(dividingBy: 1)
            let fy = (CGFloat(i) * 0.173 + time * 1.15).truncatingRemainder(dividingBy: 1.1) - 0.05
            let len = h * 0.045
            ctx.stroke(
                line(CGPoint(x: fx * w, y: fy * h), CGPoint(x: fx * w - w * 0.012, y: fy * h + len)),
                with: .color(palette.ripple.opacity(0.45)),
                style: stroke(w * 0.004)
            )
        }
        // Where the drops land the water answers back.
        for i in 0..<6 {
            let p = (time * 0.9 + CGFloat(i) * 0.17).truncatingRemainder(dividingBy: 1)
            ctx.stroke(
                circle(
                    CGPoint(
                        x: w * (CGFloat(i) * 0.173 * 5).truncatingRemainder(dividingBy: 1),
                        y: h * (0.25 + 0.5 * (CGFloat(i) * 0.31).truncatingRemainder(dividingBy: 1))
                    ),
                    w * (0.01 + p * 0.06)
                ),
                with: .color(palette.ripple.opacity((1 - p) * 0.30)),
                style: stroke(w * 0.003)
            )
        }

    case "snow":
        ctx.fill(full, with: .color(Color(hex: 0xBFE3F2).opacity(0.18)))
        for i in 0..<40 {
            let sway = sin(time * 0.7 + CGFloat(i)) * w * 0.02
            let fx = (CGFloat(i) * 0.0313 * 8).truncatingRemainder(dividingBy: 1)
            let fy = (CGFloat(i) * 0.211 + time * 0.13).truncatingRemainder(dividingBy: 1.1) - 0.05
            ctx.fill(
                circle(CGPoint(x: fx * w + sway, y: fy * h), w * (0.004 + 0.004 * (CGFloat(i % 3) / 2))),
                with: .color(Color.white.opacity(0.75))
            )
        }

    default:
        drawWeatherMore(&ctx, id, size, palette, time)
    }
}

/// The water itself, tinted for the sky above it.
///
/// Night and sunset change what colour water *is*, not just what is drawn on
/// top of it: a bright noon pond under a night overlay looks like a photo with
/// a filter, which is exactly what it would be.
nonisolated func drawPondWater(
    _ ctx: inout GraphicsContext,
    weatherId: String,
    size: CGSize,
    palette: PondPalette,
    time: CGFloat,
    /// The water the player bought, which is a different question from the sky.
    /// Defaults to the plain surface so the four mini games - which draw water
    /// with no pond around it - go on looking exactly as they did.
    waterId: String = "clear"
) {
    let tint: (Color, CGFloat)
    switch weatherId {
    case "night": tint = (Color(hex: 0x0A1B33), 0.45)
    case "sunset": tint = (Color(hex: 0x8C3B63), 0.22)
    case "fog": tint = (Color(hex: 0xB8D3DC), 0.20)
    case "rain": tint = (Color(hex: 0x1E3C4C), 0.25)
    case "snow": tint = (Color(hex: 0xD7EEF8), 0.16)
    case "storm": tint = (Color(hex: 0x16283A), 0.34)
    case "aurora": tint = (Color(hex: 0x123A46), 0.26)
    case "starry": tint = (Color(hex: 0x0B1430), 0.42)
    default: tint = (.clear, 0)
    }
    // The bought surface first, the sky's tint on top of it: the sky is the
    // light falling on the water, so it has to be the thing that colours it
    // last, or a night pond over emerald water reads as green daylight.
    let base = waterColours(waterId, palette)
    let top = base.0.blended(tint.0, tint.1)
    let deep = base.1.blended(tint.0, tint.1)
    let w = size.width
    let h = size.height
    ctx.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .linearGradient(Gradient(colors: [top, deep]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h))
    )

    // Standing swell, so the surface is never a flat colour field.
    for i in 0..<7 {
        let y = h * (0.10 + 0.125 * CGFloat(i)) + sin(time * 0.6 + CGFloat(i)) * h * 0.006
        ctx.stroke(
            line(CGPoint(x: 0, y: y), CGPoint(x: w, y: y + h * 0.004)),
            with: .color(palette.waterRim.opacity(0.13)),
            style: stroke(h * 0.004)
        )
    }

    drawWaterDetail(&ctx, waterId, size, palette, time)
}

// MARK: - The banks
//
// My Pond and the Decorate screen draw the same basin so that a thing placed on
// one is in the same place on the other. Everything here is in fractions - of
// the width across, of the height down - so the two screens can be different
// shapes and still agree about where the water ends.
//
// The shoreline is a wave rather than a straight edge. A rectangle of water in
// a rectangle of grass reads as a swimming pool, and the whole screen is about
// a pond you would want to sit beside.

nonisolated private let shoreTopFraction: CGFloat = 0.155
nonisolated private let shoreBottomFraction: CGFloat = 0.845
nonisolated private let shoreWave: CGFloat = 0.013

/// The far shoreline's y, in height fractions, at `x` in width fractions.
nonisolated func shoreTopAt(_ x: CGFloat) -> CGFloat {
    shoreTopFraction + sin(x * 2 * .pi + 0.4) * shoreWave
}

/// The near shoreline's y, in height fractions, at `x` in width fractions.
nonisolated func shoreBottomAt(_ x: CGFloat) -> CGFloat {
    shoreBottomFraction + sin(x * 2.6 * .pi + 1.7) * shoreWave
}

/// True if `at` (in pond fractions) is over open water.
nonisolated func isOverWater(_ at: CGPoint) -> Bool {
    at.y > shoreTopAt(at.x) && at.y < shoreBottomAt(at.x)
}

/// The water's outline, in pixels, for clipping and for its rim.
nonisolated private func waterPath(_ w: CGFloat, _ h: CGFloat) -> Path {
    let steps = 28
    var p = Path()
    p.move(to: CGPoint(x: 0, y: shoreTopAt(0) * h))
    for i in 1...steps {
        let x = CGFloat(i) / CGFloat(steps)
        p.addLine(to: CGPoint(x: x * w, y: shoreTopAt(x) * h))
    }
    for i in stride(from: steps, through: 0, by: -1) {
        let x = CGFloat(i) / CGFloat(steps)
        p.addLine(to: CGPoint(x: x * w, y: shoreBottomAt(x) * h))
    }
    p.closeSubpath()
    return p
}

/// Grass, then the water sitting in it.
///
/// Used by My Pond and by the Decorate screen; the games draw `drawPondWater`
/// on its own, because a bank is scenery for a place you live in and clutter in
/// a place you are trying to read.
nonisolated func drawPondBasin(
    _ ctx: inout GraphicsContext,
    weatherId: String,
    size: CGSize,
    palette: PondPalette,
    time: CGFloat,
    waterId: String = "clear",
    shoreId: String = "meadow"
) {
    let w = size.width
    let h = size.height
    drawShore(&ctx, shoreId, size, palette, time)

    let path = waterPath(w, h)
    var clipped = ctx
    clipped.clip(to: path)
    drawPondWater(&clipped, weatherId: weatherId, size: size, palette: palette, time: time, waterId: waterId)
    // A wet rim where the water meets the grass.
    ctx.stroke(path, with: .color(palette.waterRim.opacity(0.45)), style: stroke(w * 0.012))
}

/// The default bank: meadow grass, tufted thickest at the water's edge.
nonisolated func drawMeadowShore(_ ctx: inout GraphicsContext, _ size: CGSize, _ palette: PondPalette, _ time: CGFloat) {
    let w = size.width
    let h = size.height
    let grass = palette.padDark.blended(Color(hex: 0x2E4A22), 0.35)
    let grassLit = palette.pad.blended(grass, 0.45)
    ctx.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .linearGradient(
            Gradient(stops: [
                .init(color: grassLit, location: 0),
                .init(color: grass, location: 0.5),
                .init(color: grassLit, location: 1),
            ]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)
        )
    )

    // Tufts, thickest near the water, so the grass is not a flat field.
    for i in 0..<44 {
        let x = CGFloat((i * 37) % 100) / 100
        let near = i % 2 == 0
        let edge = near ? shoreBottomAt(x) : shoreTopAt(x)
        let off = CGFloat((i * 53) % 100) / 100 * 0.075 + 0.012
        let y = near ? edge + off : edge - off
        if y < 0 || y > 1 { continue }
        let len = h * (0.008 + CGFloat((i * 29) % 100) / 100 * 0.014)
        ctx.stroke(
            line(
                CGPoint(x: x * w, y: y * h),
                CGPoint(x: x * w + sin(time * 0.7 + CGFloat(i)) * w * 0.006, y: y * h - len)
            ),
            with: .color(grassLit.blended(palette.pad, 0.5).opacity(0.55)),
            style: stroke(w * 0.006)
        )
    }
}

/// A tile of plain pond, for drawing one decoration against in a picker.
nonisolated func drawRoundRectPatch(_ ctx: inout GraphicsContext, size: CGSize, palette: PondPalette) {
    let r = min(size.width, size.height) * 0.16
    ctx.fill(
        Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: r),
        with: .linearGradient(
            Gradient(colors: [palette.water, palette.waterDeep]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)
        )
    )
}

/// Expanding rings from one tap, at `progress` through their life.
nonisolated func drawSplashRings(_ ctx: inout GraphicsContext, at: CGPoint, progress: CGFloat, size: CGSize, palette: PondPalette) {
    let w = size.width
    for ring in 0...2 {
        let alpha = max((1 - progress) * (0.42 - CGFloat(ring) * 0.12), 0)
        if alpha <= 0 { continue }
        ctx.stroke(
            circle(at, w * (0.02 + progress * 0.19 + CGFloat(ring) * 0.032)),
            with: .color(palette.ripple.opacity(alpha)),
            style: stroke(w * 0.004 + (1 - progress) * w * 0.005)
        )
    }
    if progress < 0.3 {
        ctx.fill(circle(at, w * 0.018), with: .color(palette.ripple.opacity((0.3 - progress) * 1.6)))
    }
}
