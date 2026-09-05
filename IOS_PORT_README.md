# PondPulse — iOS port

SwiftUI port of `~/AndroidStudioProjects/PondPulse` (Kotlin + Compose). The
LOGIC is mirrored 1:1 — engine, solver, level data, unlock rules, progress
keys — while the UI is rebuilt to feel native on iOS (SF Rounded type, SF
Symbols, spring animations, `UIImpactFeedbackGenerator` haptics, native
alerts/sheets). Deployment floor iOS 18, portrait, bundle `com.rongo.pondpulse`.

## Structure map (Android → iOS)

| Android (`app/src/main/java/com/rongo/pondpulse`) | iOS (`PondPulse/`) |
|---|---|
| `engine/Model.kt`, `Engine.kt`, `Solver.kt` | `Engine.swift` (all `nonisolated` so the solver runs off-main) |
| `levels/LevelParser.kt` | `LevelParser.swift` |
| `levels/Levels.kt` (maps + pars) | `LevelMaps1.swift` *(generated)* + `Levels.swift` (pack assembly) |
| `levels/MoreLevels.kt` | `LevelMaps2.swift` *(generated)* |
| `levels/NewLevels.kt` | `LevelMaps3.swift` *(generated)* |
| `shop/Catalog.kt` | `Catalog.swift` |
| `data/ProgressRepository.kt` | `ProgressStore.swift` (UserDefaults, **identical keys**: `stars_<id>`, `rush_best_<sec>`, `owned_products`, `hints_left`, `hinted_levels`, `selected_theme/skin/pad`, `haptics`) |
| `ui/theme/Palettes.kt` | `PaletteData.swift` *(generated)* + `Palettes.swift` |
| `ui/theme/Theme.kt` | `Palettes.swift` (`\.palette` environment) |
| `res/values*/strings.xml` (16 locales) | `L10nTables.swift` *(generated)* + `Strings.swift` (runtime-switchable, LineQuest pattern; keys identical to Android) |
| `ui/AppViewModel.kt` | `AppViewModel.swift` (`ObservableObject` + `@Published`) |
| `ui/GameController.kt` | `GameController.swift` |
| `ui/FloaterArt.kt` | `FloaterArt.swift` (GraphicsContext; 15 skins, 13 pads, turtle, rock, currents, rim) |
| `ui/PondBoard.kt` | `PondBoardView.swift` (Canvas + TimelineView, spring glide) |
| `ui/Components.kt` | `Components.swift` |
| `ui/HomeScreen.kt` | `HomeView.swift` (living pond: glide/wrap/bounce physics, hatch easter egg) |
| `ui/GameScreen.kt` | `GameView.swift` |
| `ui/PacksScreen.kt` | `PacksView.swift` |
| `ui/PackLevelsScreen.kt` | `PackLevelsView.swift` (stage pager, level tiles, golden-pond row) |
| `ui/RushScreen.kt` | `RushView.swift` |
| `ui/DailyScreen.kt` | `DailyView.swift` |
| `ui/SettingsScreen.kt` | `SettingsView.swift` |
| `ui/ShopScreen.kt` (+ `ShopShelfScreen`) | `ShopView.swift` (`ShopView` + `ShopShelfView`) |
| `ui/PondScreen.kt` | `PondView.swift` (My Pond: friends, seats, games, roster) |
| `ui/DecorateScreen.kt` | `DecorateView.swift` (drag-to-place, zone rule, sky picker) |
| `ui/PondGames.kt` | `PondGamesView.swift` (the four mini games + their shell) |
| `ui/PondArt.kt` | `PondArt.swift` (16 decorations, 6 skies, the basin) |
| `ui/FloaterArtMore.kt` | `FloaterArtMore.swift` (the later friends and pads) |
| `ui/CoinUi.kt` | `CoinUi.swift` (the coin, the balance chip, a price) |
| `pond/PondCatalog.kt` | `PondCatalog.swift` |
| `data/CoinBank.kt` | `CoinBank.swift` (the whole economy: earn rates, prices, caps) |
| `data/FreeMode.kt` | `FreeMode.swift` (**off** on iOS — see below) |
| `ui/WinCelebration.kt` | `WinCelebration.swift` |
| `MainActivity.kt` | `PondPulseApp.swift` (root router, theme + RTL environment) |

