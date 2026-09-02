//
//  PondPulseApp.swift
//  PondPulse
//
//  App entry and the top-level router: the equipped theme paints everything,
//  the in-app language drives strings and layout direction (Hebrew/Arabic
//  flip to RTL), and screens cross-fade like the Android Crossfade shell.
//

import SwiftUI

@main
struct PondPulseApp: App {
    @StateObject private var vm = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(vm: vm)
        }
    }
}

struct RootView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        let palette = vm.palette
        ZStack {
            palette.background.ignoresSafeArea()

            screenView(vm.current)
                .id(screenKey(vm.current))
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.22), value: screenKey(vm.current))
        .environment(\.palette, palette)
        .environment(\.strings, vm.strings)
        .environment(\.layoutDirection, vm.language.isRTL ? .rightToLeft : .leftToRight)
        // Dark palettes get light status-bar icons and dark system sheets, and
        // vice versa - the iOS take on Android's enableEdgeToEdge switch.
        .preferredColorScheme(palette.isDark ? .dark : .light)
    }

    @ViewBuilder
    private func screenView(_ screen: Screen) -> some View {
        switch screen {
        case .home:
            HomeView(vm: vm)
        case .packs:
            PacksView(vm: vm)
        case .packLevels(let packId, let focusLevelId):
            PackLevelsView(vm: vm, packId: packId, focusLevelId: focusLevelId)
        case .game(let levelId):
            GameView(vm: vm, levelId: levelId)
        case .settings:
            SettingsView(vm: vm)
        case .shop:
            ShopView(vm: vm)
        case .shopShelf(let shelf):
            ShopShelfView(vm: vm, shelf: shelf)
        case .rush:
            RushView(vm: vm)
        case .daily:
            DailyView(vm: vm)
        case .pond:
            PondView(vm: vm)
        case .pondGame(let gameId):
            PondGameView(vm: vm, gameId: gameId)
        case .achievements:
            AchievementsView(vm: vm)
        case .achievementFamily(let raw):
            if let family = Achievements.Family(rawValue: raw) {
                AchievementFamilyView(vm: vm, family: family)
            } else {
                AchievementsView(vm: vm)
            }
        case .decorate:
            DecorateView(vm: vm)
        }
    }

    /// Stable identity per screen instance so Crossfade-style transitions fire
    /// (and a new level id means a fresh GameView with a fresh controller).
    private func screenKey(_ screen: Screen) -> String {
        switch screen {
        case .home: "home"
        case .packs: "packs"
        // The focused pond is deliberately not part of the key: it changes when
        // the player leaves a level, and a new key there would cross-fade the
        // page they just came back to.
        case .packLevels(let packId, _): "packlevels-\(packId)"
        case .game(let levelId): "game-\(levelId)"
        case .settings: "settings"
        case .shop: "shop"
        case .shopShelf(let shelf): "shelf-\(shelf)"
        case .rush: "rush"
        case .daily: "daily"
        case .pond: "pond"
        case .pondGame(let gameId): "pondgame-\(gameId)"
        case .decorate: "decorate"
        case .achievements: "achievements"
        case .achievementFamily(let raw): "achievements-\(raw)"
        }
    }
}
