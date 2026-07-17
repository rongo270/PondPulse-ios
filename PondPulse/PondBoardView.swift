//
//  PondBoardView.swift
//  PondPulse
//
//  The pond itself: draws the level and animates splashes, drifts and hints.
//  Port of the Android ui/PondBoard.kt. One Canvas inside a
//  TimelineView(.animation) redraws per frame; a small spring simulation
//  glides every floater toward its cell, matching Compose's
//  spring(dampingRatio 0.75, stiffness low) feel.
//

import SwiftUI

/// Per-board animation state, mutated inside the render loop (the timeline
/// invalidates every frame, so no SwiftUI publishing is needed).
private final class BoardMotion {
    var levelId: String?
    var display: [Int: CGPoint] = [:]     // cell coordinates
    var velocity: [Int: CGVector] = [:]
    var ripples: [(center: Pos, start: Date)] = []
    var lastTick: Date?
    /// Captured by every draw so taps can map view points to cells.
    var lastSize: CGSize = .zero

    /// Compose StiffnessLow with dampingRatio 0.75.
    private let stiffness: CGFloat = 200
    private var damping: CGFloat { 2 * sqrt(stiffness) * 0.75 }

    func step(to now: Date, floaters: [Floater], levelId: String) {
        if self.levelId != levelId {
            self.levelId = levelId
            display = Dictionary(uniqueKeysWithValues: floaters.map {
                ($0.id, CGPoint(x: CGFloat($0.pos.x), y: CGFloat($0.pos.y)))
            })
            velocity = [:]
            ripples = []
            lastTick = now
            return
        }
        let dt = min(CGFloat(now.timeIntervalSince(lastTick ?? now)), 0.05)
        lastTick = now
        guard dt > 0 else { return }
        for floater in floaters {
            let target = CGPoint(x: CGFloat(floater.pos.x), y: CGFloat(floater.pos.y))
            var pos = display[floater.id] ?? target
            var vel = velocity[floater.id] ?? .zero
            let ax = stiffness * (target.x - pos.x) - damping * vel.dx
            let ay = stiffness * (target.y - pos.y) - damping * vel.dy
            vel.dx += ax * dt
            vel.dy += ay * dt
            pos.x += vel.dx * dt
            pos.y += vel.dy * dt
            // Settle when close and slow, so idle boards stop integrating.
            if abs(pos.x - target.x) < 0.001, abs(pos.y - target.y) < 0.001,
               abs(vel.dx) < 0.01, abs(vel.dy) < 0.01 {
                pos = target
                vel = .zero
            }
            display[floater.id] = pos
            velocity[floater.id] = vel
        }
        ripples.removeAll { now.timeIntervalSince($0.start) > 0.75 }
    }
}

struct PondBoardView: View {
    let state: GameState
    let hintCell: Pos?
    let skinId: String
    let padId: String
    let onTap: (Pos) -> Bool

    @Environment(\.palette) private var palette
    @State private var motion = BoardMotion()

