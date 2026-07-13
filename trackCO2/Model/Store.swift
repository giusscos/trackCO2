//
//  Store.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 06/07/25.
//

import Foundation
import StoreKit

//alias
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo // The Product.SubscriptionInfo.RenewalInfo provides information about the next subscription renewal period.
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState // the renewal states of auto-renewable subscriptions.

@Observable
class Store {
    private var subscriptions: [Product] = []
    var purchasedSubscriptions: [Product] = []
    private var subscriptionGroupStatus: RenewalState?
    var isLoading: Bool = true
    
//    let productIds: [String] = ["fp_199_1m_d", "fp_1999_1y_1w", "fp_399_1m_3d_f", "fp_3999_1y_1w_f"] // test
//    let groupId: String = "1C60A97F" // test
//    
//    let productLifetimeIds: [String] = ["com.giusscos.footprintFamilyLifetime", "com.giusscos.footprintLifetime"] // test
    
    let productIds: [String] = ["fp_199_1m_d", "fp_1999_1y_1w", "fp_399_1m_3d_f", "fp_3999_1y_1w_f"]
    let groupId: String = "21727569"
    
    let productLifetimeIds: [String] = ["com.giusscos.footprintFamilyLifetime", "com.giusscos.footprintLifetime"]
    
    // if there are multiple product types - create multiple variable for each .consumable, .nonconsumable, .autoRenewable, .nonRenewable.
    private var storeProducts: [Product] = []
    var purchasedProducts: [Product] = []
    private(set) var entitledProductIDs: Set<String> = []
    
    var hasPaid: Bool {
        !purchasedSubscriptions.isEmpty || !purchasedProducts.isEmpty || !entitledProductIDs.isEmpty
    }
    
    var updateListenerTask : Task<Void, Error>? = nil
    
    init() {
        // start a transaction listern as close to app launch as possible so you don't miss a transaction
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            
            await updateCustomerProductStatus()
            
            isLoading = false
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.recordEntitlement(for: transaction)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("transaction failed verification")
                }
            }
        }
    }
    
    // Request the products
    @MainActor
    func requestProducts() async {
        do {
            storeProducts = try await Product.products(for: productLifetimeIds)
            
            // request from the app store using the product ids (hardcoded)
            subscriptions = try await Product.products(for: productIds)
        } catch {
            print("Failed product request from app store server: \(error)")
        }
    }
    
    // purchase the product
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Check whether the transaction is verified. If it isn't,
            // this function rethrows the verification error.
            let transaction = try checkVerified(verification)
            
            // The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()
            
            // Always finish a transaction.
            await transaction.finish()
            
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    //check if product has already been purchased
    func isPurchased(_ product: Product) async throws -> Bool {
        // as we only have one product type grouping .nonconsumable - we check if it belongs to the purchasedCourses which ran init()
        return purchasedProducts.contains(product)
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            // StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            // The result is verified. Return the unwrapped value.
            return safe
        }
    }
    
    @MainActor
    func recordEntitlement(for transaction: Transaction) {
        entitledProductIDs.insert(transaction.productID)

        switch transaction.productType {
        case .autoRenewable:
            if let subscription = subscriptions.first(where: { $0.id == transaction.productID }),
               !purchasedSubscriptions.contains(where: { $0.id == subscription.id }) {
                purchasedSubscriptions.append(subscription)
            }
        case .nonConsumable:
            if let storeProduct = storeProducts.first(where: { $0.id == transaction.productID }),
               !purchasedProducts.contains(where: { $0.id == storeProduct.id }) {
                purchasedProducts.append(storeProduct)
            }
        default:
            break
        }
    }

    @MainActor
    func updateCustomerProductStatus() async {
        var newPurchasedSubscriptions: [Product] = []
        var newPurchasedProducts: [Product] = []
        var newEntitledProductIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                newEntitledProductIDs.insert(transaction.productID)

                switch transaction.productType {
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        newPurchasedSubscriptions.append(subscription)
                    }
                case .nonConsumable:
                    if let storeProduct = storeProducts.first(where: { $0.id == transaction.productID }) {
                        newPurchasedProducts.append(storeProduct)
                    }
                default:
                    break
                }
            } catch {
                print("failed updating products")
            }
        }

        purchasedSubscriptions = newPurchasedSubscriptions
        purchasedProducts = newPurchasedProducts
        entitledProductIDs = newEntitledProductIDs
    }
}

public enum StoreError: Error {
    case failedVerification
}
