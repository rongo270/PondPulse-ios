//
//  CoinBank.swift
//  PondPulse
//
//  A 1:1 port of the Android data/CoinBank.kt.
//

import Foundation

/// The coin economy, as arithmetic.
///
/// Coins come from two kinds of place and the difference decides how they are
/// stored. Most of them are *derived*: a pond's clear, its third star, a golden
/// pond, a daily, a best streak, a Splash Rush best. Every one of those reads off
/// a number that can only ever go up, so the payout is recomputed from progress
/// rather than banked - which is what makes it impossible to farm. Replaying a
/// pond you have already three-starred recomputes to the same total; it does not
/// add a second one.
///
/// The rest are *granted*: bought coin packs and the pond's mini games. Those
/// cannot be recomputed from anything, so they run as a lifetime total. Spending
/// is a third lifetime total, and the balance is simply
///
///     derived  +  granted  -  spent
///
/// There is no fourth number that could drift out of step with those three.
enum CoinBank {

    // MARK: - Earning

    /// Clearing a campaign pond, at any star count. Paid once, by derivation.
    static let clear = 30

    /// On top of `clear` when the pond is finished at three stars.
    static let threeStarBonus = 20

    /// A golden pond. Worth three ordinary clears - they are optional and rare.
    static let goldenPond = 150

    /// Each Daily Pond ever cleared.
    ///
    /// Half what the ×10 rescale would have made it, because the daily is now
    /// also a `Quests` board every day: clearing it usually pays a quest as
    /// well, and paying twice at full rate for one pond would have made the
    /// daily worth more than the pack it came out of.
    static let dailyClear = 60

    /// Each full week of the *best* daily streak.
    static let streakWeek = 250

    /// Weeks of streak that pay. Uncapped, a hundred-day streak would out-earn
    /// the whole campaign, and the streak already has cosmetics of its own.
    static let streakWeekCap = 8

    /// Splash Rush points that earn ten coins, read off the best score for a
    /// duration. 750 points is still what it takes to cap one.
    static let rushPointsPerTen = 15

    /// Most one Splash Rush duration's best can ever be worth.
    static let rushCap = 500

    /// What each coin pack grants. These are the real-money products.
    static let coinPacks = [1000, 2500, 5000]

    /// All the pond's mini games together can pay this much in one week.
    ///
    /// The cap is what lets the games pay at all. Every one of them is a toy you
    /// can replay forever, so without a ceiling the cheapest of them would set
    /// the price of everything in the shop. With one, a keen player empties the
    /// week in an afternoon and the pond goes back to being a pond.
    static let pondWeeklyCap = PondCatalog.boosted(1000)

    // MARK: - Spending

    /// One hint. The hint pack in the shop stays a real-money product.
    ///
    /// A bundle of five is 1750 coins - a little over a cheap friend, and about
    /// a week of quests. Hints are the one thing in the shop that is *spent*
    /// rather than owned, so they are deliberately dear against the cosmetics:
    /// a player who can buy their way past every pond has bought their way out
    /// of the game.
    static let priceHint = 350

    /// Hints sold in one coin purchase. Five rather than one: a shop row you
    /// have to tap seven times is a chore, and the pack above it already exists
    /// for anyone who wants more.
    static let hintBundle = 5

    /// Three bands for friends, two for pads and two for themes, rather than one
    /// price each. With thirty-odd items on the shelves a single price would make
    /// the whole catalogue one undifferentiated wall - and put the first purchase
    /// as far away as the last.
    static let priceSkin = 1500
    static let priceSkinUncommon = 2600
    static let priceSkinRare = 4000
    static let pricePad = 1300
    static let pricePadRare = 2200
    static let priceTheme = 3500
    static let priceThemeRare = 5500

    /// The top band on each shelf: the handful of things worth saving for.
    ///
    /// Deliberately well clear of the band below - 6500 against 4000, 4000
    /// against 2200 - because a top band a fifth dearer than the one under it is
    /// not a goal, it is a rounding error.
    static let priceSkinLegendary = 6500
    static let pricePadLegendary = 4000

    /// The ladder the campaign's old prizes moved onto, in ascending order.
    ///
    /// Twenty-one cosmetics used to arrive simply for reaching a level number,
    /// which meant a prize every five to ten ponds and a win card that spent
    /// more of its life handing something over than saying well done. They are
    /// bought now, and the golden ponds are the only place play alone still
    /// pays a cosmetic - which is what makes a golden pond worth the detour.
    ///
    /// A ladder rather than bands, because these are the one run of items whose
    /// order already means something: a friend that used to arrive at level 40
    /// is the cheap end and one that used to arrive at level 300 is the dear
    /// end, and pricing them flat would throw that away. Pads sit under friends
    /// throughout, the way every other band on the two shelves does.
    ///
    /// Each step is used exactly once, in shelf order.
    static let priceLadderSkin = [
        1000, 1200, 1400, 1700, 2000, 2300, 2700, 3100, 3600, 4200, 4900, 5800,
    ]

