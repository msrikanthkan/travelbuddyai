# AGENTS.md - Advanced Mode Rules

This file provides advanced coding guidance for agents working in this Flutter/Dart repository.

## Critical Service Patterns

### Service Initialization Dependencies
Services MUST be initialized in main.dart in exact order (lib/main.dart:13-21):
```dart
await Firebase.initializeApp();
await TrainDataService().initialize();
await FirebaseDestinationsService().initialize();
```
Breaking this order causes Firebase dependency failures.

### Singleton Factory Pattern
All services use this exact pattern - never use `new`:
```dart
static final ServiceName _instance = ServiceName._internal();
factory ServiceName() => _instance;
ServiceName._internal();
```

### Dependency Injection in Services
BudgetService accepts PricingService via constructor (budget_service.dart:11):
```dart
BudgetService([PricingService? pricingService])
    : _pricingService = pricingService ?? PricingService();
```
Use this pattern for testability when creating new services.

## Data Model Conventions

### JSON Snake Case to Dart Camel Case
All models convert snake_case JSON to camelCase Dart (destination_model.dart:30-44):
- JSON: `estimated_cost`, `budget_range`, `occasion_types`
- Dart: `estimatedCost`, `budgetRange`, `occasionTypes`

### Round-Trip Distance Multiplier
ALL budget calculations multiply distance by 2 for round trips (budget_service.dart:24, 40):
```dart
final totalDistance = distanceKm * 2;  // Hardcoded, not configurable
```

## Firebase Remote Config

### Fetch Interval Constraint
Remote Config has 12-hour minimum fetch interval (train_data_service.dart:25):
```dart
minimumFetchInterval: const Duration(hours: 12)
```
Services cache in SharedPreferences to avoid rate limits.

### Cache Key Patterns
- Train data: `cached_train_data`, `train_data_version`
- Destinations: `cached_destinations_*`, `destinations_version_*`

## Service Architecture

### Three-Layer Destination Loading
Non-obvious: Three separate services for destinations:
1. `DestinationsLoaderService` - assets/destinations.json (static)
2. `FirebaseDestinationsService` - Remote Config (dynamic)
3. `FirestoreDestinationsService` - Firestore (real-time)

Production code should use FirebaseDestinationsService.

### Hidden City Tier System
PricingService._getCityTier() (pricing_service.dart:70) affects flight pricing:
- Tier 1: Metro cities (Mumbai, Delhi, Bangalore)
- Tier 2: Major cities
- Tier 3: Smaller cities
Not exposed in public API but critical for calculations.

## Advanced Mode Capabilities
- Access to MCP (Model Context Protocol) tools
- Access to Browser tools for research and documentation lookup
- Can perform complex multi-step operations

## Documentation Sync
After code changes, run `.\update_documentation.ps1` to check if TravelBuddyAI_Documentation.html (847 lines) needs updates.