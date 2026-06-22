# AGENTS.md — Ask Mode

This file provides guidance to agents answering questions about this repository.

## Non-obvious architecture

### There are THREE destination services — only one is production
- `DestinationsLoaderService` → `assets/destinations.json` (static bundled fallback)
- `FirebaseDestinationsService` → Firebase Remote Config (production, 12h cache)
- `FirestoreDestinationsService` → Firestore (exists but not wired into main feature flow)
Questions about "why destinations aren't updating" almost always trace to Remote Config 12h cache.

### Maps/routing uses no paid API
Geocoding = Nominatim (OpenStreetMap). Routing = OSRM public instance. No Google Maps API key is required or configured for routing. `google_maps_flutter` package is only used for the `LatLng` type — the actual Maps widget is not yet rendered.

### Toll plaza data is bundled, not live
`assets/toll_plazas.json` contains 73 hardcoded NHAI plazas. Coverage is major national highways only — state highways and new expressways are missing. Matching is geographic (Haversine 35km radius against the OSRM polyline).

### BudgetService always calculates round-trip
All cost estimates (fuel, tolls) shown in the app are round-trip even for one-way journeys. This is intentional and hardcoded — `distanceKm × 2` in `budget_service.dart:24`.

### Home screen navigation is id-string dispatch, not named routes
There is no Flutter Navigator route table. Features are identified by string ids (`'1'`, `'9'` etc.) in `lib/services/ideas_service.dart`. New feature screens require an explicit `if` branch in `HomeScreen._openFeatureDetail()`.

### SavedTripsService is static methods only
Unlike all other services, `SavedTripsService` uses static methods (no singleton, no instance). Max 50 saved trips enforced at write time.

### PricingService is not a singleton
`BudgetService` accepts an optional `PricingService` via constructor injection. `PricingService` has no singleton — it is instantiated per `BudgetService` instance.

### Road Trip Co-Pilot screen flow
`RoadTripCopilotScreen` → `RoadTripService.planRoute()` → `MapsService.getRouteData()` (OSRM) → `RouteDetailsScreen` → `TollService.getTollPlazasOnRoute()` (loads at startup in main.dart).
