import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Fuel prices for different fuel types at a station
class FuelPrices {
  final double petrol;
  final double diesel;
  final DateTime lastUpdated;

  FuelPrices({
    required this.petrol,
    required this.diesel,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'petrol': petrol,
        'diesel': diesel,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory FuelPrices.fromJson(Map<String, dynamic> json) => FuelPrices(
        petrol: (json['petrol'] as num).toDouble(),
        diesel: (json['diesel'] as num).toDouble(),
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'] as String)
            : DateTime.now(),
      );
}

/// Represents a fuel station along a route
class FuelStation {
  final String id;
  final String name;
  final String brand;
  final LatLng location;
  final double distanceFromRouteKm;
  final double distanceFromCurrentKm;
  final FuelPrices prices;
  final List<String> amenities;
  final double rating;
  final bool isOpen24x7;
  final String? contactNumber;

  FuelStation({
    required this.id,
    required this.name,
    required this.brand,
    required this.location,
    this.distanceFromRouteKm = 0,
    this.distanceFromCurrentKm = 0,
    required this.prices,
    this.amenities = const [],
    this.rating = 0,
    this.isOpen24x7 = true,
    this.contactNumber,
  });

  /// Get brand icon emoji
  String get brandIcon => '⛽';

  /// Formatted petrol price
  String get formattedPetrol => '₹${prices.petrol.toStringAsFixed(1)}/L';

  /// Formatted diesel price
  String get formattedDiesel => '₹${prices.diesel.toStringAsFixed(1)}/L';

  /// Formatted distance from route
  String get formattedDistance =>
      distanceFromRouteKm < 1
          ? '${(distanceFromRouteKm * 1000).toStringAsFixed(0)}m off route'
          : '${distanceFromRouteKm.toStringAsFixed(1)}km off route';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'distanceFromRouteKm': distanceFromRouteKm,
        'distanceFromCurrentKm': distanceFromCurrentKm,
        'prices': prices.toJson(),
        'amenities': amenities,
        'rating': rating,
        'isOpen24x7': isOpen24x7,
        'contactNumber': contactNumber,
      };

  factory FuelStation.fromJson(Map<String, dynamic> json) => FuelStation(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String,
        location: LatLng(
          (json['latitude'] as num).toDouble(),
          (json['longitude'] as num).toDouble(),
        ),
        distanceFromRouteKm:
            (json['distanceFromRouteKm'] ?? 0).toDouble(),
        distanceFromCurrentKm:
            (json['distanceFromCurrentKm'] ?? 0).toDouble(),
        prices: FuelPrices.fromJson(
            json['prices'] as Map<String, dynamic>),
        amenities:
            (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [],
        rating: (json['rating'] ?? 0).toDouble(),
        isOpen24x7: json['isOpen24x7'] as bool? ?? true,
        contactNumber: json['contactNumber'] as String?,
      );

  @override
  String toString() =>
      'FuelStation($name, $brand, petrol: $formattedPetrol)';
}

// Made with Bob
