//
//  FloaterArtSpecial.swift
//  PondPulse
//
//  The five special friends - the only things in PondPulse that cost money on
//  their own. A 1:1 port of the Android ui/FloaterArtSpecial.kt.
//
//  They are drawn to a higher standard than the rest on purpose: more layers,
//  more moving parts in the silhouette, a mark of their own. Somebody who pays
//  for one has to be able to see, at a single grid cell, that theirs is not one
//  of the ones everybody has. That is the whole justification for charging, and
//  a paid friend that reads like a recoloured duckling would not have one.
//

import SwiftUI

/// A whale made of night sky, with stars inside it and a spout of light.
nonisolated func drawStarWhale(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x2B2A63))
    let deep = body.shaded(0.78)
    let spark = Color(hex: 0xDCE9FF)

    // Tail flukes, then the body over them.
    var flukes = Path()
    flukes.move(to: CGPoint(x: c.x - cell * 0.20, y: c.y + cell * 0.02))
    flukes.addQuadCurve(to: CGPoint(x: c.x - cell * 0.48, y: c.y - cell * 0.24), control: CGPoint(x: c.x - cell * 0.40, y: c.y - cell * 0.04))
    flukes.addQuadCurve(to: CGPoint(x: c.x - cell * 0.26, y: c.y + cell * 0.02), control: CGPoint(x: c.x - cell * 0.30, y: c.y - cell * 0.14))
    flukes.addQuadCurve(to: CGPoint(x: c.x - cell * 0.46, y: c.y + cell * 0.22), control: CGPoint(x: c.x - cell * 0.30, y: c.y + cell * 0.16))
    flukes.addQuadCurve(to: CGPoint(x: c.x - cell * 0.20, y: c.y + cell * 0.02), control: CGPoint(x: c.x - cell * 0.34, y: c.y + cell * 0.12))
    flukes.closeSubpath()
    ctx.fill(flukes, with: .color(deep))

    var hull = Path()
    hull.move(to: CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.02))
    hull.addCurve(
        to: CGPoint(x: c.x + cell * 0.36, y: c.y - cell * 0.06),
        control1: CGPoint(x: c.x - cell * 0.16, y: c.y - cell * 0.24),
        control2: CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.26)
    )
    hull.addCurve(
        to: CGPoint(x: c.x - cell * 0.24, y: c.y + cell * 0.10),
        control1: CGPoint(x: c.x + cell * 0.40, y: c.y + cell * 0.06),
        control2: CGPoint(x: c.x + cell * 0.10, y: c.y + cell * 0.22)
    )
    hull.closeSubpath()
    ctx.fill(hull, with: .color(deep))

    var back = Path()
    back.move(to: CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.02))
    back.addCurve(
        to: CGPoint(x: c.x + cell * 0.34, y: c.y - cell * 0.06),
        control1: CGPoint(x: c.x - cell * 0.14, y: c.y - cell * 0.22),
        control2: CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.24)
    )
    back.addCurve(
        to: CGPoint(x: c.x - cell * 0.22, y: c.y - cell * 0.02),
        control1: CGPoint(x: c.x + cell * 0.20, y: c.y + cell * 0.02),
        control2: CGPoint(x: c.x - cell * 0.04, y: c.y + cell * 0.04)
    )
    back.closeSubpath()
    ctx.fill(back, with: .color(body))

    // Belly pleats.
    for i in 0..<4 {
        let x = c.x - cell * 0.10 + cell * 0.11 * CGFloat(i)
        ctx.stroke(
            line(CGPoint(x: x, y: c.y + cell * 0.03), CGPoint(x: x + cell * 0.02, y: c.y + cell * 0.15)),
            with: .color(deep.opacity(0.7)), style: stroke(cell * 0.014)
        )
    }
    // The night inside it: constellations, and one bright star.
    let stars: [CGPoint] = [
        CGPoint(x: -0.10, y: -0.10), CGPoint(x: 0.00, y: -0.14), CGPoint(x: 0.10, y: -0.08),
        CGPoint(x: 0.18, y: -0.13), CGPoint(x: -0.02, y: -0.04), CGPoint(x: 0.24, y: -0.05),
    ]
    for (i, p) in stars.enumerated() {
        ctx.fill(
            circle(CGPoint(x: c.x + cell * p.x, y: c.y + cell * p.y), cell * (0.014 + 0.006 * CGFloat(i % 3))),
            with: .color(spark.opacity(0.9))
        )
    }
    for i in 0..<(stars.count - 1) {
        ctx.stroke(
            line(CGPoint(x: c.x + cell * stars[i].x, y: c.y + cell * stars[i].y),
                 CGPoint(x: c.x + cell * stars[i + 1].x, y: c.y + cell * stars[i + 1].y)),
            with: .color(spark.opacity(0.28)), style: stroke(cell * 0.006)
        )
    }
    // Pectoral fin, so it is not a floating log.
    var fin = Path()
    fin.move(to: CGPoint(x: c.x + cell * 0.02, y: c.y + cell * 0.06))
    fin.addQuadCurve(to: CGPoint(x: c.x + cell * 0.20, y: c.y + cell * 0.18), control: CGPoint(x: c.x + cell * 0.06, y: c.y + cell * 0.24))
    fin.closeSubpath()
    ctx.fill(fin, with: .color(deep))
    // The spout: a fountain of light rather than water.
    for a in [-32.0, -8.0, 16.0] as [CGFloat] {
        let r = a * .pi / 180
        ctx.stroke(
            line(CGPoint(x: c.x + cell * 0.16, y: c.y - cell * 0.20),
                 CGPoint(x: c.x + cell * 0.16 + sin(r) * cell * 0.20, y: c.y - cell * 0.20 - cos(r) * cell * 0.22)),
            with: .color(spark.opacity(0.55)), style: stroke(cell * 0.020)
        )
    }
    ctx.fill(starBurst(CGPoint(x: c.x + cell * 0.15, y: c.y - cell * 0.40), cell * 0.075), with: .color(Color(hex: 0xFFF2B8)))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.28, y: c.y - cell * 0.08), cell * 0.035), with: .color(spark))
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.29, y: c.y - cell * 0.08), cell * 0.020), with: .color(ink))
}

