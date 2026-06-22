/// Enum representing types of vehicles
enum VehicleType {
  car,
  suv,
  sedan,
  hatchback,
}

/// Represents a user's vehicle profile for accurate fuel cost estimation
class VehicleProfile {
  final String vehicleId;
  final String make;
  final String model;
  final int year;
  final VehicleType type;
  final double fuelTankCapacityLiters;
  final double averageMileageKmpl;

  VehicleProfile({
    required this.vehicleId,
    required this.make,
    required this.model,
    required this.year,
    required this.type,
    required this.fuelTankCapacityLiters,
    required this.averageMileageKmpl,
  });

  /// Maximum range on a full tank
  double get maxRangeKm => fuelTankCapacityLiters * averageMileageKmpl;

  /// Get display name for vehicle type
  String get typeName {
    switch (type) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.suv:
        return 'SUV';
      case VehicleType.sedan:
        return 'Sedan';
      case VehicleType.hatchback:
        return 'Hatchback';
    }
  }

  /// Get vehicle label e.g. "Maruti Swift (2022)"
  String get displayName => '$make $model ($year)';

  Map<String, dynamic> toJson() => {
        'vehicleId': vehicleId,
        'make': make,
        'model': model,
        'year': year,
        'type': type.name,
        'fuelTankCapacityLiters': fuelTankCapacityLiters,
        'averageMileageKmpl': averageMileageKmpl,
      };

  factory VehicleProfile.fromJson(Map<String, dynamic> json) => VehicleProfile(
        vehicleId: json['vehicleId'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        type: VehicleType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => VehicleType.car,
        ),
        fuelTankCapacityLiters:
            (json['fuelTankCapacityLiters'] as num).toDouble(),
        averageMileageKmpl: (json['averageMileageKmpl'] as num).toDouble(),
      );

  VehicleProfile copyWith({
    String? vehicleId,
    String? make,
    String? model,
    int? year,
    VehicleType? type,
    double? fuelTankCapacityLiters,
    double? averageMileageKmpl,
  }) {
    return VehicleProfile(
      vehicleId: vehicleId ?? this.vehicleId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      type: type ?? this.type,
      fuelTankCapacityLiters:
          fuelTankCapacityLiters ?? this.fuelTankCapacityLiters,
      averageMileageKmpl: averageMileageKmpl ?? this.averageMileageKmpl,
    );
  }

  /// Default vehicle profile for first-time users (Maruti Swift, 22 kmpl)
  static VehicleProfile get defaultProfile => VehicleProfile(
        vehicleId: 'default',
        make: 'Maruti',
        model: 'Swift',
        year: 2022,
        type: VehicleType.hatchback,
        fuelTankCapacityLiters: 37,
        averageMileageKmpl: 22,
      );

  @override
  String toString() =>
      'VehicleProfile($displayName, ${averageMileageKmpl}kmpl, ${fuelTankCapacityLiters}L)';
}

// Made with Bob
