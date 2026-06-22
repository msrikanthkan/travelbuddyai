import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Enum representing different types of routes
enum RouteType {
  fastest,
  shortest,
  scenic,
  fuelEfficient,
}

/// Enum representing different types of waypoints along a route
enum WaypointType {
  fuel,
  food,
  rest,
  attraction,
  toll,
  emergency,
}

/// Represents a waypoint or stop along a route
class Waypoint {
  final String name;
  final LatLng location;
  final Duration stopDuration;
  final WaypointType type;
  final double distanceFromOriginKm;
  final String? description;

  Waypoint({
    required this.name,
    required this.location,
    required this.stopDuration,
    required this.type,
    this.distanceFromOriginKm = 0,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'stopDuration': stopDuration.inMinutes,
        'type': type.name,
        'distanceFromOriginKm': distanceFromOriginKm,
        'description': description,
      };

  factory Waypoint.fromJson(Map<String, dynamic> json) => Waypoint(
        name: json['name'] as String,
        location: LatLng(
          (json['location']['latitude'] as num).toDouble(),
          (json['location']['longitude'] as num).toDouble(),
        ),
        stopDuration: Duration(minutes: json['stopDuration'] as int),
        type: WaypointType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => WaypointType.rest,
        ),
        distanceFromOriginKm: (json['distanceFromOriginKm'] ?? 0).toDouble(),
        description: json['description'] as String?,
      );

  /// Get emoji icon for waypoint type
  String get icon {
    switch (type) {
      case WaypointType.fuel:
        return '⛽';
      case WaypointType.food:
        return '🍽️';
      case WaypointType.rest:
        return '🛏️';
      case WaypointType.attraction:
        return '🎯';
      case WaypointType.toll:
        return '🛣️';
      case WaypointType.emergency:
        return '🆘';
    }
  }

  /// Get display name for waypoint type
  String get typeName {
    switch (type) {
      case WaypointType.fuel:
        return 'Fuel Stop';
      case WaypointType.food:
        return 'Food Stop';
      case WaypointType.rest:
        return 'Rest Stop';
      case WaypointType.attraction:
        return 'Attraction';
      case WaypointType.toll:
        return 'Toll Plaza';
      case WaypointType.emergency:
        return 'Emergency';
    }
  }
}

/// Represents detailed information about a planned route
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
  final DateTime createdAt;
  final String? vehicleId;

  RouteDetails({
    required this.routeId,
    required this.origin,
    required this.destination,
    this.waypoints = const [],
    required this.totalDistanceKm,
    required this.estimatedDuration,
    this.estimatedFuelCost = 0,
    this.estimatedTollCost = 0,
    this.type = RouteType.fastest,
    this.polylinePoints = const [],
    DateTime? createdAt,
    this.vehicleId,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate total estimated cost for the route
  double get totalEstimatedCost => estimatedFuelCost + estimatedTollCost;

  /// Get formatted distance string
  String get formattedDistance => '${totalDistanceKm.toStringAsFixed(1)} km';

  /// Get formatted duration string
  String get formattedDuration {
    final hours = estimatedDuration.inHours;
    final minutes = estimatedDuration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  /// Get formatted fuel cost string
  String get formattedFuelCost => '₹${estimatedFuelCost.toStringAsFixed(0)}';

  /// Get formatted toll cost string
  String get formattedTollCost => '₹${estimatedTollCost.toStringAsFixed(0)}';

  /// Get formatted total cost string
  String get formattedTotalCost => '₹${totalEstimatedCost.toStringAsFixed(0)}';

  /// Get route type display name
  String get routeTypeName {
    switch (type) {
      case RouteType.fastest:
        return 'Fastest Route';
      case RouteType.shortest:
        return 'Shortest Route';
      case RouteType.scenic:
        return 'Scenic Route';
      case RouteType.fuelEfficient:
        return 'Fuel Efficient Route';
    }
  }

  /// Get route type icon
  String get routeTypeIcon {
    switch (type) {
      case RouteType.fastest:
        return '⚡';
      case RouteType.shortest:
        return '📏';
      case RouteType.scenic:
        return '🌄';
      case RouteType.fuelEfficient:
        return '⛽';
    }
  }

  Map<String, dynamic> toJson() => {
        'routeId': routeId,
        'origin': origin,
        'destination': destination,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        'totalDistanceKm': totalDistanceKm,
        'estimatedDuration': estimatedDuration.inMinutes,
        'estimatedFuelCost': estimatedFuelCost,
        'estimatedTollCost': estimatedTollCost,
        'type': type.name,
        'polylinePoints': polylinePoints
            .map((p) => {
                  'latitude': p.latitude,
                  'longitude': p.longitude,
                })
            .toList(),
        'createdAt': createdAt.toIso8601String(),
        'vehicleId': vehicleId,
      };

  factory RouteDetails.fromJson(Map<String, dynamic> json) => RouteDetails(
        routeId: json['routeId'] as String,
        origin: json['origin'] as String,
        destination: json['destination'] as String,
        waypoints: (json['waypoints'] as List<dynamic>?)
                ?.map((w) => Waypoint.fromJson(w as Map<String, dynamic>))
                .toList() ??
            [],
        totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
        estimatedDuration: Duration(minutes: json['estimatedDuration'] as int),
        estimatedFuelCost: (json['estimatedFuelCost'] ?? 0).toDouble(),
        estimatedTollCost: (json['estimatedTollCost'] ?? 0).toDouble(),
        type: RouteType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => RouteType.fastest,
        ),
        polylinePoints: (json['polylinePoints'] as List<dynamic>?)
                ?.map((p) => LatLng(
                      (p['latitude'] as num).toDouble(),
                      (p['longitude'] as num).toDouble(),
                    ))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        vehicleId: json['vehicleId'] as String?,
      );

  /// Create a copy of this route with updated fields
  RouteDetails copyWith({
    String? routeId,
    String? origin,
    String? destination,
    List<Waypoint>? waypoints,
    double? totalDistanceKm,
    Duration? estimatedDuration,
    double? estimatedFuelCost,
    double? estimatedTollCost,
    RouteType? type,
    List<LatLng>? polylinePoints,
    DateTime? createdAt,
    String? vehicleId,
  }) {
    return RouteDetails(
      routeId: routeId ?? this.routeId,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      waypoints: waypoints ?? this.waypoints,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedFuelCost: estimatedFuelCost ?? this.estimatedFuelCost,
      estimatedTollCost: estimatedTollCost ?? this.estimatedTollCost,
      type: type ?? this.type,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      createdAt: createdAt ?? this.createdAt,
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }

  @override
  String toString() {
    return 'RouteDetails(origin: $origin, destination: $destination, '
        'distance: $formattedDistance, duration: $formattedDuration, '
        'cost: $formattedTotalCost)';
  }
}

// Made with Bob