/// A nine-tailed fox: the fan of tails is the entire silhouette.
nonisolated func drawKitsune(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xE8804A))
    let pale = body.lightened(1.34)
    let tip = Color(hex: 0xFDF3E4)

    // Nine tails, fanned behind, drawn as leaves rather than as strokes. Each
    // is a closed lobe with its two control points pushed to *opposite* sides
    // of the tail's own axis - that is what gives it width. Built from a single
    // control point either side, they collapsed to slivers and the fan read as
    // a string of beads.
    let from = CGPoint(x: c.x - cell * 0.04, y: c.y + cell * 0.04)
    for i in 0..<9 {
        let a = CGFloat.pi * (0.58 + 0.093 * CGFloat(i))
        let len = cell * (0.42 + 0.04 * sin(CGFloat(i) * 1.7))
        let dir = CGPoint(x: cos(a), y: sin(a))
        let across = CGPoint(x: -dir.y, y: dir.x)
        let to = CGPoint(x: from.x + dir.x * len, y: from.y + dir.y * len)
        let fat = cell * 0.085
        var tail = Path()
        tail.move(to: from)
        tail.addQuadCurve(to: to, control: CGPoint(x: from.x + dir.x * len * 0.55 + across.x * fat, y: from.y + dir.y * len * 0.55 + across.y * fat))
        tail.addQuadCurve(to: from, control: CGPoint(x: from.x + dir.x * len * 0.55 - across.x * fat, y: from.y + dir.y * len * 0.55 - across.y * fat))
        tail.closeSubpath()
        ctx.fill(tail, with: .color(i % 2 == 0 ? body : pale))
        // A white tip on each, which is the mark of the fox and also what makes
        // nine overlapping lobes countable at one grid cell.
        ctx.fill(circle(to, cell * 0.042), with: .color(tip))
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.12, y: c.y - cell * 0.04), CGSize(width: cell * 0.40, height: cell * 0.28)), with: .color(body.shaded()))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.12, y: c.y - cell * 0.08), CGSize(width: cell * 0.38, height: cell * 0.26)), with: .color(body))
    let head = CGPoint(x: c.x + cell * 0.24, y: c.y - cell * 0.16)
    // Ears first, so the head sits over their bases.
    for sx in [-1.0, 1.0] as [CGFloat] {
        ctx.fill(
            polygon([
                CGPoint(x: head.x + cell * 0.10 * sx - cell * 0.02, y: head.y - cell * 0.06),
                CGPoint(x: head.x + cell * 0.13 * sx, y: head.y - cell * 0.28),
                CGPoint(x: head.x + cell * 0.02 * sx + cell * 0.03, y: head.y - cell * 0.08),
            ]),
            with: .color(body)
        )
        ctx.fill(
            polygon([
                CGPoint(x: head.x + cell * 0.095 * sx, y: head.y - cell * 0.09),
                CGPoint(x: head.x + cell * 0.115 * sx, y: head.y - cell * 0.22),
                CGPoint(x: head.x + cell * 0.045 * sx, y: head.y - cell * 0.10),
            ]),
            with: .color(Color(hex: 0x3B2430))
        )
    }
    ctx.fill(circle(head, cell * 0.135), with: .color(body))
    // Muzzle and cheek ruff, cream.
    var muzzle = Path()
    muzzle.move(to: CGPoint(x: head.x + cell * 0.02, y: head.y - cell * 0.02))
    muzzle.addQuadCurve(to: CGPoint(x: head.x + cell * 0.24, y: head.y + cell * 0.06), control: CGPoint(x: head.x + cell * 0.22, y: head.y))
    muzzle.addQuadCurve(to: CGPoint(x: head.x - cell * 0.02, y: head.y + cell * 0.09), control: CGPoint(x: head.x + cell * 0.12, y: head.y + cell * 0.14))
    muzzle.closeSubpath()
    ctx.fill(muzzle, with: .color(tip))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.235, y: head.y + cell * 0.055), cell * 0.026), with: .color(ink))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.03, y: head.y - cell * 0.04), cell * 0.026), with: .color(ink))
    // The shrine mark on the brow: the one flourish that says "kitsune".
    ctx.fill(
        polygon([
            CGPoint(x: head.x - cell * 0.08, y: head.y - cell * 0.02),
            CGPoint(x: head.x - cell * 0.02, y: head.y - cell * 0.09),
            CGPoint(x: head.x + cell * 0.01, y: head.y - cell * 0.02),
        ]),
        with: .color(Color(hex: 0xE04C57))
    )
}

