# Task: Localize Default Activities

## Goal

The 16 default activities in `trackCO2/Model/Activity.swift` have hardcoded English names. This task adds localized names for all 12 supported locales and fixes the deduplication logic in `SelectActivitiesToPersistView.swift` so it stays correct regardless of the user's language.

---

## Files to change

1. `trackCO2/Model/Activity.swift`
2. `trackCO2/View/Activity/SelectActivitiesToPersistView.swift`
3. `trackCO2/en.lproj/Localizable.strings`
4. `trackCO2/en-CA.lproj/Localizable.strings`
5. `trackCO2/en-GB.lproj/Localizable.strings`
6. `trackCO2/de.lproj/Localizable.strings`
7. `trackCO2/es.lproj/Localizable.strings`
8. `trackCO2/fr.lproj/Localizable.strings`
9. `trackCO2/it.lproj/Localizable.strings`
10. `trackCO2/nb.lproj/Localizable.strings`
11. `trackCO2/nl.lproj/Localizable.strings`
12. `trackCO2/pt.lproj/Localizable.strings`
13. `trackCO2/pt-BR.lproj/Localizable.strings`
14. `trackCO2/sv.lproj/Localizable.strings`

---

## Change 1 — `Activity.swift`

Convert `defaultActivities` from a `let` constant to a computed `var` so `String(localized:)` is evaluated at call time (picking up the current locale).

**Before:**
```swift
let defaultActivities: [Activity] = [
    // Vehicles
    Activity(type: .car, name: "Car Travel", quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.15),
    Activity(type: .airplane, name: "Airplane Flight", quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.2),
    Activity(type: .boat, name: "Boat Trip", quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.1),
    Activity(type: .motorcycle, name: "Motorcycle Ride", quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.1),
    Activity(type: .bus, name: "Bus Travel", quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.08),
    Activity(type: .train, name: "Train Travel", quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.04),
    
    // Foods
    Activity(type: .beef, name: "Beef Consumption", quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 60.0),
    Activity(type: .chicken, name: "Chicken Consumption", quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 6.0),
    Activity(type: .vegetables, name: "Vegetable Consumption", quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 1.0),
    Activity(type: .rice, name: "Rice Consumption", quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 4.0),
    Activity(type: .dairy, name: "Dairy Consumption", quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 10.0),
    
    // Energy
    Activity(type: .electricity, name: "Electricity Usage", quantityUnit: .kWh, emissionUnit: .kgCO2e, co2Emission: 0.53),
    
    // CO2 Reduction
    Activity(type: .walking, name: "Walking", quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: -0.15),
    Activity(type: .biking, name: "Biking", quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: -0.15),
    Activity(type: .treePlanting, name: "Tree Planting", quantityUnit: .tree, emissionUnit: .kgCO2e, co2Emission: -20.0),
    Activity(type: .recycling, name: "Recycling", quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: -0.5)
]
```

**After:**
```swift
var defaultActivities: [Activity] {
    [
        // Vehicles
        Activity(type: .car, name: String(localized: "Car Travel"), quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.15),
        Activity(type: .airplane, name: String(localized: "Airplane Flight"), quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.2),
        Activity(type: .boat, name: String(localized: "Boat Trip"), quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.1),
        Activity(type: .motorcycle, name: String(localized: "Motorcycle Ride"), quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.1),
        Activity(type: .bus, name: String(localized: "Bus Travel"), quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.08),
        Activity(type: .train, name: String(localized: "Train Travel"), quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.04),
        
        // Foods
        Activity(type: .beef, name: String(localized: "Beef Consumption"), quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 60.0),
        Activity(type: .chicken, name: String(localized: "Chicken Consumption"), quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 6.0),
        Activity(type: .vegetables, name: String(localized: "Vegetable Consumption"), quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 1.0),
        Activity(type: .rice, name: String(localized: "Rice Consumption"), quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 4.0),
        Activity(type: .dairy, name: String(localized: "Dairy Consumption"), quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 10.0),
        
        // Energy
        Activity(type: .electricity, name: String(localized: "Electricity Usage"), quantityUnit: .kWh, emissionUnit: .kgCO2e, co2Emission: 0.53),
        
        // CO2 Reduction
        Activity(type: .walking, name: String(localized: "Walking"), quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: -0.15),
        Activity(type: .biking, name: String(localized: "Biking"), quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: -0.15),
        Activity(type: .treePlanting, name: String(localized: "Tree Planting"), quantityUnit: .tree, emissionUnit: .kgCO2e, co2Emission: -20.0),
        Activity(type: .recycling, name: String(localized: "Recycling"), quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: -0.5)
    ]
}
```

---

## Change 2 — `SelectActivitiesToPersistView.swift`

