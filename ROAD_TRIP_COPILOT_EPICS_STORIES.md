# Road Trip Co-Pilot - Epics & User Stories

## Overview
This document breaks down the Road Trip Co-Pilot feature into Epics and User Stories following Agile methodology. Each story includes acceptance criteria, story points, and dependencies.

---

## Epic 1: Core Route Planning 🗺️
**Epic Goal**: Enable users to plan a road trip with origin, destination, and get basic route information with cost estimates.

**Business Value**: Foundation for all road trip features. Users can plan trips and understand costs upfront.

**Story Points**: 21

---

### Story 1.1: Route Details Data Model
**As a** developer  
**I want** to create a RouteDetails data model  
**So that** we can store and manage route information consistently across the app

**Acceptance Criteria**:
- [ ] Create `lib/models/route_model.dart` with RouteDetails class
- [ ] Include fields: routeId, origin, destination, waypoints, totalDistanceKm, estimatedDuration
- [ ] Include cost fields: estimatedFuelCost, estimatedTollCost
- [ ] Add toJson() and fromJson() methods for serialization
- [ ] Include RouteType enum (fastest, shortest, scenic, fuel_efficient)
- [ ] Add polylinePoints list for map rendering
- [ ] Write unit tests for model serialization

**Story Points**: 3  
**Priority**: P0 (Blocker)  
**Dependencies**: None

**Technical Notes**:
```dart
// lib/models/route_model.dart
class RouteDetails {
  final String routeId;
  final String origin;
  final String destination;
  final List<Waypoint> waypoints;
  final double totalDistanceKm;
  final Duration estimatedDuration;
  final double estimatedFuelCost;
  final double estimatedTollCost;
  final RouteType type;
  final List<LatLng> polylinePoints;
}

enum RouteType { fastest, shortest, scenic, fuelEfficient }
```

---

### Story 1.2: Waypoint Data Model
**As a** developer  
**I want** to create a Waypoint data model  
**So that** we can represent stops along the route

**Acceptance Criteria**:
- [ ] Create Waypoint class in `lib/models/route_model.dart`
- [ ] Include fields: name, location (LatLng), stopDuration, type
- [ ] Add WaypointType enum (fuel, food, rest, attraction, toll)
- [ ] Add toJson() and fromJson() methods
- [ ] Include distanceFromOriginKm field

**Story Points**: 2  
**Priority**: P0 (Blocker)  
**Dependencies**: Story 1.1

---

### Story 1.3: Basic RoadTripService Implementation
**As a** developer  
**I want** to implement RoadTripService with basic route planning  
**So that** we can calculate routes between two locations

**Acceptance Criteria**:
- [ ] Create `lib/services/road_trip_service.dart`
- [ ] Implement singleton pattern (as per AGENTS.md rules)
- [ ] Add planRoute() method that uses MapsService for distance
- [ ] Calculate estimated duration based on average speed (60 km/h)
- [ ] Integrate with BudgetService for fuel and toll cost estimation
- [ ] Return RouteDetails object with all calculated data
- [ ] Handle errors gracefully with null safety
- [ ] Add logging for debugging

**Story Points**: 5  
**Priority**: P0 (Blocker)  
**Dependencies**: Story 1.1, Story 1.2, Existing MapsService, Existing BudgetService

**Technical Notes**:
```dart
// lib/services/road_trip_service.dart
class RoadTripService {
  static final RoadTripService _instance = RoadTripService._internal();
  factory RoadTripService() => _instance;
  RoadTripService._internal();

  Future<RouteDetails?> planRoute(
    String origin,
    String destination,
    {RouteType type = RouteType.fastest}
  ) async {
    // Use MapsService for distance
    // Use BudgetService for costs
    // Return RouteDetails
  }
}
```

---

### Story 1.4: Vehicle Profile Data Model
**As a** user  
**I want** to save my vehicle details  
**So that** the app can provide accurate fuel cost estimates

**Acceptance Criteria**:
- [ ] Create `lib/models/vehicle_profile_model.dart`
- [ ] Include fields: vehicleId, make, model, year, type (VehicleType enum)
- [ ] Add fuelTankCapacityLiters and averageMileageKmpl
- [ ] Add toJson() and fromJson() methods
- [ ] Create VehicleType enum (car, suv, sedan, hatchback)
- [ ] Add default vehicle profile for first-time users

**Story Points**: 3  
**Priority**: P0 (Blocker)  
**Dependencies**: None

---

### Story 1.5: Road Trip Co-Pilot Main Screen UI
**As a** user  
**I want** to see a dedicated Road Trip Co-Pilot screen  
**So that** I can start planning my road trip

