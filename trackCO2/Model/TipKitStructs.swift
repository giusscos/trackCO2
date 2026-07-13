//
//  TipKitStructs.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 09/07/25.
//

import TipKit

struct SelectPlusMultiplierTip: Tip {
    var title: Text {
        Text("Change the Multiplier")
    }
    var message: Text? {
        Text("Long-press + or - to select a different step size.")
    }
    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }
}

struct MapPickDestinationTip: Tip {
    var title: Text {
        Text("Pick a Destination")
    }
    var message: Text? {
        Text("Tap anywhere on the map or use the search button to choose where you're headed.")
    }
    var image: Image? {
        Image(systemName: "mappin.and.ellipse")
    }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}

struct RouteOptionsTip: Tip {
    var title: Text {
        Text("Compare Transport Modes")
    }
    var message: Text? {
        Text("Swipe through the cards to compare CO₂ impact. The greenest route is always shown first.")
    }
    var image: Image? {
        Image(systemName: "leaf.fill")
    }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}

struct SaveTripTip: Tip {
    var title: Text {
        Text("Log Your Trip")
    }
    var message: Text? {
        Text("Tap the checkmark to save this trip and record its CO₂ emissions to your activity log.")
    }
    var image: Image? {
        Image(systemName: "checkmark.circle.fill")
    }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}
