//
//  Product+Paywall.swift
//  trackCO2
//

import Foundation
import StoreKit

extension Product {
    /// The free-trial part of the introductory offer, if the offer is a free trial.
    var freeTrialPeriod: Product.SubscriptionPeriod? {
        guard let offer = subscription?.introductoryOffer, offer.paymentMode == .freeTrial else { return nil }
        return offer.period
    }

    /// "7 days", "1 month" — used in trial badges and the post-trial disclosure.
    var freeTrialText: String? {
        guard let period = freeTrialPeriod else { return nil }
        let count: Int
        switch period.unit {
        case .day: count = period.value
        case .week: count = period.value * 7
        case .month:
            return period.value == 1
                ? String(localized: "paywall.period.oneMonth")
                : String(format: String(localized: "paywall.period.months"), period.value)
        case .year:
            return period.value == 1
                ? String(localized: "paywall.period.oneYear")
                : String(format: String(localized: "paywall.period.years"), period.value)
        @unknown default: return nil
        }
        return count == 1
            ? String(localized: "paywall.period.oneDay")
            : String(format: String(localized: "paywall.period.days"), count)
    }

    /// "$19.99/year", "$2.99/month"; the plain price for non-subscriptions.
    var pricePerPeriodText: String {
        guard let unit = subscription?.subscriptionPeriod.unit else { return displayPrice }
        let format: String
        switch unit {
        case .year: format = String(localized: "paywall.price.perYear")
        case .month: format = String(localized: "paywall.price.perMonth")
        case .week: format = String(localized: "paywall.price.perWeek")
        default: return displayPrice
        }
        return String(format: format, displayPrice)
    }

    /// Price divided by 12, formatted in the storefront currency. Only meaningful for yearly plans.
    var monthlyEquivalentText: String {
        (price / 12).formatted(priceFormatStyle)
    }
}