**Acceptance Criteria**:
- [ ] Create `lib/screens/road_trip_copilot_screen.dart`
- [ ] Add origin and destination input fields with autocomplete
- [ ] Add vehicle selection dropdown (default vehicle if none selected)
- [ ] Add route type selector (Fastest/Shortest/Fuel Efficient)
- [ ] Add "Plan My Route" button
- [ ] Show loading indicator during route calculation
- [ ] Navigate to Route Details screen on success
- [ ] Show error message on failure
- [ ] Match TravelBuddyAI design system (purple theme)
- [ ] Add quick action buttons (Fuel, Toll, Food) - disabled for MVP

**Story Points**: 5  
**Priority**: P0 (Blocker)  
**Dependencies**: Story 1.3, Story 1.4

**UI Mockup Reference**: See ROAD_TRIP_COPILOT_PLAN.md Section 4.1

---

### Story 1.6: Route Details Screen UI
**As a** user  
**I want** to see detailed information about my planned route  
**So that** I can understand the journey before starting

**Acceptance Criteria**:
- [ ] Create `lib/screens/route_details_screen.dart`
- [ ] Display route summary card (distance, duration, fuel cost, toll cost, total)
- [ ] Show interactive map with route polyline
- [ ] Display origin and destination markers
- [ ] Add "Start Navigation" button (placeholder for future)
- [ ] Add "Save Route" button
- [ ] Add "Share Route" button using existing ShareService
- [ ] Show breakdown of costs in expandable sections
- [ ] Handle loading states
- [ ] Add back button to return to main screen

**Story Points**: 8  
**Priority**: P0 (Blocker)  
**Dependencies**: Story 1.5

**UI Mockup Reference**: See ROAD_TRIP_COPILOT_PLAN.md Section 4.2

---

## Epic 2: Toll Plaza Information 🛣️
**Epic Goal**: Provide users with detailed toll plaza information including locations and exact charges.

**Business Value**: Users can budget accurately for tolls and know what to expect on their journey.

**Story Points**: 13

---

### Story 2.1: Toll Plaza Data Model
**As a** developer  
**I want** to create a TollPlaza data model  
**So that** we can store toll plaza information

**Acceptance Criteria**:
- [ ] Create `lib/models/toll_plaza_model.dart`
- [ ] Include fields: id, name, location (LatLng), distanceFromOriginKm
- [ ] Add charges map for different vehicle types
- [ ] Add hasFastag, operatingHours, paymentMethods fields
- [ ] Add highway field (e.g., "NH-44", "NH-16")
- [ ] Add toJson() and fromJson() methods
- [ ] Create VehicleType enum (car, suv, lcv, hcv, bus)

**Story Points**: 3  
**Priority**: P0 (Blocker)  
**Dependencies**: None

**Technical Notes**:
```dart
// lib/models/toll_plaza_model.dart
class TollPlaza {
  final String id;
  final String name;
  final LatLng location;
  final double distanceFromOriginKm;
  final Map<VehicleType, double> charges;
  final bool hasFastag;
  final String operatingHours;
  final List<String> paymentMethods;
  final String highway;
}

enum VehicleType { car, suv, lcv, hcv, bus }
```

---

### Story 2.2: Toll Plaza Database
**As a** developer  
**I want** to create a local database of major toll plazas  
**So that** we can provide toll information without external APIs

**Acceptance Criteria**:
- [ ] Create `assets/toll_plazas.json` with major Indian toll plazas
- [ ] Include at least 50 major toll plazas on key highways
- [ ] Include NH-44, NH-16, NH-48, NH-8, NH-27 toll plazas
- [ ] Add accurate charges for each vehicle type
- [ ] Include FASTag availability information
- [ ] Document data sources and last update date
- [ ] Add data validation script

**Story Points**: 5  
**Priority**: P1 (High)  
**Dependencies**: Story 2.1

**Data Structure**:
```json
{
  "toll_plazas": [
    {
      "id": "khalapur_toll",
      "name": "Khalapur Toll Plaza",
      "latitude": 18.8667,
      "longitude": 73.1833,
      "highway": "NH-48",
      "charges": {
        "car": 140,
        "suv": 140,
        "lcv": 230,
        "hcv": 470,
        "bus": 470
      },
      "hasFastag": true,
      "operatingHours": "24x7",
      "paymentMethods": ["FASTag", "Cash", "Card"]
    }
  ]
}
```

---