    var body: some View {
        let spec = state.spec
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                motion.step(to: timeline.date, floaters: state.floaters, levelId: spec.id)
                draw(&ctx, size: size, now: timeline.date)
            }
        }
        .aspectRatio(CGFloat(spec.cols) / CGFloat(spec.rows), contentMode: .fit)
        .onTapGesture { location in
            tapped(at: location)
        }
    }

    private func geometry(in size: CGSize) -> (cell: CGFloat, originX: CGFloat, originY: CGFloat) {
        let spec = state.spec
        let cell = min(size.width / CGFloat(spec.cols), size.height / CGFloat(spec.rows))
        return (
            cell,
            (size.width - cell * CGFloat(spec.cols)) / 2,
            (size.height - cell * CGFloat(spec.rows)) / 2
        )
    }

    private func tapped(at location: CGPoint) {
        // The tap gesture reports in view coordinates; the canvas fills the view.
        let size = motion.lastSize
        guard size.width > 0 else { return }
        let (cell, originX, originY) = geometry(in: size)
        let pos = Pos(
            x: Int(floor((location.x - originX) / cell)),
            y: Int(floor((location.y - originY) / cell))
        )
        if onTap(pos) {
            motion.ripples.append((center: pos, start: Date()))
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, now: Date) {
        motion.lastSize = size
        let spec = state.spec
        let (cell, originX, originY) = geometry(in: size)

        func cellRect(_ pos: Pos) -> CGRect {
            CGRect(x: originX + CGFloat(pos.x) * cell, y: originY + CGFloat(pos.y) * cell, width: cell, height: cell)
        }

        let t = now.timeIntervalSinceReferenceDate
        let bobPhase = CGFloat(t.truncatingRemainder(dividingBy: 3.2) / 3.2) * 2 * .pi
        let flowPhase = CGFloat(t.truncatingRemainder(dividingBy: 1.4) / 1.4)
        let hintTri = CGFloat(t.truncatingRemainder(dividingBy: 1.3))
        let hintPulse = 0.75 + 0.4 * (hintTri < 0.65 ? hintTri / 0.65 : (1.3 - hintTri) / 0.65)

        // Water and its rim.
        for y in 0..<spec.rows {
            for x in 0..<spec.cols {
                let pos = Pos(x: x, y: y)
                if spec.terrainAt(pos) == .bank { continue }
                let deep = (x + y) % 2 == 0
                ctx.fill(Path(cellRect(pos)), with: .color(deep ? palette.waterDeep : palette.water))
            }
        }
        for y in 0..<spec.rows {
            for x in 0..<spec.cols {
                let pos = Pos(x: x, y: y)
                if spec.terrainAt(pos) == .bank { continue }
                drawWaterRim(&ctx, pos: pos, rect: cellRect(pos), palette: palette) {
                    spec.terrainAt($0) == .bank
                }
            }
        }

        // Currents flow under everything that floats.
        for (pos, dir) in spec.currents {
            drawCurrent(&ctx, rect: cellRect(pos), dir: dir, phase: flowPhase, palette: palette)
        }

        // Lily pads.
        for (pos, color) in spec.pads {
            drawPadStyle(&ctx, padId: padId, rect: cellRect(pos), palette: palette, ring: palette.padRing(color))
        }

        // Rocks.
        for y in 0..<spec.rows {
            for x in 0..<spec.cols {
                let pos = Pos(x: x, y: y)
                if spec.terrainAt(pos) == .rock {
                    drawRock(&ctx, rect: cellRect(pos), palette: palette)
                }
            }
        }

        // Ripples spread below the floaters.
        for fx in motion.ripples {
            let p = CGFloat(min(now.timeIntervalSince(fx.start) / 0.75, 1))
            let center = CGPoint(x: cellRect(fx.center).midX, y: cellRect(fx.center).midY)
            for ring in 0...2 {
                let radius = cell * (0.25 + p * 2.3 + CGFloat(ring) * 0.38)
                let alpha = max((1 - p) * (0.45 - CGFloat(ring) * 0.12), 0)
                if alpha > 0 {
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                        with: .color(palette.ripple.opacity(alpha)),
                        style: StrokeStyle(lineWidth: cell * 0.09 * (1 - p) + 1)
                    )
                }
            }
            if p < 0.3 {
                let r = cell * 0.12
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                    with: .color(palette.ripple.opacity((0.3 - p) * 2))
                )
            }
        }

        // Floaters, gliding between cells.
        for floater in state.floaters {
            let animated = motion.display[floater.id]
                ?? CGPoint(x: CGFloat(floater.pos.x), y: CGFloat(floater.pos.y))
            let rect = CGRect(
                x: originX + animated.x * cell,
                y: originY + animated.y * cell,
                width: cell,
                height: cell
            )
            let bob = sin(bobPhase + CGFloat(floater.id) * 1.7) * cell * 0.03
            let bobbed = rect.offsetBy(dx: 0, dy: bob)
            switch floater.kind {
            case .duck:
                if spec.padAccepts(floater.pos, floater.color) {
                    let r = cell * 0.5
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: rect.midX - r, y: rect.midY - r, width: r * 2, height: r * 2)),
                        with: .color(palette.accent.opacity(0.28))
                    )
                }
                drawFloaterSkin(&ctx, skinId: skinId, rect: bobbed, palette: palette, color: floater.color)
            case .turtle:
                drawTurtle(&ctx, bobbed, palette)
            }
        }

        // Hint: a pulsing ring on the suggested splash cell.
        if let hintCell {
            let rect = cellRect(hintCell)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let r = cell * 0.34 * hintPulse
            ctx.stroke(
                Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                with: .color(.white.opacity(0.85)),
                style: StrokeStyle(lineWidth: cell * 0.07)
            )
            let r2 = cell * 0.12
            ctx.fill(
                Path(ellipseIn: CGRect(x: center.x - r2, y: center.y - r2, width: r2 * 2, height: r2 * 2)),
                with: .color(.white.opacity(0.35))
            )
        }
    }
}