    static let priceLadderPad = [1000, 1100, 1300, 1500, 1800, 2100, 2500]

    /// Each seat past the three the pond starts with, in order. Rising prices,
    /// so the last seat is a long-term goal rather than a rounding error.
    static let slotPrices = [1200, 2200, 3500, 5000, 7000]

    /// Seats the pond holds before any are bought.
    static let baseSlots = 3

    static var maxSlots: Int { baseSlots + slotPrices.count }

    // MARK: - The rules

    /// What one campaign pond's stars are worth.
    static func levelCoins(stars: Int) -> Int {
        if stars <= 0 { return 0 }
        if stars >= 3 { return clear + threeStarBonus }
        return clear
    }

    /// A golden pond pays a flat rate for being cleared at all.
    static func goldenCoins(stars: Int) -> Int { stars > 0 ? goldenPond : 0 }

    static func dailyCoins(clears: Int) -> Int { max(clears, 0) * dailyClear }

    static func streakCoins(bestStreak: Int) -> Int {
        min(max(bestStreak, 0) / 7, streakWeekCap) * streakWeek
    }

    static func rushCoins(best: Int) -> Int {
        min(max(best, 0) * 10 / rushPointsPerTen, rushCap)
    }

    /// Everything progress alone is worth, recomputed from scratch.
    ///
    /// `starsOf` is asked for each id rather than handed a map so that the caller
    /// decides what counts as a campaign pond and what counts as a golden one -
    /// the two pay differently and share a star ledger.
    static func derived(
        campaignIds: [String],
        goldenIds: [String],
        starsOf: (String) -> Int,
        dailyClears: Int,
        bestStreak: Int,
        rushBests: some Collection<Int>,
        /// What `Achievements` is currently worth. Passed in rather than
        /// computed here so this file stays arithmetic over its arguments - but
        /// it is summed *here*, because the balance rule has exactly one home
        /// and a payout arriving by any other route is one nothing recomputes.
        achievementCoins: Int = 0
    ) -> Int {
        campaignIds.reduce(0) { $0 + levelCoins(stars: starsOf($1)) }
            + goldenIds.reduce(0) { $0 + goldenCoins(stars: starsOf($1)) }
            + dailyCoins(clears: dailyClears)
            + streakCoins(bestStreak: bestStreak)
            + rushBests.reduce(0) { $0 + rushCoins(best: $1) }
            + achievementCoins
    }

    /// What the player can spend right now.
    ///
    /// Clamped at zero rather than allowed to read as a debt. The derived half is
    /// recomputed against today's level list, so a pond retired between versions
    /// takes its old contribution back out - the player keeps whatever they
    /// already bought, because they earned those coins at the time, and the
    /// balance simply floors.
    static func balance(derived: Int, granted: Int, spent: Int) -> Int {
        max(derived + granted - spent, 0)
    }

    static func canAfford(derived: Int, granted: Int, spent: Int, price: Int) -> Bool {
        price > 0 && price <= balance(derived: derived, granted: granted, spent: spent)
    }

    /// The new lifetime-spent total after buying something for `price`, or nil
    /// when the balance is short - in which case nothing at all is written and
    /// the purchase is simply refused.
    static func spend(derived: Int, granted: Int, spent: Int, price: Int) -> Int? {
        canAfford(derived: derived, granted: granted, spent: spent, price: price)
            ? spent + price
            : nil
    }

    /// What a mini game actually pays, given what the week has already paid out.
    ///
    /// The cap is enforced here rather than at the game, so a game never has to
    /// know about it and every game is capped the same way. A run that lands past
    /// the ceiling still pays the part that fits, never nothing at all.
    static func pondPayout(alreadyThisWeek: Int, want: Int) -> Int {
        min(max(want, 0), max(pondWeeklyCap - alreadyThisWeek, 0))
    }

    /// The week `epochDay` falls in.
    ///
    /// Plain sevens from the epoch, not a calendar week: which weekday a week
    /// starts on differs by locale, and a ceiling that moved when the phone
    /// changed region would be a ceiling the player could shop for.
    static func weekOf(epochDay: Int) -> Int {
        Int((Double(epochDay) / 7.0).rounded(.down))
    }

    /// Price of the seat that takes the pond from `slots` friends to one more.
    static func slotPrice(slots: Int) -> Int? {
        let index = slots - baseSlots
        guard index >= 0, index < slotPrices.count else { return nil }
        return slotPrices[index]
    }
}
