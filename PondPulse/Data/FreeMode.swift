//
//  FreeMode.swift
//  PondPulse
//
//  A port of the Android data/FreeMode.kt - with the switch OFF.
//

import Foundation

/// The "everything is free" switch, and why iOS keeps it turned off.
///
/// PondPulse's economy is real - `CoinBank` prices every cosmetic, every hint
/// and every seat at the pond, and the campaign pays coins out against those
/// prices. Android is in closed testing, so over there this is `true` and
/// nothing is ever charged: a tester who has to grind for a friend never sees
/// the friend, and a price shown next to a product Play has never heard of is a
/// price that cannot be paid.
///
/// **iOS ships with the economy live.** The switch is ported anyway, in the same
/// shape and consulted from the same places, so that the two apps stay one code
/// change apart rather than one rewrite apart - and so that a TestFlight build
/// can be made free by flipping a single boolean.
///
/// What flipping `enabled` to `true` would do, in one list:
///
///  - Coin purchases (cosmetics, hints, pond seats, decorations, skies) always
///    succeed and debit nothing - see `ProgressStore.spend`.
///  - Prices read "Free" wherever one would be drawn.
///  - The premium upgrade is granted, so its levels, friends, pads and theme are
///    all in, and hints are unlimited.
///  - The premium card and the coin packs leave the shop: there is nothing left
///    for either of them to sell.
///
/// What it deliberately does *not* do: open every pond. Ponds still unlock in
/// order.
enum FreeMode {

    /// `false` on iOS - the economy is live. See the type comment before flipping.
    static let enabled = false

    /// Marker dropped into the owned set while "Unlock everything" is on.
    ///
    /// It rides in the same set as the real product ids so every existing
    /// ownership check - including the ones that answer to stars, golden ponds
    /// or a daily streak rather than to a product id - sees it without growing a
    /// parameter. It is never written to storage: the set it joins is derived.
    static let unlockAllToken = "test_unlock_all"

    /// Whether a price is payable. Free mode says yes to all of them.
    static func affordable(coins: Int, price: Int) -> Bool {
        enabled || coins >= price
    }
}