### Story 2.3: TollService Implementation
**As a** developer  
**I want** to implement TollService to manage toll plaza data  
**So that** we can find toll plazas on routes and calculate costs

**Acceptance Criteria**:
- [ ] Create `lib/services/toll_service.dart`
- [ ] Implement singleton pattern
- [ ] Add initialize() method to load toll_plazas.json
- [ ] Cache toll data in SharedPreferences
- [ ] Add getTollPlazasOnRoute() method
- [ ] Add calculateTollCost() method for vehicle type
- [ ] Add getNearestTollPlaza() method
- [ ] Handle errors gracefully
- [ ] Add logging for debugging

**Story Points**: 5  
**Priority**: P1 (High)  
**Dependencies**: Story 2.1, Story 2.2

**Technical Notes**:
```dart
// lib/services/toll_service.dart
class TollService {
  static final TollService _instance = TollService._internal();
  factory TollService() => _instance;
  TollService._internal();

  Future<void> initialize() async {
    // Load toll_plazas.json
    // Cache in SharedPreferences
  }

  Future<List<TollPlaza>> getTollPlazasOnRoute(
    RouteDetails route,
    {double maxDistanceKm = 5.0}
  ) async {
    // Find toll plazas near route
  }

  double calculateTollCost(
    List<TollPlaza> plazas,
    VehicleType vehicleType
  ) {
    // Sum up toll charges
  }
}
```

---

### Story 2.4: Display Toll Plazas on Route Details Screen
**As a** user  
**I want** to see all toll plazas on my route  
**So that** I know where I'll need to pay tolls and how much

**Acceptance Criteria**:
- [ ] Add toll plazas section to Route Details screen
- [ ] Show list of toll plazas with name, distance, and charge
- [ ] Display total toll cost prominently
- [ ] Show toll plaza markers on map
- [ ] Add expandable details for each toll plaza
- [ ] Show FASTag availability indicator
- [ ] Display payment methods accepted
- [ ] Add "Toll-Free Route" option (if available)

**Story Points**: 5  
**Priority**: P1 (High)  
**Dependencies**: Story 1.6, Story 2.3

---

## Epic 3: Fuel Station Finder ⛽
**Epic Goal**: Help users find fuel stations along their route with pricing information.

**Business Value**: Users can plan refueling stops and find the best fuel prices.

**Story Points**: 13

---

### Story 3.1: Fuel Station Data Model
**As a** developer  
**I want** to create a FuelStation data model  
**So that** we can store fuel station information

**Acceptance Criteria**:
- [ ] Create `lib/models/fuel_station_model.dart`
- [ ] Include fields: id, name, brand, location (LatLng)
- [ ] Add distanceFromRouteKm and distanceFromCurrentKm
- [ ] Add FuelPrices nested class (petrol, diesel, lastUpdated)
- [ ] Add amenities list, rating, isOpen24x7, contactNumber
- [ ] Add toJson() and fromJson() methods

**Story Points**: 3  
**Priority**: P1 (High)  
**Dependencies**: None

---

### Story 3.2: FuelStationService Implementation
**As a** developer  
**I want** to implement FuelStationService using Google Places API  
**So that** we can find real fuel stations along routes

**Acceptance Criteria**:
- [ ] Create `lib/services/fuel_station_service.dart`
- [ ] Implement singleton pattern
- [ ] Add findNearbyStations() using Google Places API
- [ ] Filter for gas_station type
- [ ] Add getFuelStationsOnRoute() method
- [ ] Integrate with PricingService for fuel prices
- [ ] Add caching to reduce API calls
- [ ] Handle API errors with fallback
- [ ] Add rate limiting

**Story Points**: 5  
**Priority**: P1 (High)  
**Dependencies**: Story 3.1, Existing PricingService, Google Places API setup

**Technical Notes**:
```dart
// lib/services/fuel_station_service.dart
class FuelStationService {
  static final FuelStationService _instance = FuelStationService._internal();
  factory FuelStationService() => _instance;
  FuelStationService._internal();

  Future<List<FuelStation>> findNearbyStations(
    LatLng location,
    double radiusKm
  ) async {
    // Use Google Places API
    // Get fuel prices from PricingService
  }

  Future<List<FuelStation>> getFuelStationsOnRoute(
    RouteDetails route,
    {double maxDistanceKm = 5.0}
  ) async {
    // Find stations along route
  }
}
```

---

### Story 3.3: Display Fuel Stations on Route Details Screen
**As a** user  
**I want** to see fuel stations along my route  
**So that** I can plan where to refuel