/// A griffin: lion behind, eagle in front, one wing raised over both.
nonisolated func drawGriffin(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xC59A46))
    let fur = body.shaded(0.78)
    let feather = body.lightened(1.30)
    let gold = Color(hex: 0xE9C05A)

    // One wing, not two. The first pass drew a pair, and at a single grid cell
    // two overlapping shapes over the same body simply filled the square: no
    // lion behind, no eagle in front, just a tawny blob with a beak.
    var farWing = Path()
    farWing.move(to: CGPoint(x: c.x - cell * 0.02, y: c.y - cell * 0.06))
    farWing.addQuadCurve(to: CGPoint(x: c.x + cell * 0.10, y: c.y - cell * 0.42), control: CGPoint(x: c.x - cell * 0.16, y: c.y - cell * 0.44))
    farWing.addQuadCurve(to: CGPoint(x: c.x - cell * 0.02, y: c.y - cell * 0.06), control: CGPoint(x: c.x + cell * 0.02, y: c.y - cell * 0.22))
    farWing.closeSubpath()
    ctx.fill(farWing, with: .color(feather.shaded(0.80)))

    // Lion hindquarters and a tufted tail, before the chest overlaps them.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.36, y: c.y - cell * 0.02), CGSize(width: cell * 0.40, height: cell * 0.28)), with: .color(fur))
    var tail = Path()
    tail.move(to: CGPoint(x: c.x - cell * 0.32, y: c.y + cell * 0.06))
    tail.addCurve(
        to: CGPoint(x: c.x - cell * 0.40, y: c.y - cell * 0.24),
        control1: CGPoint(x: c.x - cell * 0.52, y: c.y + cell * 0.04),
        control2: CGPoint(x: c.x - cell * 0.50, y: c.y - cell * 0.18)
    )
    ctx.stroke(tail, with: .color(fur), style: stroke(cell * 0.026))
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.40, y: c.y - cell * 0.26), cell * 0.048), with: .color(fur))
    // Haunch, so the lion half has a leg rather than an outline.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y + cell * 0.06), CGSize(width: cell * 0.20, height: cell * 0.18)), with: .color(fur.shaded(0.90)))

    // Eagle chest and shoulder.
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.10, y: c.y - cell * 0.10), CGSize(width: cell * 0.34, height: cell * 0.30)), with: .color(feather))
    // Breast feathers: three short chevrons, the whole "eagle" read.
    for i in 0..<3 {
        let y = c.y - cell * 0.02 + cell * 0.07 * CGFloat(i)
        var chev = Path()
        chev.move(to: CGPoint(x: c.x - cell * 0.04, y: y))
        chev.addQuadCurve(to: CGPoint(x: c.x + cell * 0.16, y: y), control: CGPoint(x: c.x + cell * 0.06, y: y + cell * 0.05))
        ctx.stroke(chev, with: .color(feather.shaded(0.84).opacity(0.7)), style: stroke(cell * 0.012))
    }

    // The near wing, raised, with three flight feathers along its edge.
    var wing = Path()
    wing.move(to: CGPoint(x: c.x + cell * 0.02, y: c.y - cell * 0.02))
    wing.addCurve(
        to: CGPoint(x: c.x + cell * 0.20, y: c.y - cell * 0.40),
        control1: CGPoint(x: c.x - cell * 0.14, y: c.y - cell * 0.34),
        control2: CGPoint(x: c.x + cell * 0.06, y: c.y - cell * 0.50)
    )
    wing.addCurve(
        to: CGPoint(x: c.x + cell * 0.02, y: c.y - cell * 0.02),
        control1: CGPoint(x: c.x + cell * 0.22, y: c.y - cell * 0.22),
        control2: CGPoint(x: c.x + cell * 0.16, y: c.y - cell * 0.10)
    )
    wing.closeSubpath()
    ctx.fill(wing, with: .color(feather))
    for i in 1...3 {
        let t = CGFloat(i) / 4
        ctx.stroke(
            line(CGPoint(x: c.x + cell * 0.03, y: c.y - cell * 0.06),
                 CGPoint(x: c.x + cell * (0.02 + 0.18 * t), y: c.y - cell * (0.18 + 0.22 * t))),
            with: .color(fur.opacity(0.45)), style: stroke(cell * 0.013)
        )
    }

    // Foreleg with talons.
    var leg = Path()
    leg.move(to: CGPoint(x: c.x + cell * 0.12, y: c.y + cell * 0.14))
    leg.addLine(to: CGPoint(x: c.x + cell * 0.22, y: c.y + cell * 0.24))
    leg.addLine(to: CGPoint(x: c.x + cell * 0.34, y: c.y + cell * 0.22))
    ctx.stroke(leg, with: .color(gold), style: stroke(cell * 0.024))

    let head = CGPoint(x: c.x + cell * 0.26, y: c.y - cell * 0.18)
    ctx.fill(circle(head, cell * 0.125), with: .color(feather))
    // Hooded brow, which is what makes a round head read as a raptor.
    var brow = Path()
    brow.move(to: CGPoint(x: head.x - cell * 0.125, y: head.y - cell * 0.03))
    brow.addQuadCurve(to: CGPoint(x: head.x + cell * 0.125, y: head.y - cell * 0.04), control: CGPoint(x: head.x, y: head.y - cell * 0.20))
    brow.addLine(to: CGPoint(x: head.x + cell * 0.09, y: head.y + cell * 0.02))
    brow.addQuadCurve(to: CGPoint(x: head.x - cell * 0.10, y: head.y + cell * 0.02), control: CGPoint(x: head.x, y: head.y - cell * 0.09))
    brow.closeSubpath()
    ctx.fill(brow, with: .color(feather.shaded(0.84)))
    // Hooked beak.
    var beak = Path()
    beak.move(to: CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.02))
    beak.addQuadCurve(to: CGPoint(x: head.x + cell * 0.22, y: head.y + cell * 0.11), control: CGPoint(x: head.x + cell * 0.26, y: head.y - cell * 0.01))
    beak.addQuadCurve(to: CGPoint(x: head.x + cell * 0.05, y: head.y + cell * 0.06), control: CGPoint(x: head.x + cell * 0.15, y: head.y + cell * 0.05))
    beak.closeSubpath()
    ctx.fill(beak, with: .color(gold))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.03, y: head.y - cell * 0.04), cell * 0.038), with: .color(Color(hex: 0xFDF6E8)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.04, y: head.y - cell * 0.04), cell * 0.022), with: .color(ink))
}

