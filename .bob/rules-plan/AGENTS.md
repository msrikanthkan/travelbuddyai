# AGENTS.md - Plan Mode Rules

This file provides architectural planning guidance for agents working in this Flutter/Dart repository.

## Service Architecture Constraints

### Singleton Pattern is Mandatory
ALL services use singleton factory pattern:
```dart
static final ServiceName _instance = ServiceName._internal();
factory ServiceName() => _instance;
ServiceName._internal();
```
Never plan for services that use `new` keyword or multiple instances.

### Service Initialization Order is Critical
Firebase services have strict initialization dependencies (main.dart:13-21):
1. Firebase.initializeApp() - Must be first
2. TrainDataService().initialize() - Depends on Firebase
3. FirebaseDestinationsService().initialize() - Depends on Firebase

New services requiring Firebase must be initialized after Firebase.initializeApp().

### Three-Layer Data Loading Pattern
Destinations use three-layer loading (non-standard architecture):
1. Static assets (assets/destinations.json)
2. Firebase Remote Config (dynamic updates)
3. Firestore (real-time data)

When planning new features, consider which layer is appropriate:
- Static: Rarely changing reference data
- Remote Config: Periodic updates (12-hour minimum)
- Firestore: Real-time or frequently changing data

## Data Model Constraints

### JSON Snake Case to Dart Camel Case
All models must convert snake_case JSON to camelCase Dart properties.
Plan API integrations with this conversion in mind.

### Round-Trip Calculations are Hardcoded
Budget calculations multiply distance by 2 (budget_service.dart:24, 40).
This is NOT configurable - plan features assuming round-trip only.
One-way trip support would require architectural changes.

## Firebase Remote Config Limitations

### 12-Hour Minimum Fetch Interval
Remote Config has 12-hour minimum fetch interval (train_data_service.dart:25).
Plan features requiring frequent updates to use Firestore instead.

### Caching Strategy Required
All Remote Config services cache in SharedPreferences.
Plan new Remote Config features with cache keys:
- Data key: `cached_[feature]_data`
- Version key: `[feature]_version`

## Hidden Dependencies

### City Tier System for Pricing
PricingService has undocumented city tier system (pricing_service.dart:70).
When planning pricing features, consider:
- Tier 1: Metro cities (lower flight prices due to competition)
- Tier 2: Major cities (moderate pricing)
- Tier 3: Smaller cities (higher prices)

This affects flight pricing but is not exposed in public API.

### Dependency Injection Pattern
Services use optional dependency injection (budget_service.dart:11):
```dart
BudgetService([PricingService? pricingService])
    : _pricingService = pricingService ?? PricingService();
```
Plan new services with this pattern for testability.

## Documentation Requirements

### Documentation Must Stay in Sync
TravelBuddyAI_Documentation.html (847 lines) must be updated for:
- New features
- Modified services
- Changed data models
- Updated dependencies

Run `.\update_documentation.ps1` to check what needs updating.

## Cloud Functions Architecture

### Node.js 22 Runtime
Firebase Cloud Functions use Node.js 22 (firebase.json).
Plan functions with this runtime in mind.

### Separate Deployment
Functions have separate package.json and deploy independently:
`firebase deploy --only functions`