## Generated files — do not edit by hand

`LevelMaps1/2/3.swift`, `L10nTables.swift` and `PaletteData.swift` are produced
from the Android sources by `tools/convert_levels.py`, `tools/convert_strings.py`
(and the palette block inside the tools folder). When the Android app gains
levels/strings/themes, re-run the scripts instead of editing the Swift.
`tools/make_icon.py` rasterizes the Android launcher vector into the AppIcon.

## Parity notes

- 450 levels, 9 packs, 30 stages, 30 golden ponds, same play order, premium from
  global level 301.
- **Cosmetics are bought with coins, not money.** Thirteen products take real
  money: `premium`, `hints_50`, the three coin packs (`coins_100/250/500`), the
  five special friends and the three money themes.
  Every friend, pad, theme, decoration, sky and pond seat is priced in
  `CoinBank` and paid for out of a balance the campaign, the golden ponds, the
  daily pond, Rush and the pond's games all pay into. This replaced 23 cosmetic
  IAPs at $0.49-$0.99 — the same move Android made.
- **Purchases are real StoreKit 2** (`StoreManager.swift` + `PondPulse.storekit`
  at the project root, 13 products), with ids identical to the Android Play
  Billing ids. The payment sheet is the confirmation; consumables de-dupe by
  transaction id; refunds revoke and unequip; the shop has Restore Purchases.
  iOS is AHEAD of Android here — Android still grants locally (wire Play Billing there next).
- Pricing: premium $2.99 · hints_50 $1.99 · coin packs $0.99/$1.99/$3.99 ·
  special friends $0.99 · Autumn Gold $1.99 · Opal/Ember $2.99.
  Display prices come from the App Store once loaded; `Catalog`'s strings are
  the offline fallback.
- **`FreeMode.enabled` is `false` on iOS.** Android ships it `true` for closed
  testing, which makes everything free and puts a Testing section in Settings.
  The switch is ported in the same shape and read from the same places, so the
  two apps stay one boolean apart — flip it for a free TestFlight build.
- 16 languages, in-app switchable, Hebrew/Arabic flip to RTL instantly (Android
  recreates the activity; iOS applies live). Two iOS-only keys (`shop_restore`,
  `shop_restored`) live in `L10n.extras` — backport to Android with billing.
- DEBUG launch overrides, the twin of Android's `pp_*` intent extras:
  `SIMCTL_CHILD_PP_START_LEVEL=<n>` jumps into a level,
  `SIMCTL_CHILD_PP_START_PACK=pack3` opens one pack's ponds,
  `SIMCTL_CHILD_PP_START_SCREEN=packs|shop|rush|daily|pond|decorate|settings`
  opens a screen, `SIMCTL_CHILD_PP_START_GAME=chain|herd|seek|target` opens a
  mini game, `SIMCTL_CHILD_PP_START_BONUS=b-1` opens a golden pond,
  `SIMCTL_CHILD_PP_PREMIUM=1` grants premium and `SIMCTL_CHILD_PP_COINS=<n>`
  a balance, both in memory only.
- To test purchases locally, run from Xcode — the shared scheme selects
  `PondPulse.storekit` (project root, all 13 products) as its StoreKit
  configuration. It used to point at a `PondPulse/Products.storekit` that had
  been left behind at five products, so the eight newer ones silently failed to
  load in every debug run; that file is gone.

## Store status

- **13 in-app purchases**, and `PondPulse.storekit`, `Catalog.swift` and
  `AppStore_Listing.md` now all agree on which 13 (rewritten 2026-09-04 — the
  doc had been stuck on "five products, and only five" since the coin economy
  landed). `PondPulse/Products.storekit` is deleted; the live config is the one
  at the project root.
- **Three ids no longer say what they grant, and cannot be renamed.** `hints_50`
  gives 25 hints; `coins_100` / `coins_250` / `coins_500` give 1,000 / 2,500 /
  5,000. The ids are live and shared with Android's Play Billing, so the *display
  name* carries the real number instead — already fixed in `PondPulse.storekit`,
  and it has to be typed that way into App Store Connect too.
