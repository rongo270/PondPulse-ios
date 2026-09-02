//
//  PondLayout.swift
//  PondPulse
//
//  A whole pond, saved - a 1:1 port of the Android data/PondLayout.kt.
//
//  Not just where the decorations sit: a pond is the water it sits in, the bank
//  around it, the sky over it and who is swimming in it, and a "saved layout"
//  that restored the furniture but left the snow falling would restore something
//  the player never arranged.
//
//  ### The format
//
//  One preferences string per slot, `key=value` fields joined by `|`:
//
//      sky=night|water=deep|shore=snow|cast=frog,koi|out=bench|at=reeds:0.2,0.3|on=reeds
//
//  One string rather than several keys per slot because a layout is only ever
//  read and written whole. Every field is optional on the way back in: a layout
//  saved before the water could be changed still loads, and simply keeps the
//  default water - which is the behaviour that matters, because these live on
//  players' devices and the catalogue keeps growing.
//

import CoreGraphics
import Foundation

struct PondLayout: Equatable {
    var weather: String = "day"
    var water: String = "clear"
    var shore: String = "meadow"
    var friends: [String] = []
    var stored: Set<String> = []
    var spots: [String: CGPoint] = [:]

    /// The decorations that were actually on the pond when it was saved.
    ///
    /// `spots` is not the same question: it only ever holds things that have
    /// been *dragged*, so a bench bought and left at its catalogue anchor is
    /// absent from it. Restoring does not need this - `stored` governs what the
    /// live pond draws - but the thumbnail does, or two saved ponds full of
    /// untouched furniture would draw as two empty ponds.
    ///
    /// Empty means "saved before this field existed": the thumbnail then falls
    /// back to `spots`, which is exactly what it used to draw.
    var inPond: Set<String> = []

    /// True for a slot nothing has ever been saved into.
    var isEmpty: Bool { friends.isEmpty && spots.isEmpty && stored.isEmpty && inPond.isEmpty }

    /// What the thumbnail should draw, newest field first.
    var drawable: Set<String> { inPond.isEmpty ? Set(spots.keys) : inPond }

    func encoded() -> String {
        [
            "sky=\(weather)",
            "water=\(water)",
            "shore=\(shore)",
            "cast=" + friends.joined(separator: ","),
            "out=" + stored.joined(separator: ","),
            "at=" + spots.map { "\($0.key):\($0.value.x),\($0.value.y)" }.joined(separator: ";"),
            "on=" + inPond.joined(separator: ","),
        ].joined(separator: "|")
    }

    /// Reads one back, ignoring anything it does not recognise.
    ///
    /// Deliberately total: it never throws and never returns nil. A layout is
    /// cosmetic, and a saved pond that fails to parse should cost the player the
    /// pond, not the launch.
    static func decode(_ raw: String?) -> PondLayout {
        guard let raw, !raw.isEmpty else { return PondLayout() }
        var fields: [String: String] = [:]
        for field in raw.split(separator: "|", omittingEmptySubsequences: false) {
            guard let eq = field.firstIndex(of: "=") else { continue }
            let key = String(field[field.startIndex..<eq])
            if key.isEmpty { continue }
            fields[key] = String(field[field.index(after: eq)...])
        }
        func list(_ key: String) -> [String] {
            (fields[key] ?? "").split(separator: ",").map(String.init).filter { !$0.isEmpty }
        }
        var spots: [String: CGPoint] = [:]
        for entry in (fields["at"] ?? "").split(separator: ";") {
            let parts = entry.split(separator: ":")
            guard parts.count == 2 else { continue }
            let xy = parts[1].split(separator: ",")
            guard xy.count == 2, let x = Double(xy[0]), let y = Double(xy[1]) else { continue }
            spots[String(parts[0])] = CGPoint(x: x, y: y)
        }
        func nonEmpty(_ key: String, _ fallback: String) -> String {
            let v = fields[key] ?? ""
            return v.isEmpty ? fallback : v
        }
        return PondLayout(
            weather: nonEmpty("sky", "day"),
            water: nonEmpty("water", "clear"),
            shore: nonEmpty("shore", "meadow"),
            friends: list("cast"),
            stored: Set(list("out")),
            spots: spots,
            inPond: Set(list("on"))
        )
    }
}
