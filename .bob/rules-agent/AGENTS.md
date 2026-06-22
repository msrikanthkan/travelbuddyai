# AGENTS.md — Agent (Code) Mode

This file provides guidance to agents when writing or modifying code in this repository.

## Critical coding gotchas

### New service checklist
1. Use singleton pattern (see root AGENTS.md)
2. Add `await ServiceName().initialize()` to `lib/main.dart` in correct order
3. Use `developer.log(msg, name: 'ServiceName')` — never `print()`
4. Cache in SharedPreferences with a versioned key; document the key in root AGENTS.md cache table

### New model checklist
1. Add `toJson()` / `fromJson()` with snake_case JSON ↔ camelCase Dart
2. Export from `lib/models/models.dart` — missing this breaks all cross-service imports

### New home screen feature checklist
1. Add entry to `travelIdeas` const list in `lib/services/ideas_service.dart` with a unique string `id`
2. Add `if (id == 'X')` navigation branch in `HomeScreen._openFeatureDetail()`
3. Add icon case to `HomeScreen._getIconForId()`

### BudgetService trap
`calculateFuelCost(km, origin)` and `calculateTollCharges(km, origin, dest)` both multiply `km × 2` internally — always pass **one-way** distance. There is no flag to disable round-trip doubling.

### TollService asset versioning
When editing `assets/toll_plazas.json`, bump `_assetVersion` in `TollService` (currently `'1.1'`) — otherwise users get stale cached data until the app is reinstalled.

### MapsService — two methods, one is legacy
Use `getRouteData()` (returns `RouteData` with polyline) for all new code. `getDistanceKm()` is a thin wrapper kept for backward compatibility — it discards the polyline, breaking toll matching.

### PricingService city name matching
City detection uses `String.contains()` — add both "bangalore" AND "bengaluru" to the list if supporting a city with multiple spellings. Unmatched cities silently fall back to tier 3 (cheapest prices).

### Destination loading — three services, one is production
- `DestinationsLoaderService` = static JSON fallback only
- `FirebaseDestinationsService` = production (Remote Config, 12h cache)
- `FirestoreDestinationsService` = real-time but not used in main flow
Do not use Firestore service for new features without explicit requirement.

### `withOpacity` is deprecated
Use `Color.withValues(alpha: x)` — `withOpacity` triggers lint warnings.

### Documentation
Run `.\update_documentation.ps1` after changes to check which sections of `TravelBuddyAI_Documentation.html` need updating.