**Acceptance Criteria**:
- [ ] Add fuel stations section to Route Details screen
- [ ] Show recommended fuel stops (2-3 stations)
- [ ] Display station name, brand, distance, and fuel prices
- [ ] Show fuel station markers on map
- [ ] Add "Show All Stations" button to expand list
- [ ] Display amenities icons (restroom, food, ATM)
- [ ] Show 24x7 indicator
- [ ] Add tap to call functionality

**Story Points**: 5  
**Priority**: P1 (High)  
**Dependencies**: Story 1.6, Story 3.2

---

### Story 3.4: Optimal Refueling Strategy
**As a** user  
**I want** the app to suggest optimal refueling points  
**So that** I can minimize fuel costs and avoid running out of fuel

**Acceptance Criteria**:
- [ ] Calculate fuel range based on vehicle profile
- [ ] Suggest refueling when fuel drops below 25%
- [ ] Recommend cheapest station within range
- [ ] Show fuel cost savings comparison
- [ ] Display "Low Fuel Warning" if no station in range
- [ ] Consider round-trip fuel requirements

**Story Points**: 5  
**Priority**: P2 (Medium)  
**Dependencies**: Story 3.2, Story 1.4

---

## Epic 4: Integration & Polish 🔧
**Epic Goal**: Integrate Road Trip Co-Pilot with existing app features and polish the user experience.

**Business Value**: Seamless user experience and consistent with existing app functionality.

**Story Points**: 13

---

### Story 4.1: Update Home Screen with Road Trip Co-Pilot Entry
**As a** user  
**I want** to access Road Trip Co-Pilot from the home screen  
**So that** I can easily start planning road trips

**Acceptance Criteria**:
- [ ] Update `lib/services/ideas_service.dart` to include Road Trip Co-Pilot
- [ ] Update home screen to navigate to Road Trip Co-Pilot screen
- [ ] Use existing card design pattern
- [ ] Add appropriate icon (🚗 or Icons.directions_car)
- [ ] Update feature description
- [ ] Ensure navigation works correctly

**Story Points**: 2  
**Priority**: P1 (High)  
**Dependencies**: Story 1.5

---

### Story 4.2: Integrate with SavedTripsService
**As a** user  
**I want** to save my planned road trips  
**So that** I can access them later

**Acceptance Criteria**:
- [ ] Add "Save Route" functionality to Route Details screen
- [ ] Store RouteDetails in SavedTrip model
- [ ] Add travelType = 'road' to saved trips
- [ ] Display saved road trips in My Trips screen
- [ ] Add route-specific details to trip card
- [ ] Allow editing and deleting saved routes

**Story Points**: 3  
**Priority**: P1 (High)  
**Dependencies**: Story 1.6, Existing SavedTripsService

---

### Story 4.3: Share Route Functionality
**As a** user  
**I want** to share my planned route with others  
**So that** my travel companions know the plan

**Acceptance Criteria**:
- [ ] Add share button to Route Details screen
- [ ] Use existing ShareService
- [ ] Include route summary (origin, destination, distance, duration)
- [ ] Include toll plaza list and costs
- [ ] Include fuel station recommendations
- [ ] Include total estimated cost
- [ ] Format message for readability

**Story Points**: 3  
**Priority**: P2 (Medium)  
**Dependencies**: Story 1.6, Existing ShareService

---

### Story 4.4: Update BudgetService Integration
**As a** developer  
**I want** to ensure RoadTripService uses BudgetService correctly  
**So that** cost calculations are consistent across the app

**Acceptance Criteria**:
- [ ] Verify RoadTripService calls BudgetService.calculateFuelCost()
- [ ] Verify RoadTripService calls BudgetService.calculateTollCharges()
- [ ] Ensure round-trip multiplier (x2) is applied correctly
- [ ] Add unit tests for cost calculations
- [ ] Document integration points

**Story Points**: 2  
**Priority**: P1 (High)  
**Dependencies**: Story 1.3, Existing BudgetService

---

### Story 4.5: Error Handling & Edge Cases
**As a** developer  
**I want** to handle all error cases gracefully  
**So that** users have a smooth experience even when things go wrong

**Acceptance Criteria**:
- [ ] Handle network errors (no internet)
- [ ] Handle API failures (Google Places, Maps)
- [ ] Handle invalid input (empty origin/destination)
- [ ] Handle no route found scenarios
- [ ] Show user-friendly error messages
- [ ] Add retry mechanisms where appropriate
- [ ] Log errors for debugging
- [ ] Add offline mode with cached data

**Story Points**: 3  
**Priority**: P1 (High)  
**Dependencies**: All previous stories