- `PRIVACY.md` and `SUPPORT.md` sit at the project root and are **not hosted
  anywhere yet**. App Store Connect will not accept the submission without a
  public URL for each. GitHub Pages on the repo is the cheap answer.
- Screenshots in `AppStore_Screenshots/` — 6.9" iPhone (1320x2868) and 13" iPad
  (2064x2752), both store-exact.
- Release archive builds clean at `1.0 (1)` with **zero warnings**. Distribution
  upload is the manual Organizer step and **Ron does it, not Claude** — the App
  Store Connect key is only in play afterwards, on Ron's say-so.

## Release audit, 2026-09-04 — what was checked and what it cost

The pre-upload pass: remove the credit, prove nothing crashes, prove nothing can
be farmed. **Two source files changed. Everything else was verification**, and
the point of writing it down is so the next session does not pay for it twice.

### The two real changes

- **"Made with ❤ by Rongo" is gone**, from all 16 `settings_about` strings. It
  was stripped in `PondPulse/Localization/L10nTables.swift` *and* in Android's
  16 `values*/strings.xml`, because the iOS table is generated — editing only
  the Swift side would have let the next `tools/convert_strings.py` run put the
  credit straight back. 32 lines, 0 leftovers (`grep -c "❤"` → 0 both sides).
- **`ProgressStore.debugTools` is gated on `FreeMode.unlockable`**, the way
  `unlockAll` next to it always was. The switch that writes the key is only
  *drawn* in a debug build, but the key outlives the build that wrote it: a
  device that ran a debug build with the tools on and then took a release build
  over the top of it kept the stored `true`, and a shipped pond would have grown
  a "skip this level" button. Reading it through the gate makes release answer
  `false` whatever is on disk. This was the only hole the audit actually found.

