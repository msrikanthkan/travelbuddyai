import 'dart:developer' as developer;

import '../models/route_model.dart';
import '../models/vehicle_profile_model.dart';
import 'budget_service.dart';
import 'maps_service.dart'; // also imports RouteData

/// Service for planning road trips with route, cost, and waypoint calculations.
/// Follows singleton pattern per AGENTS.md.
class RoadTripService {
  static final RoadTripService _instance = RoadTripService._internal();
  factory RoadTripService() => _instance;
  RoadTripService._internal();

  final MapsService _mapsService = MapsService();
  final BudgetService _budgetService = BudgetService();

  /// Plan a route between origin and destination.
  /// Returns null if distance cannot be determined.
  Future<RouteDetails?> planRoute(
    String origin,
    String destination, {
    RouteType type = RouteType.fastest,
    VehicleProfile? vehicle,
  }) async {
    try {
      developer.log(
        'Planning route: $origin → $destination (${type.name})',
        name: 'RoadTripService',
      );

      // Fetch distance + actual road geometry (polyline) from OSRM
      final routeData = await _mapsService.getRouteData(origin, destination);
      if (routeData == null || routeData.distanceKm <= 0) {
        developer.log(
          'Failed to get route data for $origin → $destination',
          name: 'RoadTripService',
        );
        return null;
      }

      // Apply a route-type multiplier on the base driving distance
      final adjustedDistance = _applyRouteTypeMultiplier(routeData.distanceKm, type);

      // Use OSRM duration as base; scale it proportionally if distance was adjusted
      final distanceRatio = adjustedDistance / routeData.distanceKm;
      final duration = Duration(
        seconds: (routeData.duration.inSeconds * distanceRatio).round(),
      );

      // Fuel cost: use vehicle mileage if available, else BudgetService default
      double fuelCost;
      if (vehicle != null) {
        final fuelPricePerLiter = await _budgetService.calculateFuelCost(
          adjustedDistance,
          origin,
          vehicle.averageMileageKmpl,
        );
        fuelCost = fuelPricePerLiter;
      } else {
        fuelCost =
            await _budgetService.calculateFuelCost(adjustedDistance, origin);
      }

      // Toll cost estimate via BudgetService
      final tollCost = await _budgetService.calculateTollCharges(
        adjustedDistance,
        origin,
        destination,
      );

      final routeId = _generateRouteId(origin, destination);

      // Scale polyline points for non-fastest types (same geometry, just annotated)
      final polyline = routeData.polylinePoints;

      final route = RouteDetails(
        routeId: routeId,
        origin: origin,
        destination: destination,
        totalDistanceKm: adjustedDistance,
        estimatedDuration: duration,
        estimatedFuelCost: fuelCost,
        estimatedTollCost: tollCost,
        type: type,
        polylinePoints: polyline,
        vehicleId: vehicle?.vehicleId,
      );

      developer.log(
        'Route planned: ${route.formattedDistance}, '
        '${route.formattedDuration}, cost: ${route.formattedTotalCost}',
        name: 'RoadTripService',
      );

      return route;
    } catch (e) {
      developer.log(
        'Error planning route: $e',
        name: 'RoadTripService',
        error: e,
      );
      return null;
    }
  }

  /// Calculate fuel needed for the route based on vehicle profile
  double calculateFuelNeededLiters(
    RouteDetails route,
    VehicleProfile vehicle,
  ) {
    return route.totalDistanceKm / vehicle.averageMileageKmpl;
  }

  /// Check whether refueling stops are needed given vehicle's current tank level
  bool needsRefueling(
    RouteDetails route,
    VehicleProfile vehicle, {
    double currentFuelLevelFraction = 1.0,
  }) {
    final fuelAvailableLiters =
        vehicle.fuelTankCapacityLiters * currentFuelLevelFraction;
    final rangeKm = fuelAvailableLiters * vehicle.averageMileageKmpl;
    return rangeKm < route.totalDistanceKm;
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  double _applyRouteTypeMultiplier(double baseKm, RouteType type) {
    switch (type) {
      case RouteType.fastest:
        return baseKm; // expressway / direct route
      case RouteType.shortest:
        return baseKm * 0.95; // slightly shorter, possibly slower roads
      case RouteType.scenic:
        return baseKm * 1.15; // longer detour for scenic views
      case RouteType.fuelEfficient:
        return baseKm * 1.05; // gentle inclines / avoid steep highways
    }
  }

  String _generateRouteId(String origin, String destination) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final o = origin.replaceAll(' ', '_').toLowerCase();
    final d = destination.replaceAll(' ', '_').toLowerCase();
    return '${o}_${d}_$ts';
  }
}

// Made with Bob
