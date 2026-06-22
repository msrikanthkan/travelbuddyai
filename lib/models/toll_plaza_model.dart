import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Vehicle categories used for toll charging (matches NHAI categories)
enum TollVehicleType {
  car,
  suv,
  lcv, // Light Commercial Vehicle
  hcv, // Heavy Commercial Vehicle
  bus,
}

/// Represents a toll plaza on an Indian highway
class TollPlaza {
  final String id;
  final String name;
  final LatLng location;
  final double distanceFromOriginKm;
  final Map<TollVehicleType, double> charges;
  final bool hasFastag;
  final String operatingHours;
  final List<String> paymentMethods;
  final String highway;

  TollPlaza({
    required this.id,
    required this.name,
    required this.location,
    this.distanceFromOriginKm = 0,
    required this.charges,
    this.hasFastag = true,
    this.operatingHours = '24x7',
    this.paymentMethods = const ['FASTag', 'Cash'],
    required this.highway,
  });

  /// Get charge for a specific vehicle type
  double chargeFor(TollVehicleType vehicleType) =>
      charges[vehicleType] ?? charges[TollVehicleType.car] ?? 0;

  /// Get display label for highway e.g. "NH-48"
  String get highwayLabel => highway.toUpperCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'distanceFromOriginKm': distanceFromOriginKm,
        'charges': {
          for (final entry in charges.entries) entry.key.name: entry.value,
        },
        'hasFastag': hasFastag,
        'operatingHours': operatingHours,
        'paymentMethods': paymentMethods,
        'highway': highway,
      };

  factory TollPlaza.fromJson(Map<String, dynamic> json) => TollPlaza(
        id: json['id'] as String,
        name: json['name'] as String,
        location: LatLng(
          (json['latitude'] as num).toDouble(),
          (json['longitude'] as num).toDouble(),
        ),
        distanceFromOriginKm:
            (json['distanceFromOriginKm'] ?? 0).toDouble(),
        charges: _parseCharges(json['charges'] as Map<String, dynamic>? ?? {}),
        hasFastag: json['hasFastag'] as bool? ?? true,
        operatingHours: json['operatingHours'] as String? ?? '24x7',
        paymentMethods:
            (json['paymentMethods'] as List<dynamic>?)?.cast<String>() ??
                ['FASTag', 'Cash'],
        highway: json['highway'] as String,
      );

  static Map<TollVehicleType, double> _parseCharges(
      Map<String, dynamic> raw) {
    final result = <TollVehicleType, double>{};
    for (final entry in raw.entries) {
      final type = TollVehicleType.values.firstWhere(
        (e) => e.name == entry.key,
        orElse: () => TollVehicleType.car,
      );
      result[type] = (entry.value as num).toDouble();
    }
    return result;
  }

  @override
  String toString() =>
      'TollPlaza($name, $highwayLabel, car: ₹${chargeFor(TollVehicleType.car)})';
}

// Made with Bob
