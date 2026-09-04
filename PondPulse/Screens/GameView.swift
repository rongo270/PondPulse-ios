//
//  GameView.swift
//  PondPulse
//
//  One level of the campaign: board, splash budget, undo/reset/hint, the win
//  sequence (confetti heartbeat, then the card) and the dead-end nudge. Port of
//  the Android ui/GameScreen.kt.
//

import SwiftUI

struct GameView: View {
    @ObservedObject var vm: AppViewModel
    let levelId: String

    @StateObject private var controller: GameController
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    @State private var showWinCard = false
    @State private var showHintsOut = false

    /// Set only when this clear was the pond's first, i.e. when it paid a prize.
    @State private var bonusFirstClear = false

    /// Snapshotted on arrival, before any win of this visit can bank a star, so
    /// it means "was still unsolved when the player walked in".
    private let wasUnsolved: Bool

    /// A teaching pond: the ring is on the board from the first frame, and the
    /// splash counter is hidden because its budget can never run out.
    private let guided: Bool

    init(vm: AppViewModel, levelId: String) {
        self.vm = vm
        self.levelId = levelId
        self.wasUnsolved = (vm.stars[levelId] ?? 0) == 0
        let spec = Levels.byId(levelId)
        let isGuided = Levels.isGuided(levelId)
        self.guided = isGuided
        _controller = StateObject(wrappedValue: GameController(spec: spec, guided: isGuided) { stars, splashes in
            if spec.isBonus {
                vm.recordBonusWin(levelId: levelId, stars: stars)
            } else {
                vm.recordWin(levelId: levelId, stars: stars, splashes: splashes)
            }
        })
    }