---

### Story 4.6: Testing & Documentation
**As a** developer  
**I want** comprehensive tests and documentation  
**So that** the code is maintainable and reliable

**Acceptance Criteria**:
- [ ] Write unit tests for all models
- [ ] Write unit tests for all services
- [ ] Write widget tests for main screens
- [ ] Update TravelBuddyAI_Documentation.html
- [ ] Add inline code documentation
- [ ] Create API setup guide for Google Places
- [ ] Document toll plaza data sources
- [ ] Add troubleshooting guide

**Story Points**: 5  
**Priority**: P1 (High)  
**Dependencies**: All previous stories

---

## Sprint Planning Recommendation

### Sprint 1 (Week 1-2): Foundation
**Goal**: Build core data models and services

**Stories**:
- Story 1.1: Route Details Data Model (3 pts)
- Story 1.2: Waypoint Data Model (2 pts)
- Story 1.4: Vehicle Profile Data Model (3 pts)
- Story 2.1: Toll Plaza Data Model (3 pts)
- Story 3.1: Fuel Station Data Model (3 pts)
- Story 2.2: Toll Plaza Database (5 pts)

**Total**: 19 points

---

### Sprint 2 (Week 3-4): Services & Business Logic
**Goal**: Implement core services

**Stories**:
- Story 1.3: Basic RoadTripService Implementation (5 pts)
- Story 2.3: TollService Implementation (5 pts)
- Story 3.2: FuelStationService Implementation (5 pts)
- Story 4.4: Update BudgetService Integration (2 pts)

**Total**: 17 points

---

### Sprint 3 (Week 5-6): UI Development
**Goal**: Build user-facing screens

**Stories**:
- Story 1.5: Road Trip Co-Pilot Main Screen UI (5 pts)
- Story 1.6: Route Details Screen UI (8 pts)
- Story 4.1: Update Home Screen (2 pts)

**Total**: 15 points

---

### Sprint 4 (Week 7-8): Features & Integration
**Goal**: Add remaining features and integrate

**Stories**:
- Story 2.4: Display Toll Plazas on Route Details (5 pts)
- Story 3.3: Display Fuel Stations on Route Details (5 pts)
- Story 4.2: Integrate with SavedTripsService (3 pts)
- Story 4.3: Share Route Functionality (3 pts)

**Total**: 16 points

---

### Sprint 5 (Week 9-10): Polish & Testing
**Goal**: Error handling, testing, and documentation

**Stories**:
- Story 3.4: Optimal Refueling Strategy (5 pts)
- Story 4.5: Error Handling & Edge Cases (3 pts)
- Story 4.6: Testing & Documentation (5 pts)

**Total**: 13 points

---

## Definition of Done

A story is considered "Done" when:
- [ ] Code is written and follows Flutter/Dart best practices
- [ ] Code follows singleton pattern for services (as per AGENTS.md)
- [ ] All acceptance criteria are met
- [ ] Unit tests are written and passing
- [ ] Code is reviewed and approved
- [ ] Documentation is updated
- [ ] Feature is tested on Android device
- [ ] No critical bugs or issues
- [ ] Code is merged to main branch

---

## Story Point Reference

- **1 point**: < 2 hours (trivial change)
- **2 points**: 2-4 hours (simple feature)
- **3 points**: 4-8 hours (moderate feature)
- **5 points**: 1-2 days (complex feature)
- **8 points**: 2-3 days (very complex feature)
- **13 points**: 3-5 days (epic-level feature, should be broken down)

---

## Risk Assessment

### High Risk Items
1. **Google Places API costs** - Monitor usage, implement caching
2. **Toll plaza data accuracy** - Need regular updates, verify sources
3. **Route calculation performance** - Optimize for long routes

### Mitigation Strategies
1. Implement aggressive caching for API calls
2. Create manual update process for toll data
3. Add loading indicators and optimize algorithms

---

## Success Metrics

### Phase 1 MVP Success Criteria
- [ ] Users can plan a road trip in < 30 seconds
- [ ] Route cost estimates are within 10% of actual costs
- [ ] Toll plaza information is accurate for major highways
- [ ] Fuel station finder returns results within 3 seconds
- [ ] App doesn't crash on any user flow
- [ ] User satisfaction rating > 4.0/5.0

---

**Document Version**: 1.0  
**Last Updated**: 2026-06-17  
**Total Epics**: 4  
**Total Stories**: 20  
**Total Story Points**: 60  
**Estimated Duration**: 10 weeks (5 sprints)