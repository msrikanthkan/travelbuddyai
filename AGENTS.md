# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Build & Test Commands
- **Run app**: `flutter run`
- **Build APK**: `flutter build apk --release`
- **Build App Bundle**: `flutter build appbundle --release`
- **Run tests**: `flutter test`
- **Analyze code**: `flutter analyze`
- **Get dependencies**: `flutter pub get`

## Firebase Cloud Functions
- **Deploy functions**: `firebase deploy --only functions` (run from project root)
- **Test locally**: `cd functions && npm run serve`
- **Lint functions**: `cd functions && npm run lint`
- Functions use Node.js 22 runtime (see firebase.json)

## Critical Non-Obvious Patterns

### Service Initialization Order
Services MUST be initialized in main.dart in this exact order:
1. Firebase.initializeApp()
2. TrainDataService().initialize()
3. FirebaseDestinationsService().initialize()

Changing this order will cause runtime failures due to Firebase dependency chain.

### Singleton Pattern Usage
All services use singleton pattern with factory constructors:
```dart
static final ServiceName _instance = ServiceName._internal();
factory ServiceName() => _instance;
ServiceName._internal();
```
Never instantiate services with `new` - always use `ServiceName()` to get singleton.

### Firebase Remote Config Caching
- Remote Config has 12-hour minimum fetch interval (see train_data_service.dart:25)
- Services cache data in SharedPreferences with keys: `cached_train_data`, `cached_destinations_*`
- Version keys track updates: `train_data_version`, `destinations_version_*`
- Always check cache before fetching to avoid rate limits

### Destination Loading Strategy
Three separate services handle destinations (non-obvious architecture):
1. `DestinationsLoaderService` - loads from assets/destinations.json (static fallback)
2. `FirebaseDestinationsService` - loads from Firebase Remote Config (dynamic updates)
3. `FirestoreDestinationsService` - loads from Firestore (real-time data)

Use FirebaseDestinationsService for production, others are fallbacks.

### Budget Calculations
All budget calculations use round-trip multiplier (distance * 2) - see budget_service.dart:24, 40
This is hardcoded and not configurable per trip type.

### Model fromJson Pattern
All models use snake_case in JSON but camelCase in Dart:
- JSON: `estimated_cost`, `budget_range`, `occasion_types`
- Dart: `estimatedCost`, `budgetRange`, `occasionTypes`

### Pricing Service City Tiers
PricingService uses undocumented city tier system (1-3) for flight pricing:
- Tier 1: Metro cities (Mumbai, Delhi, Bangalore, etc.)
- Tier 2: Major cities
- Tier 3: Smaller cities
See _getCityTier() method - not exposed in public API but affects all flight calculations.

### Documentation Maintenance
When modifying code, run `.\update_documentation.ps1` to check which documentation needs updates.
The TravelBuddyAI_Documentation.html file (847 lines) must stay in sync with code changes.

## Code Style
- Uses flutter_lints package (standard Flutter lints)
- No custom lint rules enabled in analysis_options.yaml
- Prefer explicit types over `var` for public APIs
- Use `const` constructors where possible
- Services use dependency injection pattern (see BudgetService constructor accepting PricingService)