    var body: some View {
        let state = controller.state
        let spec = controller.spec
        let stuckNow = state.stuck || controller.deadEnd

        ZStack {
            VStack(spacing: 0) {
                // Top bar.
                HStack {
                    RoundIconButton(systemName: "chevron.backward") { vm.leaveLevel(levelId) }
                    Spacer()
                    VStack(spacing: 1) {
                        Text(spec.isBonus
                            ? strings["bonus_title"]
                            : strings["level_title", vm.globalLevelNumber(levelId)])
                            .font(.game(17, .bold))
                            .foregroundStyle(spec.isBonus ? palette.star : palette.textPrimary)
                        Text(strings["game_ducks_home", state.ducksHome, spec.duckCount])
                            .font(.game(12, .semibold))
                            .foregroundStyle(palette.textSecondary)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    RoundIconButton(systemName: "arrow.counterclockwise") {
                        vm.clearBonusPayoutNotice()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { controller.reset() }
                    }
                }

                // Splash budget. Hidden on the guided ponds: their budget is
                // deliberately far past anything a player could burn through, and
                // a counter that can never run out is a worry with nothing behind
                // it. The pond that teaches the counter (`1-7`) draws it first.
                if !guided {
                    DropletRow(total: spec.maxSplashes, left: state.splashesLeft)
                        .padding(.vertical, 8)
                }

                // Developer level skipper. Gated on the debug switch in Settings,
                // which itself only exists in a debug build, so this can never
                // reach a player.
                if vm.debugTools {
                    let previous = vm.debugNeighbour(levelId, delta: -1)
                    let next = vm.debugNeighbour(levelId, delta: 1)
                    HStack(spacing: 8) {
                        GhostButton(strings["debug_previous"], enabled: previous != nil) {
                            if let previous { vm.replaceTop(.game(levelId: previous.id)) }
                        }
                        Text(strings["debug_level_of", vm.globalLevelNumber(levelId), Levels.all.count])
                            .font(.game(11, .semibold))
                            .foregroundStyle(palette.textSecondary)
                        GhostButton(strings["debug_next"], enabled: next != nil) {
                            if let next { vm.replaceTop(.game(levelId: next.id)) }
                        }
                    }
                    .padding(.bottom, 4)
                }

                // The pond.
                Spacer(minLength: 0)
                PondBoardView(
                    state: state,
                    hintCell: controller.ringCell,
                    skinId: vm.skinId,
                    padId: vm.padId,
                    onTap: { pos in
                        let accepted = controller.tap(pos)
                        if accepted { Haptics.splash(enabled: vm.haptics) }
                        return accepted
                    }
                )
                .frame(maxWidth: .infinity)
                Spacer(minLength: 0)

                // A dead end used to stop the game with a card over the board. It
                // says the same thing here instead - in the line the player is
                // already reading, with Reset lit up in the row their thumb is
                // already on - so being stuck is a nudge rather than an
                // interruption.
                let stuckText: String? = stuckNow
                    ? strings[state.stranded ? "stranded_body"
                        : controller.deadEnd ? "deadend_body" : "fail_body"]
                    : nil
                let tipText = stuckText ?? tip
                Text(tipText.isEmpty ? " " : tipText)
                    .font(.game(14, stuckText != nil ? .bold : .regular))
                    .foregroundStyle(stuckText != nil ? palette.accent : palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        (tipText.isEmpty ? palette.background : palette.surface),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .padding(.vertical, 8)

                // Bottom controls.
                HStack(spacing: 8) {
                    GhostButton(strings["undo"]) { controller.undo() }
                    // Reset is always here, so the row never reflows under the
                    // thumb. It only *lights up* at a dead end.
                    PulseButton(strings["reset"], highlighted: stuckNow) {
                        vm.clearBonusPayoutNotice()
                        controller.reset()
                    }
                    // Golden ponds hand prizes *out*; spending a hint inside the
                    // pond that pays one is backwards, so they are solved on your
                    // own and Undo and Reset take the whole row.
                    if !spec.isBonus {
                        // A level pays for its hint once, ever: after that the
                        // glow is a free replay (saved locally in the store).
                        let hintPaid = vm.hintedLevels.contains(levelId)
                        GhostButton(hintLabel(paid: hintPaid)) {
                            if vm.isPremium || hintPaid {
                                controller.requestHint()
                            } else if vm.hintsLeft > 0 {
                                controller.requestHint { vm.useHint(levelId: levelId) }
                            } else {
                                showHintsOut = true
                            }
                        }
                    }
                }
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 16)
            .pondContentWidth(560)

            // Win sequence: a heartbeat of confetti and a spinning duck, then the card.
            if state.won {
                WinCelebration(skinId: vm.skinId)
                    .transition(.opacity)
            }
            if state.won && showWinCard {
                winCard
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.won)
        .animation(.easeInOut(duration: 0.25), value: showWinCard)
        .task(id: state.won) {
            if state.won {
                bonusFirstClear = vm.bonusPrizePaidFor == levelId
                try? await Task.sleep(for: .seconds(1.1))
                showWinCard = true
            } else {
                showWinCard = false
                // A replay has to earn its own verdict: the prize is already paid.
                bonusFirstClear = false
            }
        }
        .alert(strings["hints_out_title"], isPresented: $showHintsOut) {
            // Coins first: they are the currency the campaign actually pays out,
            // and five hints is the bundle the shop sells for them.
            if vm.canAfford(CoinBank.priceHint * CoinBank.hintBundle) {
                Button(strings["shop_hints_bundle", CoinBank.hintBundle, CoinBank.priceHint * CoinBank.hintBundle]) {
                    vm.buyHints(count: CoinBank.hintBundle)
                }
            }
            Button(strings["hints_buy_cta", Catalog.hintsPerPack]) {
                Task { await vm.purchase(Catalog.hintsId) }
            }
            Button(strings["win_get_premium"]) { vm.navigate(.shop) }
            Button(strings["shop_cancel"], role: .cancel) {}
        } message: {
            Text(strings["hints_out_body", Catalog.hintsPerPack])
        }
    }

    private var tip: String {
        switch controller.hintState {
        case .thinking: strings["hint_thinking"]
        case .shown: strings["hint_found"]
        case .noneFound: strings["hint_none"]
        case .idle: controller.spec.tip.map { strings[$0] } ?? ""
        }
    }

    private func hintLabel(paid: Bool) -> String {
        if vm.isPremium { return strings["hint_unlimited"] }
        if paid { return strings["hint_free"] }
        return strings["hint_left", vm.hintsLeft]
    }

    private var winCard: some View {
        let state = controller.state
        let spec = controller.spec
        let stars = controller.stars()
        let levelNumber = vm.globalLevelNumber(levelId)
        let bonusCleared = vm.bonusPondsCleared()

        // A cosmetic is celebrated only on the very clear that earns it.
        func justEarned(_ unlock: Unlock) -> Bool {
            switch unlock {
            case .levelReward(let level):
                return !spec.isBonus && level == levelNumber
            // bonusFirstClear marks a first-ever clear, so replays stay quiet.
            case .bonusReward(let count):
                return spec.isBonus && bonusFirstClear && count == bonusCleared
            // A coin item with a golden-pond rung is won on that rung too: the
            // price is one door to it and the golden pond is the other.
            case .coins(_, let bonusCount):
                return spec.isBonus && bonusFirstClear && bonusCount == bonusCleared
            // Streak prizes are celebrated on the Daily Pond's own win card;
            // a theme friend arrives with its theme and a special friend with
            // its purchase, so neither is ever earned by finishing a pond.
            case .streakReward, .free, .premium, .themeFriend, .money:
                return false
            }
        }
        let rewardSkin = Catalog.skins.first { justEarned($0.unlock) }
        let rewardTheme = Catalog.themes.first { justEarned($0.unlock) }
        let rewardPad = Catalog.pads.first { justEarned($0.unlock) }
        let rewardDecor = PondCatalog.decor.first {
            spec.isBonus && bonusFirstClear && $0.bonusCount == bonusCleared
        }

        return OverlayCard {
            SectionTitle(strings[spec.isBonus ? "bonus_win_title" : "win_title"])
            StarsRow(stars: stars)
            Text(winMessage(state: state, spec: spec))
                .font(.game(14))
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)

            // The button here equips. It used to be labelled "Equip" and merely
            // open the shop, which is the one thing a button called Equip must
            // not do; a prize you just won should go on with one tap, from the
            // card that told you about it.
            if let rewardSkin {
                RewardUnlockBanner(
                    name: strings[rewardSkin.nameKey],
                    equipped: vm.skinId == rewardSkin.id,
                    onEquip: { vm.selectSkin(rewardSkin.id) }
                ) { SkinPreview(skinId: rewardSkin.id).frame(width: 52, height: 52) }
            } else if let rewardTheme {
                RewardUnlockBanner(
                    name: strings[rewardTheme.nameKey],
                    equipped: vm.themeId == rewardTheme.id,
                    onEquip: { vm.selectTheme(rewardTheme.id) },
                    titleKey: "win_reward_title_theme",
                    bodyKey: "win_reward_body_thing"
                ) { ThemePreview(palette: rewardTheme.palette).frame(width: 68, height: 48) }
            } else if let rewardPad {
                RewardUnlockBanner(
                    name: strings[rewardPad.nameKey],
                    equipped: vm.padId == rewardPad.id,
                    onEquip: { vm.selectPad(rewardPad.id) },
                    titleKey: "win_reward_title_pad",
                    bodyKey: "win_reward_body_thing"
                ) { PadPreview(padId: rewardPad.id).frame(width: 52, height: 52) }
            } else if let rewardDecor {
                // A decoration is not worn, it is placed - so its button opens
                // Decorate rather than pretending to equip anything.
                RewardUnlockBanner(
                    name: strings[rewardDecor.nameKey],
                    equipped: false,
                    onEquip: { vm.navigate(.decorate) },
                    titleKey: "win_reward_title_decor",
                    bodyKey: "win_reward_body_thing",
                    actionKey: "win_reward_place"
                ) { DecorPreview(item: rewardDecor).frame(width: 52, height: 52) }
            }

            // Finishing a run of ponds opens a golden one. Offer it right here -
            // it is otherwise buried in the level list, and nobody would find it.
            let openBonus = vm.bonusOpenedBy(levelId, firstClear: wasUnsolved)
            let next = Levels.next(levelId)
            if let openBonus {
                PrimaryButton(strings["bonus_play_cta"]) {
                    vm.replaceTop(.game(levelId: openBonus.level.id))
                }
            } else if let next {
                if vm.isPremiumLevel(next.id) && !vm.isPremium {
                    PrimaryButton(strings["win_get_premium"]) { vm.navigate(.shop) }
                } else {
                    PrimaryButton(strings["next_level"]) { vm.replaceTop(.game(levelId: next.id)) }
                }
            }
            HStack(spacing: 10) {
                // With a golden pond offered above, "Next" still has to be
                // reachable - it is the way on through the campaign.
                if openBonus != nil, let next, !(vm.isPremiumLevel(next.id) && !vm.isPremium) {
                    GhostButton(strings["next_level"]) { vm.replaceTop(.game(levelId: next.id)) }
                } else {
                    GhostButton(strings["win_replay"]) {
                        vm.clearBonusPayoutNotice()
                        controller.reset()
                    }
                }
                GhostButton(strings["all_levels"]) {
                    vm.leaveLevel(levelId)
                    if vm.current == .home { vm.navigate(.packs) }
                }
            }
        }
    }

    private func winMessage(state: GameState, spec: LevelSpec) -> String {
        if spec.isBonus {
            return bonusFirstClear ? strings["bonus_win_prize"] : strings["bonus_win_again"]
        }
        if state.splashesUsed <= spec.par { return strings["win_par"] }
        if state.splashesLeft > 0 { return strings["win_over_par", state.splashesLeft] }
        return strings["win_exact"]
    }
}
