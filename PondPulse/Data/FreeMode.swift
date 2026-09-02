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

    /// Whether the **Unlock everything** switch is allowed to be on at all.
    ///
    /// It used to be `enabled` alone, and `enabled` is false here - so Settings
    /// drew the switch in a debug build, `ProgressStore` stored it on tap, and
    /// the property that reads it answered `false` for ever. A debug build is a
    /// build nobody pays with, so the switch is exactly as safe there as it was
    /// in closed testing; a release build with the economy on still has no path
    /// to it, because the section that holds it is not compiled in.
    static var unlockable: Bool {
        #if DEBUG
        return true
        #else
        return enabled
        #endif
    }

    /// The coin pile "Unlock everything" shows on top of the real balance.
    ///
    /// Shown, not banked - see `CoinBank`. It is folded into the *balance* in
    /// `AppViewModel`, never into `coinsGranted`, so turning the switch off puts
    /// the honest number straight back. Nothing is actually debited while it is
    /// on either (`ProgressStore.spending` hands the goods over untouched), so a
    /// tester cannot spend their way into a negative balance and leave it
    /// behind.
    static let debugCoins = 99_999

    /// Hints the same switch adds to the counter, for the same reason.
    static let debugHints = 999

    /// Marker dropped into the owned set while "Unlock everything" is on.
    ///
    /// It rides in the same set as the real product ids so every existing
    /// ownership check - including the ones that answer to stars, golden ponds
    /// or a daily streak rather than to a product id - sees it without growing a
    /// parameter. It is never written to storage: the set it joins is derived.
    static let unlockAllToken = "test_unlock_all"

    /// Whether a price is payable. Free mode says yes to all of them.
    ///
    /// "Unlock everything" needs no case here: it pays the price out of the
    /// `debugCoins` pile already folded into the balance the caller passes in.
    static func affordable(coins: Int, price: Int) -> Bool {
        enabled || coins >= price
    }
}
