# AGENTS.md - Ask Mode Rules

This file provides documentation context for agents answering questions about this Flutter/Dart repository.

## Project Structure Context

### Three-Layer Destination System
Non-obvious: Destinations are loaded from THREE separate sources:
1. `assets/destinations.json` - Static fallback data
2. Firebase Remote Config - Dynamic updates (12-hour fetch interval)
3. Firestore - Real-time data

When answering questions about destinations, clarify which source is being used.

### Service Initialization Order Matters
Firebase services have strict initialization order in main.dart:
1. Firebase.initializeApp()
2. TrainDataService().initialize()
3. FirebaseDestinationsService().initialize()

This is critical for understanding startup behavior.

## Hidden Implementation Details

### Budget Calculations Always Round-Trip
All distance-based calculations multiply by 2 (budget_service.dart:24, 40):
- Fuel costs
- Toll charges
- Train/flight distances

This is hardcoded, not configurable per trip type.

### City Tier System for Flight Pricing
PricingService has undocumented city tier system (pricing_service.dart:70):
- Tier 1: Metro cities (Mumbai, Delhi, Bangalore, etc.)
- Tier 2: Major cities
- Tier 3: Smaller cities

Affects flight pricing calculations but not exposed in public API.

### JSON to Dart Naming Convention
All models convert snake_case JSON to camelCase Dart:
- JSON: `estimated_cost`, `budget_range`, `occasion_types`
- Dart: `estimatedCost`, `budgetRange`, `occasionTypes`

Important when discussing data models or API responses.

## Documentation Files

### Primary Documentation
- `TravelBuddyAI_Documentation.html` - 847 lines, comprehensive technical docs
- `FIREBASE_COMPLETE_SETUP.md` - Complete Firebase setup guide
- `update_documentation.ps1` - Helper script to check what needs updating

### Setup Guides
Multiple setup guides exist for different services:
- Firebase, Firestore, OpenWeather, Google Places, Google Search APIs
- Each has specific configuration requirements

## Firebase Remote Config Caching

### 12-Hour Fetch Interval
Remote Config has minimum 12-hour fetch interval (train_data_service.dart:25).
Services cache data in SharedPreferences with keys:
- `cached_train_data`, `train_data_version`
- `cached_destinations_*`, `destinations_version_*`

Important for understanding data freshness and offline behavior.

## Cloud Functions

### Node.js 22 Runtime
Firebase Cloud Functions use Node.js 22 (firebase.json).
Functions directory has separate package.json and dependencies.