/// A sea dragon: a coiled serpent with a mane of fins.
nonisolated func drawSeaDragon(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0x2E9E8F))
    let dark = body.shaded(0.78)
    let fin = Color(hex: 0x7FE0D2)

    // The coil: an S of overlapping segments, biggest at the shoulder.
    let spine: [CGPoint] = [
        CGPoint(x: -0.42, y: 0.18), CGPoint(x: -0.28, y: 0.24), CGPoint(x: -0.12, y: 0.16),
        CGPoint(x: -0.02, y: 0.02), CGPoint(x: 0.06, y: -0.12), CGPoint(x: 0.18, y: -0.20),
    ]
    // Tail fin first.
    ctx.fill(
        polygon([
            CGPoint(x: c.x + cell * spine[0].x, y: c.y + cell * spine[0].y),
            CGPoint(x: c.x - cell * 0.52, y: c.y + cell * 0.02),
            CGPoint(x: c.x - cell * 0.40, y: c.y + cell * 0.16),
            CGPoint(x: c.x - cell * 0.52, y: c.y + cell * 0.34),
        ]),
        with: .color(fin.opacity(0.85))
    )
    for (i, p) in spine.enumerated() {
        ctx.fill(circle(CGPoint(x: c.x + cell * p.x, y: c.y + cell * p.y), cell * (0.075 + 0.017 * CGFloat(i))), with: .color(dark))
    }
    for (i, p) in spine.enumerated() {
        ctx.fill(circle(CGPoint(x: c.x + cell * p.x, y: c.y + cell * p.y - cell * 0.010), cell * (0.062 + 0.016 * CGFloat(i))), with: .color(body))
    }
    // Dorsal sail along the spine.
    for i in 1..<spine.count {
        let p = CGPoint(x: c.x + cell * spine[i].x, y: c.y + cell * spine[i].y)
        let q = CGPoint(x: c.x + cell * spine[i - 1].x, y: c.y + cell * spine[i - 1].y)
        let nx = -(p.y - q.y), ny = p.x - q.x
        let n = max(sqrt(nx * nx + ny * ny), 0.0001)
        ctx.fill(
            polygon([q, CGPoint(x: p.x + nx / n * cell * 0.16, y: p.y + ny / n * cell * 0.16), p]),
            with: .color(fin.opacity(0.8))
        )
    }
    let head = CGPoint(x: c.x + cell * 0.30, y: c.y - cell * 0.26)
    ctx.fill(circle(head, cell * 0.125), with: .color(body))
    // A long snout, and whiskers.
    ctx.fill(
        polygon([
            CGPoint(x: head.x + cell * 0.02, y: head.y - cell * 0.05),
            CGPoint(x: head.x + cell * 0.26, y: head.y - cell * 0.01),
            CGPoint(x: head.x + cell * 0.24, y: head.y + cell * 0.07),
            CGPoint(x: head.x + cell * 0.02, y: head.y + cell * 0.08),
        ]),
        with: .color(body)
    )
    for sy in [-1.0, 1.0] as [CGFloat] {
        var whisker = Path()
        whisker.move(to: CGPoint(x: head.x + cell * 0.20, y: head.y + cell * 0.03 * sy))
        whisker.addQuadCurve(
            to: CGPoint(x: head.x + cell * 0.18, y: head.y + cell * 0.26 * sy),
            control: CGPoint(x: head.x + cell * 0.36, y: head.y + cell * 0.16 * sy)
        )
        ctx.stroke(whisker, with: .color(fin), style: stroke(cell * 0.014))
    }
    // Horns.
    for sx in [-0.02, 0.06] as [CGFloat] {
        ctx.fill(
            polygon([
                CGPoint(x: head.x + cell * sx, y: head.y - cell * 0.09),
                CGPoint(x: head.x + cell * (sx - 0.05), y: head.y - cell * 0.28),
                CGPoint(x: head.x + cell * (sx + 0.05), y: head.y - cell * 0.11),
            ]),
            with: .color(fin)
        )
    }
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.07, y: head.y - cell * 0.02), cell * 0.036), with: .color(Color(hex: 0xFFF0B8)))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.08, y: head.y - cell * 0.02), cell * 0.018), with: .color(ink))
}

