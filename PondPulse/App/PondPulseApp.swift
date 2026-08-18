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
        case .packLevels(let packId):
            PackLevelsView(vm: vm, packId: packId)
        case .game(let levelId):
            GameView(vm: vm, levelId: levelId)
        case .settings:
            SettingsView(vm: vm)
        case .shop:
            ShopView(vm: vm)
        case .rush:
            RushView(vm: vm)
        }
    }

    /// Stable identity per screen instance so Crossfade-style transitions fire
    /// (and a new level id means a fresh GameView with a fresh controller).
    private func screenKey(_ screen: Screen) -> String {
        switch screen {
        case .home: "home"
        case .packs: "packs"
        case .packLevels(let packId): "packlevels-\(packId)"
        case .game(let levelId): "game-\(levelId)"
        case .settings: "settings"
        case .shop: "shop"
        case .rush: "rush"
        }
    }
}
