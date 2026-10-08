//
//  DeepLink.swift
//  trackCO2
//

import Foundation

/// URLs handled by the `claud://` scheme, used by In-App Events and shortcuts.
///
/// - `claud://home` opens Home.
/// - `claud://log` opens Home with the log-activity sheet.
/// - `claud://trips` opens the Trips tab.
enum DeepLink: Equatable {
    case home
    case log
    case trips

    init?(url: URL) {
        guard url.scheme?.lowercased() == "claud" else { return nil }
        switch url.host()?.lowercased() {
        case "log": self = .log
        case "trips": self = .trips
        default: self = .home
        }
    }
}

enum AppTab: Hashable {
    case home
    case trips
    case activities
}