/// A moon rabbit pounding rice cake, sitting inside a crescent.
nonisolated func drawMoonRabbit(_ ctx: inout GraphicsContext, _ rect: CGRect, _ palette: PondPalette, _ color: DuckColor?) {
    let cell = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let body = bodyTint(palette, color, Color(hex: 0xF4F1FA))
    let dark = body.shaded(0.88)
    let moon = Color(hex: 0xF7E7A8)

    // The moon it rides in.
    ctx.fill(circle(CGPoint(x: c.x - cell * 0.02, y: c.y + cell * 0.02), cell * 0.46), with: .color(moon.opacity(0.30)))
    ctx.stroke(circle(CGPoint(x: c.x - cell * 0.02, y: c.y + cell * 0.02), cell * 0.40), with: .color(moon.opacity(0.55)), style: stroke(cell * 0.028))
    for i in 0..<5 {
        let a = CGFloat.pi * (1.15 + 0.16 * CGFloat(i))
        ctx.fill(
            circle(CGPoint(x: c.x + cos(a) * cell * 0.40, y: c.y + sin(a) * cell * 0.40), cell * (0.020 + 0.008 * CGFloat(i % 2))),
            with: .color(moon.opacity(0.45))
        )
    }
    // Ears, then head, then body: long ears are the whole read.
    let head = CGPoint(x: c.x + cell * 0.10, y: c.y - cell * 0.10)
    for (i, sx) in ([-1.0, 1.0] as [CGFloat]).enumerated() {
        let lean: CGFloat = i == 0 ? -0.10 : 0.02
        ctx.fill(
            oval(CGPoint(x: head.x + cell * (0.02 * sx + lean) - cell * 0.045, y: head.y - cell * 0.40),
                 CGSize(width: cell * 0.09, height: cell * 0.34)),
            with: .color(body)
        )
        ctx.fill(
            oval(CGPoint(x: head.x + cell * (0.02 * sx + lean) - cell * 0.022, y: head.y - cell * 0.36),
                 CGSize(width: cell * 0.045, height: cell * 0.26)),
            with: .color(Color(hex: 0xE6A8BC))
        )
    }
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.02), CGSize(width: cell * 0.40, height: cell * 0.30)), with: .color(dark))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.24, y: c.y - cell * 0.06), CGSize(width: cell * 0.38, height: cell * 0.28)), with: .color(body))
    ctx.fill(circle(head, cell * 0.125), with: .color(body))
    ctx.fill(circle(CGPoint(x: head.x + cell * 0.05, y: head.y - cell * 0.02), cell * 0.024), with: .color(ink))
    ctx.fill(circle(CGPoint(x: head.x - cell * 0.05, y: head.y - cell * 0.02), cell * 0.024), with: .color(ink))
    ctx.fill(circle(CGPoint(x: head.x, y: head.y + cell * 0.05), cell * 0.022), with: .color(Color(hex: 0xE6A8BC)))
    // The mallet and the mortar - the rest of the legend.
    ctx.stroke(
        line(CGPoint(x: c.x + cell * 0.16, y: c.y - cell * 0.06), CGPoint(x: c.x + cell * 0.36, y: c.y - cell * 0.32)),
        with: .color(Color(hex: 0xB98A52)), style: stroke(cell * 0.032)
    )
    ctx.fill(circle(CGPoint(x: c.x + cell * 0.38, y: c.y - cell * 0.34), cell * 0.070), with: .color(Color(hex: 0xD8A96A)))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.30, y: c.y + cell * 0.16), CGSize(width: cell * 0.26, height: cell * 0.18)), with: .color(Color(hex: 0xB98A52)))
    ctx.fill(oval(CGPoint(x: c.x - cell * 0.27, y: c.y + cell * 0.15), CGSize(width: cell * 0.20, height: cell * 0.09)), with: .color(Color(hex: 0xFDFBF4)))
}
