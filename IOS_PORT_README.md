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
| `ui/RushScreen.kt` | `RushView.swift` |
| `ui/SettingsScreen.kt` | `SettingsView.swift` |
| `ui/ShopScreen.kt` | `ShopView.swift` |
| `ui/WinCelebration.kt` | `WinCelebration.swift` |
| `MainActivity.kt` | `PondPulseApp.swift` (root router, theme + RTL environment) |

## Generated files — do not edit by hand

`LevelMaps1/2/3.swift`, `L10nTables.swift` and `PaletteData.swift` are produced
from the Android sources by `tools/convert_levels.py`, `tools/convert_strings.py`
(and the palette block inside the tools folder). When the Android app gains
levels/strings/themes, re-run the scripts instead of editing the Swift.
`tools/make_icon.py` rasterizes the Android launcher vector into the AppIcon.

## Parity notes

- 450 levels, 30 packs, same play order, premium from global level 301.
- **Purchases are real StoreKit 2** (`StoreManager.swift` + `Products.storekit`,
  23 products). Product ids are identical to the Android Play Billing ids
  (`premium`, `hints_50`, `theme_*`, `skin_*`, `pad_*`), so the catalogs stay in
  sync. The payment sheet is the confirmation; consumable hint packs de-dupe by
  transaction id; refunds revoke and unequip; the shop has Restore Purchases.
  iOS is AHEAD of Android here — Android still grants locally (wire Play
  Billing there next).
- Pricing: premium $2.99 · hints_50 $0.99 · themes $0.99 · skins $0.49 ·
  pads $0.49. Display prices come from the App Store once loaded; `Catalog`'s
  strings are the offline fallback.
- 16 languages, in-app switchable, Hebrew/Arabic flip to RTL instantly (Android
  recreates the activity; iOS applies live). Two iOS-only keys (`shop_restore`,
  `shop_restored`) live in `L10n.extras` — backport to Android with billing.
- DEBUG launch overrides mirror linequest: `SIMCTL_CHILD_PP_START_LEVEL=<n>`
  jumps into a level, `SIMCTL_CHILD_PP_START_PACK=pack3` opens one pack's ponds,
  `SIMCTL_CHILD_PP_START_SCREEN=packs|shop|rush|settings` opens a screen, and
  `SIMCTL_CHILD_PP_PREMIUM=1` grants premium in memory.
- To test purchases locally, run from Xcode — the shared scheme already selects
  `PondPulse/Products.storekit` as its StoreKit configuration.

## Store status

- `AppStore_Listing.md` (EN + HE, all 23 IAPs with prices), `PRIVACY.md`,
  `SUPPORT.md` at project root; screenshots in `AppStore_Screenshots/`
  (6.9" iPhone + 13" iPad, store-exact sizes).
- Release archive builds clean (`1.0 (1)`); one copy sits in Xcode Organizer.
  Distribution upload is the manual Organizer step (App Store Connect login).

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

Last run: 450 levels + 30 bonus ponds, 9 packs, 30 stages, 0 problems — every
pond solvable at par, none starting dead, and every tile's printed number
resolving back to the pond it opens.

## Still to do

- Create the app record + 23 IAPs in App Store Connect (tables in
  `AppStore_Listing.md`), host PRIVACY/SUPPORT, upload via Organizer.
- Backport Play Billing + restore strings to Android.
- Game Center / iCloud sync — not on Android either; skip until Android has it.
