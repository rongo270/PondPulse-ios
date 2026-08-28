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
- **Cosmetics are bought with coins, not money.** Only five things take real
  money: `premium`, `hints_50` and the three coin packs (`coins_100/250/500`).
  Every friend, pad, theme, decoration, sky and pond seat is priced in
  `CoinBank` and paid for out of a balance the campaign, the golden ponds, the
  daily pond, Rush and the pond's games all pay into. This replaced 23 cosmetic
  IAPs at $0.49-$0.99 — the same move Android made.
- **Purchases are real StoreKit 2** (`StoreManager.swift` + `Products.storekit`,
  5 products), with ids identical to the Android Play Billing ids. The payment
  sheet is the confirmation; consumables de-dupe by transaction id; refunds
  revoke and unequip; the shop has Restore Purchases. iOS is AHEAD of Android
  here — Android still grants locally (wire Play Billing there next).
- Pricing: premium $2.99 · hints_50 $0.99 · coin packs $0.99/$1.99/$3.99.
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
- To test purchases locally, run from Xcode — the shared scheme already selects
  `PondPulse/Products.storekit` as its StoreKit configuration.

## Store status

- `AppStore_Listing.md` (EN + HE; **still lists the retired 23 cosmetic IAPs —
  rewrite it for the five that remain**), `PRIVACY.md`,
  `SUPPORT.md` at project root; screenshots in `AppStore_Screenshots/`
  (6.9" iPhone + 13" iPad, store-exact sizes).
- Release archive builds clean (`1.0 (1)`); one copy sits in Xcode Organizer.
  Distribution upload is the manual Organizer step (App Store Connect login).

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

- Create the app record + the 5 IAPs in App Store Connect, after rewriting the
  IAP tables in `AppStore_Listing.md`; host PRIVACY/SUPPORT, upload via Organizer.
- Backport Play Billing + restore strings to Android.
- Game Center / iCloud sync — not on Android either; skip until Android has it.