The `unpersistedActivities` property currently deduplicates by matching the stored `name` string. This breaks if the user already has "Car Travel" stored in English but the app is now running in another language. Fix it by comparing the `type` enum value instead.

**Before (lines 11–14):**
```swift
var unpersistedActivities: [Activity] {
    let persistedNames = Set(activities.map { $0.name })
    return defaultActivities.filter { !persistedNames.contains($0.name) }
}
```

**After:**
```swift
var unpersistedActivities: [Activity] {
    let persistedTypes = Set(activities.map { $0.type })
    return defaultActivities.filter { !persistedTypes.contains($0.type) }
}
```

---

## Change 3 — Add localization keys to all Localizable.strings files

Append a `// MARK: - Default Activities` section at the end of each file (before the last blank line if one exists).

### en / en-CA / en-GB

```
// MARK: - Default Activities
"Car Travel" = "Car Travel";
"Airplane Flight" = "Airplane Flight";
"Boat Trip" = "Boat Trip";
"Motorcycle Ride" = "Motorcycle Ride";
"Bus Travel" = "Bus Travel";
"Train Travel" = "Train Travel";
"Beef Consumption" = "Beef Consumption";
"Chicken Consumption" = "Chicken Consumption";
"Vegetable Consumption" = "Vegetable Consumption";
"Rice Consumption" = "Rice Consumption";
"Dairy Consumption" = "Dairy Consumption";
"Electricity Usage" = "Electricity Usage";
"Walking" = "Walking";
"Biking" = "Biking";
"Tree Planting" = "Tree Planting";
"Recycling" = "Recycling";
```

### de (German)

```
// MARK: - Default Activities
"Car Travel" = "Autofahrt";
"Airplane Flight" = "Flugreise";
"Boat Trip" = "Bootsfahrt";
"Motorcycle Ride" = "Motorradfahrt";
"Bus Travel" = "Busfahrt";
"Train Travel" = "Zugfahrt";
"Beef Consumption" = "Rindfleischkonsum";
"Chicken Consumption" = "Hühnerkonsum";
"Vegetable Consumption" = "Gemüsekonsum";
"Rice Consumption" = "Reiskonsum";
"Dairy Consumption" = "Milchproduktkonsum";
"Electricity Usage" = "Stromverbrauch";
"Walking" = "Gehen";
"Biking" = "Radfahren";
"Tree Planting" = "Baumpflanzung";
"Recycling" = "Recycling";
```

### es (Spanish)

```
// MARK: - Default Activities
"Car Travel" = "Viaje en coche";
"Airplane Flight" = "Vuelo en avión";
"Boat Trip" = "Viaje en barco";
"Motorcycle Ride" = "Viaje en moto";
"Bus Travel" = "Viaje en autobús";
"Train Travel" = "Viaje en tren";
"Beef Consumption" = "Consumo de ternera";
"Chicken Consumption" = "Consumo de pollo";
"Vegetable Consumption" = "Consumo de verduras";
"Rice Consumption" = "Consumo de arroz";
"Dairy Consumption" = "Consumo de lácteos";
"Electricity Usage" = "Consumo eléctrico";
"Walking" = "Caminar";
"Biking" = "Ciclismo";
"Tree Planting" = "Plantación de árboles";
"Recycling" = "Reciclaje";
```

### fr (French)

```
// MARK: - Default Activities
"Car Travel" = "Trajet en voiture";
"Airplane Flight" = "Vol en avion";
"Boat Trip" = "Voyage en bateau";
"Motorcycle Ride" = "Trajet en moto";
"Bus Travel" = "Trajet en bus";
"Train Travel" = "Trajet en train";
"Beef Consumption" = "Consommation de bœuf";
"Chicken Consumption" = "Consommation de poulet";
"Vegetable Consumption" = "Consommation de légumes";
"Rice Consumption" = "Consommation de riz";
"Dairy Consumption" = "Consommation de produits laitiers";
"Electricity Usage" = "Consommation d'électricité";
"Walking" = "Marche";
"Biking" = "Vélo";
"Tree Planting" = "Plantation d'arbres";
"Recycling" = "Recyclage";
```

### it (Italian)

```
// MARK: - Default Activities
"Car Travel" = "Viaggio in auto";
"Airplane Flight" = "Volo in aereo";
"Boat Trip" = "Gita in barca";
"Motorcycle Ride" = "Viaggio in moto";
"Bus Travel" = "Viaggio in autobus";
"Train Travel" = "Viaggio in treno";
"Beef Consumption" = "Consumo di manzo";
"Chicken Consumption" = "Consumo di pollo";
"Vegetable Consumption" = "Consumo di verdure";
"Rice Consumption" = "Consumo di riso";
"Dairy Consumption" = "Consumo di latticini";
"Electricity Usage" = "Consumo di elettricità";
"Walking" = "Camminata";
"Biking" = "Ciclismo";
"Tree Planting" = "Piantumazione alberi";
"Recycling" = "Riciclaggio";
```

