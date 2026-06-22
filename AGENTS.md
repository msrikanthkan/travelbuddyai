# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Task Logging — REQUIRED for every task
For every task created or completed, create a log file in `tasks_logs/` (project root, create if absent).

**Filename format**: `yyyy-mm-ddTHH-mm-ss_<concise-task-summary>.md`
**Example**: `tasks_logs/2026-06-17T10-30-00_road-trip-copilot-implementation.md`

**Required content**: Task title · Date/Time · Objective · Files created/modified · Key features · Status · Next steps

```markdown
# Task: [Name]
**Date**: 2026-06-17T10:30:00  **Status**: Completed
## Objective
## Changes Made
- Created: file.dart
- Modified: other.dart
## Key Features Implemented
## Next Steps
```

## Commands
- `flutter run` · `flutter build apk --release` · `flutter analyze` · `flutter pub get`
- Single test: `flutter test test/path/to_test.dart`
- Run `.\update_documentation.ps1` after any change to check which sections of `TravelBuddyAI_Documentation.html` need updating (sections: Data Models, Services & APIs, Core Features, UI, Dependencies, Firebase, Architecture)

## Service Initialization — STRICT ORDER in main.dart
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await TrainDataService().initialize();
await FirebaseDestinationsService().initialize();
await TollService().initialize();
```
Adding a service with `initialize()` MUST go here. Changing this order breaks Firebase dependency chain.

## Singleton Pattern — ALL services
```dart
static final Foo _instance = Foo._internal();
factory Foo() => _instance;
Foo._internal();
```
Never use `new`. Always call `ServiceName()` to get the singleton.

## BudgetService always doubles distance (round-trip)
`calculateFuelCost(distanceKm, origin)` and `calculateTollCharges(distanceKm, ...)` multiply distance × 2 internally. Pass one-way distance — the result is always round-trip cost. No configurable override exists.

## Home screen feature routing — id-based dispatch
Features are defined in `lib/services/ideas_service.dart` as a const list with string `id` keys. Navigation in `HomeScreen._openFeatureDetail()` switches on `id`. To wire a new screen, add an entry to `travelIdeas` and add an `if (id == 'X')` branch — there is no route table or named routes.

## Models barrel — always update
All models are re-exported from `lib/models/models.dart`. New model files MUST be added there or imports across the app break.

## SharedPreferences cache keys in use
| Key | Owner |
|---|---|
| `cached_train_data` / `train_data_version` | TrainDataService |
| `cached_destinations_*` / `destinations_version_*` | FirebaseDestinationsService |
| `toll_plazas_cache` / `toll_plazas_version` | TollService (current version: `1.1`) |
| `saved_trips` (max 50) | SavedTripsService |

Bump `_assetVersion` in TollService when `assets/toll_plazas.json` changes, or cached stale data will be served.

## Routing / Maps — no Google Maps API key required
- Geocoding: Nominatim (`nominatim.openstreetmap.org`) — free, requires `User-Agent: TravelBuddyAI/1.0` header
- Routing: OSRM public instance (`router.project-osrm.org`) — free, no key
- `MapsService.getRouteData()` returns `RouteData` (distance + duration + polyline). `getDistanceKm()` is a legacy thin wrapper.
- Polyline uses GeoJSON order: `[lon, lat]` — reversed to `LatLng(lat, lon)` when decoded.

## PricingService city matching — substring only
`_extractState()` and `_getCityTier()` use `String.contains()` on lowercase input. "Bangalore" matches but "Bengaluru" does NOT match "bangalore" — both spellings must be present or calls fall through to defaults (tier 3 / ₹105/L fuel).

## TollService matching
Uses Haversine against route polyline points (radius 35 km). Zero results means either no polyline (OSRM failed) or no plazas in `assets/toll_plazas.json` for that corridor. Check the debug log: `TollService: matched X/73 plazas from Y polyline points`.

## Code style
- `dart:developer` (`developer.log(...)`) for all service logging — never `print()` in services
- `withValues(alpha: x)` not `withOpacity(x)` (deprecated)
- Explicit types on public APIs; `const` constructors where possible
- JSON: snake_case keys → Dart: camelCase fields (enforced in all models)