Plus eight warning fixes with no behaviour attached: four `PondCatalog` product-id
builders marked `nonisolated` (they are string concatenation, but
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` put them on the main actor, so
passing one *by reference* — Decorate hands `waterProductId` to `surfaceStrip` —
read as an isolation crossing), and six `var` → `let` in the art files. **Release
now builds with zero warnings**; keep it there.

### What was proven, so it need not be re-proven

Everything below ran headless. `xcrun swiftc` compiles the logic files for macOS
without any UI dependency — the same trick as *Verifying a level port* below, and
the way to test anything in `Data/` or `Game/` without a simulator.

- **All 480 ponds** (450 campaign + 30 golden): parse, unique ids, no two
  floaters on a cell, everything on water, budget ≥ par, none start won or
  stranded, packs tile exactly. **Every pond is solvable inside its own budget
  and every recorded par is the BFS optimum.**
- **The economy, 9 scenario groups, 0 failures.** Replaying a cleared pond 50×
  pays nothing extra (derived coins are recomputed, never banked); a worse replay
  never downgrades; spending debits exactly the price; overspend / zero / negative
  prices are refused with no state written; the mini-game weekly cap holds
  exactly and resets on the next week; quests and the daily each pay once per day;
  golden prizes pay once; reset keeps money purchases and drops coin ones; hints
  cannot go negative. **There is no loophole that turns play into free coins.**
- **Daily pond over 7,300 days** — always in range, never repeats back to back,
  uses all 300 ponds evenly (24-25 each); negative and far-future days safe.
  **Quest boards over 10,950 days** — always 3 distinct kinds, positive goals,
  never pre-completed, kinds within 23-26%.
- **All 6 runtime traps proven unreachable**: `Engine`'s `precondition` and its
  two `Dictionary(uniqueKeysWithValues:)`, `LevelParser`'s `fatalError` on an
  unknown tile (checked against all 480 maps), and the force unwraps. Remember
  `assert` is the *only* one of these stripped in Release.
- **Localization**: 0 format-argument mismatches across 16 languages; every
  missing key is DEBUG-only and falls back to English.
- **The three dev switches are hard-closed in Release**: `FreeMode.enabled`,
  `FreeMode.unlockable`, `Catalog.cosmeticsUnlocked`.
- **StoreKit**: only `.verified` transactions are processed, consumables are
  de-duped by transaction id in `handled_hint_transactions`, revocation routes to
  `onRevoked`, Restore Purchases is wired.
- No network code, no debug prints, no TODOs. Icon 1024×1024, no alpha. Release
  build installs, launches, and renders all 11 screens on the simulator.
- The `AchievementsView` / `@EnvironmentObject` crash report from 2026-09-02 is
  **stale** — neither symbol exists in the codebase any more.

### Two things left open, deliberately

- **A fresh install cannot enter the Pond.** `pondMinFriends` is 3 and a new
  player owns 2 free skins, so pond quests are unreachable until they buy or earn
  a third friend. Over 3,650 days, **75.1%** of quest boards carry at least one
  pond-gated quest — which blocks that day's "finish all 3" bonus — and **2.2%**
  are pond-gated on all three. Fix is one of: start with 3 friends, drop
  `pondMinFriends` to 2, or exclude pond quests until the pond is open. It is a
  design call, so it was left to Ron.
- **iPad landscape is untested.** iPhone is portrait-only; iPad allows all four
  orientations. Nothing could drive a rotation — the simulator refused
  AppleScript (`osascript is not allowed assistive access`, -1719) — so landscape
  was never seen. The layouts are shrink-to-fit and scroll-based so they should
  adapt, but the cheap certain answer is locking iPad to portrait too.

### Gotchas worth keeping

- `xcodebuild` is not on the path: the active developer dir is
  `/Library/Developer/CommandLineTools`. Prefix commands with
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` rather than changing
  Ron's global `xcode-select`.
- A standalone `swiftc` harness needs its entry file named `main.swift`, and
  `ProgressStore.swift` drags in `Strings.swift` + `L10nTables.swift` to compile.
- Simulator UI cannot be driven from here (no assistive access). Screens were
  swept with `SIMCTL_CHILD_PP_*` DEBUG launch overrides plus `simctl` screenshots.

## iOS-only, 2026-09-04 — shop shape and the hint economy

Ron's calls, made on iOS first. **Android does not have any of this yet**; port
it back before the two are compared again.

- **The shop has two tabs.** *Pond* is the cosmetics - friends, lily pads,
  themes - and *Premium* is the three things that take real money: the upgrade,
  the coin packs, and the hint pack under them. One scroll put the money cards
  above the shelves, so every visit to buy a lily pad opened on an upsell. Both
  tab labels reuse strings the app already had (`home_pond`, `shelf_tab_premium`),
  so nothing needed translating.
- **Settings can switch theme, lily pad and friend.** Three rows under Language,
  each opening a grid of what the player *owns* and nothing else - prices,
  browsing and everything locked stay in the shop, and the picker's only exit is
  a "Find more in the shop" button onto that shelf. The rows reuse the shop's own
  three headings, and the theme row wears a colour swatch rather than
  `ThemePreview`, which at 34pt was a second, blurrier duckling.
  Dusk Pond is still what an install opens on.
- **The hint economy was re-tuned.** An install starts with **10** hints, not
  150; the pack is **25** hints for **$1.99**, not 50 for $0.99; five hints cost
  **1750 coins** (`CoinBank.priceHint` 350), not 750. 150 free hints was a pile
  nobody could spend, which made the counter furniture and the pack unsellable.
  - The product id stays `hints_50`. It is live in App Store Connect and shared
    with Android's Play Billing id; what a pack grants is what a re-tune gets to
    change, what it is called is not - the same rule the coin packs keep.
  - `economy_version` 3 clamps a pre-existing save's hint pile to 10, so a
    tester carrying 149 of them can actually see the economy. **It takes hints
    off anyone who had already bought some — drop that block rather than ship it
    to players who have paid for a pack.**
  - `shop_hints_desc` had "50" written into the sentence in all 16 languages. It
    takes the pack size as `%1$d` now; that one edit was made in the Android
    `strings.xml` so the generated table stays the source of truth.

## Sync with Android, 2026-09-04

Android's `start to public it` (859023a) and the three `coins and full screen`
commits, brought over.

- **Nothing is pinned to a level number any more.** `Unlock.levelReward` is
  gone, and the twenty-one cosmetics that used to arrive for reaching a level
  moved onto `CoinBank.priceLadderSkin` (12 rungs, 1000→5800) and
  `priceLadderPad` (7 rungs, 1000→2500), cheapest where the level was lowest.
  The Tadpole is free from the first launch and Jungle Mist is a coin theme.
  Each ladder step is used exactly once, in shelf order.
- **The shop's shelves lost the Play tab and gained Coins.** Everything with a
  price sits in one place, cheapest first; Earn is golden ponds and daily
  streaks only. Yours holds the Duckling and the Lily Pad from launch.
- **The pond's roster is cut into six sections** along the same ladder, so the
  collection and the shelf describe the catalogue the same way.
- **Quests and milestones were halved** (a day is 240 coins, not 500; the nine
  ladders total 7,300, not 14,890) — the shop stops being a shop the moment
  turning up covers it.
- **The win card stopped grading the win.** A heading and a line drawn at random
  from `win_titles`/`win_lines`, so 450 ponds do not all end the same way, and a
  prize is only celebrated when that clear is what actually opened it.
- **The pack gallery and the level grid stand on real water** (`BoardArt.swift`,
  the port of Android's `ui/art/BoardArt.kt`): a pack card carries a strip whose
  depth is its difficulty, and a stage is laid out on a banked pond with reeds.
  Level tiles are the player's own lily pad now, with the number on the pad and
  the stars floating under it. Neither drawing may ever read a level — a pond
  solved off the level grid is a pond you no longer have to solve.
- **Settings opens with the language row, carrying a flag.** A player who has
  the game in a language they cannot read cannot read "Language" either.
- Fixed on the way through, both iOS-only:
  - the three coin packs were being sold under ids built from their *amounts*
    (`coins_1000/2500/5000`), which matched neither Android nor the StoreKit
    config. They are written out now, as Android writes them.
  - six of the twelve quest kinds drew their own storage key instead of a
    sentence (`quest_rushScore` for `quest_rush_score`), because the enum's
    camel-cased case names were being used as string keys.
- `tools/convert_strings.py` now carries Android's `<string-array>` across
  (`L10n.arrayTables`, `Strings.array(_:)`), and `tools/convert_levels.py` was
  repointed at the renamed `LevelMaps1to10/11to20/21to30.kt` — it had been
  unrunnable since Android's "order part 1". Level data regenerates byte for
  byte, so no pond had drifted.

## Sync with Android, 2026-08-28

Android's v1.1 (versionCode 2) work, brought over in six commits.

- **Coins.** `CoinBank` is the whole economy in one file — what a clear, a
  three-star, a golden pond, the daily pond and a Rush run pay, what every
  cosmetic costs, and the weekly ceiling on what the pond's games can pay. The
  balance is *derived* from progress plus what was granted minus what was spent,
  so it survives a reinstall the same way stars do.
- **My Pond** (`PondView`). The friends you own live on real water: a tap
  splashes and shoves them, they glide and stop where the water leaves them.
  Opens at three friends owned. It absorbed the old Collection screen as its
  roster panel, and it is where the seats, the games and Decorate are reached.
- **Decorate** (`DecorateView`). 16 decorations and 6 skies. Tapping something
  you do not own puts it on the water as a draggable ghost, so you see it before
  you pay; the shore/water zone rule is enforced under the finger, so a dock
  dragged over open water slides back to the nearer bank. Positions are saved
  per decoration — two ponds with the same seven things do not look alike.
- **Four mini games** (`PondGamesView`): Ripple Chain, Duckling Round-Up,
  Hide & Seek and Splash Target, sharing one intro/HUD/results shell. Each keeps
  its simulation in a plain engine class stepped once a frame from inside the
  screen's `Canvas` — which is also what makes the `Canvas` redraw at all; a
  game stepped from an `onChange` beside it captures nothing that changes
  between frames, and SwiftUI draws it once and leaves it. They pay coins
  against a small weekly cap: toys first, faucets a distant second.
- **The Daily Pond** (`DailyView`) and its streak, plus streak-unlocked friends
  (`Unlock.streakReward`).
- **The shop split into shelves** (`ShopShelfView`), the golden-pond prize ladder
  shown on the pack pages, and level tiles that mark which ponds pay a prize.
- **The home menu is two rows**, with the Daily Pond and My Pond as tiles, and
  the Splash button measures its own top so nothing swims in behind it.
- The catalogue grew to 36 friends, 22 pads and 12 themes.
- `LevelParser.budget`'s floor dropped from three to zero, which makes nine
  early ponds (1-8..1-13, 22-1, 22-8, 22-10) exactly par — three stars or
  nothing. None of them carries a teaching tip, which is the Android invariant.

## Sync with Android, 2026-08-18

Android moved a long way after the July port; this brought iOS level with it.

- **Ducklings settle.** A duckling on a pad it accepts is home for good: ripples
  and currents no longer move it, it just becomes an obstacle. `LevelSpec.isSettled`
  plus the two dead-end proofs (`GameState.stranded` over Hall's condition, and
  `Engine.hasUnreachablePad`) and `Solver.isProvablyLost` for the exhaustive one.
  A pond that can no longer be won now says so and offers an undo instead of
  letting the player splash on.
- **All 450 levels were redrawn** on Android and regenerated here, plus the
  **30 golden bonus ponds** (`BonusMaps.swift`) and the measured toughness table
  (`Toughness.swift`) that decides play order. Star bands widened to par + 2 for
  two stars, so one star is reachable inside the budget.
- **Two-tier navigation.** Nine packs of 37-73 ponds, each cut into three or four
  browsable stages of 10-20, each stage closed by a golden pond. `PacksView` is
  the nine-card gallery; `PackLevelsView` is new — stage tabs, the level grid, the
  golden-pond row and a pack stepper.
- **Wrong level opening (fixed).** The old packs list nested `ForEach(rows, id: \.offset)`
  inside a `LazyVStack`, so every expanded pack numbered its rows 0,1,2… and
  SwiftUI treated different packs' rows as the same view. With two packs open the
  second one's grid rendered the first one's leaves, and tapping "31" opened
  someone else's pond. Identity is now the pack and the level id, never a row index.
- Golden cosmetics (`Unlock.bonusReward`): Golden Pond theme at 10 ponds, Gosling
  skin at 20, Golden Lily pad at 3. Clearing a golden pond pays 5 hints, once ever,
  tracked separately from stars so a progress reset doesn't reprint the reward.
- The shop now reads as free during early access throughout — the hint pack was
  the one card still quoting $0.99 while every other surface said free. StoreKit
  plumbing is untouched, so flipping back is one constant in `Catalog`.

### Verifying a level port

`tools/convert_levels.py` moves the data; the check that the *engine* agrees with
Android is to solve every pond and confirm BFS optimal == par (Android's
`LevelDoctorTest` invariant), then replay the solver's own line and confirm it
wins under the live rules. The engine has no UI dependencies, so it compiles
standalone:

```bash
xcrun swiftc -O -o /tmp/verify PondPulse/Game/Engine.swift \
  PondPulse/Game/LevelParser.swift PondPulse/Levels/*.swift main.swift
```

Last run (2026-08-28, after the budget floor change): 450 levels + 30 bonus
ponds, 9 packs, 0 problems — every pond's BFS optimum equals its recorded par,
every solver line replays to a win under the live rules, and none of it needs
more splashes than the pond hands out.

## Still to do

- Host `PRIVACY.md` + `SUPPORT.md` at public URLs — the one hard blocker left.
- Create the app record and all **13** IAPs in App Store Connect, using the
  tables in `AppStore_Listing.md` (now correct), and remember the coin/hint
  display names carry the real amounts, not the ones in the ids.
- Archive and upload via Organizer. **Ron uploads the bundle**; Claude may only
  touch the App Store Connect key afterwards, and only when Ron says so.
- Decide the two open questions in the audit section above: the new-player pond
  gate, and whether iPad should be locked to portrait.
- Backport Play Billing + restore strings to Android.
- Port the 2026-09-04 iOS-only shop/settings/hint work back to Android.
- Game Center / iCloud sync — not on Android either; skip until Android has it.
