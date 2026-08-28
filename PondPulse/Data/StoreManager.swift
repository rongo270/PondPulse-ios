//
//  StoreManager.swift
//  PondPulse
//
//  StoreKit 2 wiring for the shop. Product ids are identical to the Android
//  Play Billing ids so the two stores stay in sync.
//
//  Only five things in PondPulse ever charge real money: the premium upgrade
//  (one non-consumable), the 50-hint pack and the three coin packs (four
//  consumables). Every cosmetic is bought with coins now and is not a store
//  product at all - see `CoinBank`. Create exactly these five in App Store
//  Connect; the twenty cosmetic IAPs the shop used to sell are retired.
//
//  For local testing, select PondPulse/Products.storekit as the scheme's
//  StoreKit configuration (the shared scheme already does).
//
//  Ownership lives in AppViewModel/ProgressStore; this class only talks to
//  StoreKit and reports verified outcomes through its callbacks.
//

import Foundation
import StoreKit

@MainActor
final class StoreManager {

    /// Every id that can be bought with money: premium, the hint pack, the
    /// three coin packs. Cosmetics are coin purchases and never appear here.
    static var allProductIds: [String] {
        [Catalog.premiumId, Catalog.hintsId] + Catalog.coinPackIds
    }

    /// A verified non-consumable entitlement appeared (purchase, restore, or launch sync).
    var onEntitled: ((String) -> Void)?
    /// A verified non-consumable was refunded/revoked.
    var onRevoked: ((String) -> Void)?
    /// A verified hint-pack purchase was credited (already de-duplicated).
    var onHintsPurchased: ((Int) -> Void)?
    /// A verified coin-pack purchase was credited (already de-duplicated).
    var onCoinsPurchased: ((Int) -> Void)?

    private(set) var products: [String: Product] = [:]
    /// True when the product list could not be fetched (no network / products not set up yet).
    private(set) var loadFailed = false

    /// Consumable transactions already credited, so a re-delivered transaction
    /// (unfinished at crash, Ask to Buy approval, ...) never double-credits.
    /// One ledger for hints and coins alike - a transaction id is unique across
    /// products, and two ledgers would only be two things to keep in step.
    private let handledKey = "handled_hint_transactions"
    private var handledConsumables: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: handledKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue).sorted(), forKey: handledKey) }
    }

    /// Credits one consumable exactly once, whatever redelivers it.
    private func creditOnce(_ transaction: Transaction, _ credit: () -> Void) {
        guard transaction.revocationDate == nil else { return }
        let key = String(transaction.id)
        guard !handledConsumables.contains(key) else { return }
        handledConsumables.insert(key)
        credit()
    }

    private var updatesTask: Task<Void, Never>?

    init() {
        // App-lifetime listener; the manager is created once at the root.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await self?.process(transaction, finish: true)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var displayPrices: [String: String] {
        products.mapValues(\.displayPrice)
    }

    func load() async {
        do {
            let loaded = try await Product.products(for: Self.allProductIds)
            products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
            loadFailed = loaded.isEmpty
        } catch {
            loadFailed = true
        }
        await syncEntitlements()
    }

    /// Runs the App Store payment sheet. Returns true once the purchase is
    /// verified AND granted through the callbacks, so callers can equip the
    /// item right after.
    func purchase(_ productId: String) async -> Bool {
        guard let product = products[productId] else { return false }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result,
               case .verified(let transaction) = verification {
                await process(transaction, finish: true)
                return true
            }
        } catch {
            // Cancelled or failed - the shop simply stays up.
        }
        return false
    }

    func restore() async {
        try? await AppStore.sync()
        await syncEntitlements()
    }

    /// Grants every currently held non-consumable (launch, restore, new device).
    private func syncEntitlements() async {
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            await process(transaction, finish: false)
        }
    }

    private func process(_ transaction: Transaction, finish: Bool) async {
        if transaction.productID == Catalog.hintsId {
            creditOnce(transaction) { onHintsPurchased?(Catalog.hintsPerPack) }
        } else if let coins = Catalog.coinsInPack(transaction.productID) {
            creditOnce(transaction) { onCoinsPurchased?(coins) }
        } else if transaction.revocationDate == nil {
            onEntitled?(transaction.productID)
        } else {
            onRevoked?(transaction.productID)
        }
        if finish { await transaction.finish() }
    }
}
