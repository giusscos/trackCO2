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