### nb (Norwegian Bokmål)

```
// MARK: - Default Activities
"Car Travel" = "Bilreise";
"Airplane Flight" = "Flyreise";
"Boat Trip" = "Båttur";
"Motorcycle Ride" = "Motorsykkeltur";
"Bus Travel" = "Bussreise";
"Train Travel" = "Togreise";
"Beef Consumption" = "Storfekjøttforbruk";
"Chicken Consumption" = "Kyllingforbruk";
"Vegetable Consumption" = "Grønnsaksforbruk";
"Rice Consumption" = "Risforbruk";
"Dairy Consumption" = "Meieriforbruk";
"Electricity Usage" = "Strømforbruk";
"Walking" = "Gåing";
"Biking" = "Sykling";
"Tree Planting" = "Treplanting";
"Recycling" = "Resirkulering";
```

### nl (Dutch)

```
// MARK: - Default Activities
"Car Travel" = "Autorit";
"Airplane Flight" = "Vliegtuigreis";
"Boat Trip" = "Boottrip";
"Motorcycle Ride" = "Motorrijden";
"Bus Travel" = "Busreis";
"Train Travel" = "Treinreis";
"Beef Consumption" = "Rundvleesconsumptie";
"Chicken Consumption" = "Kippenconsumptie";
"Vegetable Consumption" = "Groenteconsumptie";
"Rice Consumption" = "Rijstconsumptie";
"Dairy Consumption" = "Zuivelconsumptie";
"Electricity Usage" = "Elektriciteitsverbruik";
"Walking" = "Wandelen";
"Biking" = "Fietsen";
"Tree Planting" = "Boomplanten";
"Recycling" = "Recycling";
```

### pt (Portuguese — Portugal)

```
// MARK: - Default Activities
"Car Travel" = "Viagem de carro";
"Airplane Flight" = "Voo de avião";
"Boat Trip" = "Passeio de barco";
"Motorcycle Ride" = "Viagem de mota";
"Bus Travel" = "Viagem de autocarro";
"Train Travel" = "Viagem de comboio";
"Beef Consumption" = "Consumo de carne de vaca";
"Chicken Consumption" = "Consumo de frango";
"Vegetable Consumption" = "Consumo de vegetais";
"Rice Consumption" = "Consumo de arroz";
"Dairy Consumption" = "Consumo de laticínios";
"Electricity Usage" = "Consumo de eletricidade";
"Walking" = "Caminhada";
"Biking" = "Ciclismo";
"Tree Planting" = "Plantação de árvores";
"Recycling" = "Reciclagem";
```

### pt-BR (Portuguese — Brazil)

```
// MARK: - Default Activities
"Car Travel" = "Viagem de carro";
"Airplane Flight" = "Voo de avião";
"Boat Trip" = "Passeio de barco";
"Motorcycle Ride" = "Viagem de moto";
"Bus Travel" = "Viagem de ônibus";
"Train Travel" = "Viagem de trem";
"Beef Consumption" = "Consumo de carne bovina";
"Chicken Consumption" = "Consumo de frango";
"Vegetable Consumption" = "Consumo de vegetais";
"Rice Consumption" = "Consumo de arroz";
"Dairy Consumption" = "Consumo de laticínios";
"Electricity Usage" = "Consumo de eletricidade";
"Walking" = "Caminhada";
"Biking" = "Ciclismo";
"Tree Planting" = "Plantio de árvores";
"Recycling" = "Reciclagem";
```

### sv (Swedish)

```
// MARK: - Default Activities
"Car Travel" = "Bilresa";
"Airplane Flight" = "Flygresa";
"Boat Trip" = "Båttur";
"Motorcycle Ride" = "Motorcykeltur";
"Bus Travel" = "Bussresa";
"Train Travel" = "Tågresa";
"Beef Consumption" = "Nötköttkonsumtion";
"Chicken Consumption" = "Kycklingkonsumtion";
"Vegetable Consumption" = "Grönsakskonsumtion";
"Rice Consumption" = "Riskonsumtion";
"Dairy Consumption" = "Mejerikonsumtion";
"Electricity Usage" = "Elförbrukning";
"Walking" = "Promenad";
"Biking" = "Cykling";
"Tree Planting" = "Trädplantering";
"Recycling" = "Återvinning";
```

---

## Notes

- The 16 localization keys exactly match the English strings used in `String(localized:)` calls in `Activity.swift`. Do not rename them.
- `en-CA` and `en-GB` get the same values as `en` (English-variant files use the same English text).
- After this change, `defaultActivities` is a computed property, not a constant — this is intentional so `String(localized:)` is resolved at runtime using the active locale.
- Do not touch any other part of `Activity.swift` or `SelectActivitiesToPersistView.swift` beyond what is described above.
