//
//  GameView.swift
//  PondPulse
//
//  One level of the campaign: board, splash budget, undo/hint, the win
//  sequence (confetti heartbeat, then the card) and the out-of-splashes
//  overlay. Port of the Android ui/GameScreen.kt.
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
    init(vm: AppViewModel, levelId: String) {
        self.vm = vm
        self.levelId = levelId
        let spec = Levels.byId(levelId)
        _controller = StateObject(wrappedValue: GameController(spec: spec) { stars in
            if spec.isBonus {
                vm.recordBonusWin(levelId: levelId, stars: stars)
            } else {
                vm.recordWin(levelId: levelId, stars: stars)
            }
        })
    }

    /// True when this clear was the pond's first, i.e. when hints were paid out.
    private var bonusHintsWon: Bool { vm.bonusHintsPaidFor == levelId }

    var body: some View {
        let state = controller.state
        let spec = controller.spec

        ZStack {
            VStack(spacing: 0) {
                // Top bar.
                HStack {
                    RoundIconButton(systemName: "chevron.backward") { vm.back() }
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

                // Splash budget.
                DropletRow(total: spec.maxSplashes, left: state.splashesLeft)
                    .padding(.vertical, 8)

                // The pond.
                Spacer(minLength: 0)
                PondBoardView(
                    state: state,
                    hintCell: controller.hintCell,
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

                // Tutorial tip or hint feedback.
                let tipText = tip
                Text(tipText.isEmpty ? " " : tipText)
                    .font(.game(14))
                    .foregroundStyle(palette.textSecondary)
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
                HStack(spacing: 12) {
                    GhostButton(strings["undo"]) { controller.undo() }
                    // A level pays for its hint once, ever: after that the glow
                    // is a free replay (saved locally in the progress store).
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

            // Out-of-splashes overlay.
            if state.stuck || controller.deadEnd {
                stuckCard
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.won)
        .animation(.easeInOut(duration: 0.25), value: showWinCard)
        .animation(.easeInOut(duration: 0.25), value: state.stuck || controller.deadEnd)
        .task(id: state.won) {
            if state.won {
                try? await Task.sleep(for: .seconds(1.1))
                showWinCard = true
            } else {
                showWinCard = false
            }
        }
        .alert(strings["hints_out_title"], isPresented: $showHintsOut) {
            Button(strings["hints_buy_cta", Catalog.hintsPerPack]) {
                Task { await vm.purchase(Catalog.hintsId) }
            }
            Button(strings["win_get_premium"]) {
                vm.navigate(.shop)
            }
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
            if let level = unlock.rewardLevel { return !spec.isBonus && level == levelNumber }
            // bonusHintsWon marks a first-ever clear, so replays stay quiet.
            if let count = unlock.rewardBonusPonds {
                return spec.isBonus && bonusHintsWon && count == bonusCleared
            }
            return false
        }
        let rewardSkin = Catalog.skins.first { justEarned($0.unlock) }
        let rewardTheme = Catalog.themes.first { justEarned($0.unlock) }
        let rewardPad = Catalog.pads.first { justEarned($0.unlock) }

        return OverlayCard {
            SectionTitle(strings[spec.isBonus ? "bonus_win_title" : "win_title"])
            StarsRow(stars: stars)
            Text(winMessage(state: state, spec: spec))
                .font(.game(14))
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)

            if let rewardSkin {
                RewardUnlockBanner(name: strings[rewardSkin.nameKey], onOpenShop: { vm.navigate(.shop) }) {
                    SkinPreview(skinId: rewardSkin.id).frame(width: 52, height: 52)
                }
            } else if let rewardTheme {
                RewardUnlockBanner(name: strings[rewardTheme.nameKey], onOpenShop: { vm.navigate(.shop) }) {
                    ThemePreview(palette: rewardTheme.palette).frame(width: 68, height: 48)
                }
            } else if let rewardPad {
                RewardUnlockBanner(name: strings[rewardPad.nameKey], onOpenShop: { vm.navigate(.shop) }) {
                    PadPreview(padId: rewardPad.id).frame(width: 52, height: 52)
                }
            }

            // Finishing a run of ponds opens a golden one. Offer it right here -
            // it is otherwise buried in the level list, and nobody would find it.
            let openBonus = spec.isBonus ? nil : vm.openBonus(Levels.packOf(levelId))
            if let openBonus {
                PrimaryButton(strings["bonus_play_cta"]) {
                    vm.replaceTop(.game(levelId: openBonus.level.id))
                }
            } else if let next = Levels.next(levelId) {
                if vm.isPremiumLevel(next.id) && !vm.isPremium {
                    PrimaryButton(strings["win_get_premium"]) { vm.navigate(.shop) }
                } else {
                    PrimaryButton(strings["next_level"]) { vm.replaceTop(.game(levelId: next.id)) }
                }
            }
            HStack(spacing: 10) {
                GhostButton(strings["win_replay"]) { vm.clearBonusPayoutNotice(); controller.reset() }
                GhostButton(strings["all_levels"]) {
                    vm.back()
                    if vm.current != .packs { vm.navigate(.packs) }
                }
            }
        }
    }

    private func winMessage(state: GameState, spec: LevelSpec) -> String {
        if spec.isBonus {
            return bonusHintsWon
                ? strings["bonus_win_hints", ProgressStore.bonusHintReward]
                : strings["bonus_win_again"]
        }
        if state.splashesUsed <= spec.par { return strings["win_par"] }
        if state.splashesLeft > 0 { return strings["win_over_par", state.splashesLeft] }
        return strings["win_exact"]
    }

    private var stuckCard: some View {
        let state = controller.state
        let titleKey = state.stranded ? "stranded_title"
            : controller.deadEnd ? "deadend_title"
            : "fail_title"
        let bodyKey = state.stranded ? "stranded_body"
            : controller.deadEnd ? "deadend_body"
            : "fail_body"

        return OverlayCard {
            SectionTitle(strings[titleKey])
            Text(strings[bodyKey])
                .font(.game(14))
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton(strings["undo"]) { controller.undo() }
            GhostButton(strings["restart"]) { vm.clearBonusPayoutNotice(); controller.reset() }
        }
    }
}
