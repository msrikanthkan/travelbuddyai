# AGENTS.md — Plan Mode

This file provides guidance to agents planning changes or new features in this repository.

## Architectural constraints

### Service startup coupling
`main.dart` initialisation is sequential and order-sensitive. Firebase must be first (Remote Config and Firestore depend on it). TollService must be last (no Firebase dependency, but convention). Any new service with async setup goes in this chain — a missing `initialize()` call causes silent failures, not crashes.

### BudgetService is not road-trip aware
`calculateFuelCost()` and `calculateTollCharges()` always apply a × 2 round-trip multiplier with no override. Any one-way cost feature requires either: (a) dividing results by 2, or (b) adding a `oneWay` parameter — a breaking change to the existing budget planner.

### TollService matching requires a polyline
`getTollPlazasOnRoute()` returns nothing if `RouteDetails.polylinePoints` is empty. The polyline comes from `MapsService.getRouteData()` via OSRM — if OSRM times out (10–15s), toll matching silently returns 0 results. Plan for a timeout/fallback UX in any toll-dependent feature.

### Toll data coverage gaps
`assets/toll_plazas.json` covers major NH corridors. State highways, Delhi-Mumbai Expressway, Pune-Nashik, and North-East India are missing. Plans that promise "all Indian toll plazas" require either: a paid API (TollGuru/MapmyIndia), an OSM data export script, or explicit scope limitation.

### Three destination services — only one wired
New features should use `FirebaseDestinationsService` only. Do not couple new features to `FirestoreDestinationsService` (it exists but is not part of the production flow) unless explicitly migrating the architecture.

### No named routes / deep links
The app uses `MaterialPageRoute` push-only navigation with id-string dispatch in `HomeScreen`. Adding deep linking or a bottom nav bar requires replacing this with a proper router (`go_router` or similar) — a significant refactor.

### PricingService city recognition is string-contains only
Plans that extend pricing to new Indian cities must add city name strings to `_extractState()` and `_getCityTier()` in `pricing_service.dart`. The method has no fuzzy matching — "Bengaluru" and "Bangalore" are treated as different strings.

### Google Maps widget not yet rendered
`google_maps_flutter` is a dependency for `LatLng` type only. Route map display shows a placeholder. Rendering an actual interactive map requires a Google Maps API key, Android/iOS manifest config, and a `GoogleMap` widget — none of which are set up.

### SavedTripsService has a 50-trip hard cap
`SavedTripsService` throws at write time when 50 trips exist. Any feature that auto-saves trips (e.g., auto-saving a planned road trip) must handle this exception in the UI.
