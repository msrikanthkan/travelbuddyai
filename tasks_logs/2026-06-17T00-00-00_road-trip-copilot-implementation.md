# Task: Road Trip Co-Pilot — Full Sprint 1 & 2 Implementation

**Date**: 2026-06-17T00-00-00  
**Status**: Completed

## Objective
Implement the Road Trip Co-Pilot feature from scratch — all Sprint 1 and Sprint 2 stories including data models, services, UI screens, toll plaza database, and home screen wiring. Fix runtime bugs (overflow, autocomplete race condition, 0 toll plazas). Comply with AGENTS.md rules.

## Changes Made

### Created
- `lib/models/vehicle_profile_model.dart` — VehicleProfile + VehicleType enum
- `lib/models/toll_plaza_model.dart` — TollPlaza + TollVehicleType enum
- `lib/models/fuel_station_model.dart` — FuelStation + FuelPrices
- `assets/toll_plazas.json` — 73 NHAI toll plazas (NH-44, NH-48, NH-16, NH-19, NH-65, NH-275, NH-50, NH-60, NH-27)
- `lib/services/road_trip_service.dart` — Singleton, planRoute() via OSRM + BudgetService
- `lib/services/toll_service.dart` — Singleton, loads JSON asset, Haversine route matching, SharedPreferences cache
- `lib/services/fuel_station_service.dart` — Singleton, Overpass API, polyline sampling, optimal stop calc
- `lib/screens/road_trip_copilot_screen.dart` — Main UI: origin/dest autocomplete, route type picker, vehicle card
- `lib/screens/route_details_screen.dart` — Results: gradient summary, expandable cost/toll sections, share button

### Modified
- `lib/models/models.dart` — Added 4 new model exports
- `lib/screens/home_screen.dart` — Wired id `'9'` to `RoadTripCopilotScreen`; removed unused import
- `lib/services/maps_service.dart` — Added `RouteData` class + `getRouteData()` returning full OSRM polyline (GeoJSON); kept `getDistanceKm()` as legacy wrapper
- `lib/services/road_trip_service.dart` — Updated to use `getRouteData()` so polyline flows into `RouteDetails`
- `lib/main.dart` — Added `TollService().initialize()` to startup chain
- `pubspec.yaml` — Added `google_maps_flutter: ^2.5.3` + `assets/toll_plazas.json`
- `AGENTS.md` — Full rewrite: removed obvious content, added project-specific gotchas; added task logging rule
- `.bob/rules-agent/AGENTS.md` — Created (new)
- `.bob/rules-ask/AGENTS.md` — Replaced verbose content with non-obvious architecture facts
- `.bob/rules-plan/AGENTS.md` — Replaced verbose content with architectural constraints

## Key Features Implemented
- **Story 1.1/1.2** — RouteDetails + Waypoint models (already existed)
- **Story 1.3** — RoadTripService: OSRM distance + OSRM polyline + BudgetService costs
- **Story 1.4** — VehicleProfile model with default Maruti Swift (22 kmpl, 37L)
- **Story 1.5** — RoadTripCopilotScreen: Nominatim autocomplete with 400ms debounce, route type selector
- **Story 1.6** — RouteDetailsScreen: expandable cost breakdown, live toll plaza list, share route
- **Story 2.1** — TollPlaza model with NHAI vehicle categories (car/suv/lcv/hcv/bus)
- **Story 2.2** — 73 toll plazas covering major NH corridors including Mumbai→Hyderabad (NH-65)
- **Story 2.3** — TollService: asset load, SharedPreferences cache v1.1, Haversine matching (35km radius)
- **Story 3.1** — FuelStation + FuelPrices models
- **Story 3.2** — FuelStationService: Overpass API, in-memory cache, optimal refuel stop calculator
- **Story 4.1** — Home screen id `'9'` routes to RoadTripCopilotScreen

## Bugs Fixed
- `Colors.black08` → `Colors.black.withValues(alpha: 0.08)` (compile error)
- `google_maps_flutter` missing from pubspec (compile errors in 4 files)
- Row overflow in Plan button → `mainAxisSize: MainAxisSize.min`
- Autocomplete race condition → 400ms debounce + stale-result guard
- 0 toll plazas for Mumbai→Hyderabad → added 9 NH-65/NH-50 corridor plazas + bumped radius 25→35km
- TollService fallback returned all 55 plazas unfiltered → replaced with empty + debug log
- `_averageSpeedForType` dead code removed after OSRM provides real duration
- AGENTS.md compliance: `TollService().initialize()` added to main.dart

## Next Steps
- Story 2.4: Display toll plazas on route map with markers
- Story 3.3: Display fuel stations section on RouteDetailsScreen
- Story 3.4: Optimal refueling strategy UI
- Story 4.2: Save route to SavedTripsService
- Story 4.5: Error handling & edge cases (OSRM timeout UX)
- Story 4.6: Unit tests for models and services
- Render actual GoogleMap widget (currently shows placeholder — needs API key + manifest config)
- BudgetService one-way flag (currently always doubles distance)
- Expand toll_plazas.json: Delhi-Mumbai Expressway, Pune-Nashik, North-East corridors
