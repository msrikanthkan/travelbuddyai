class TaxiFare {
  final String id;
  final String pickupLocation;
  final String dropoffLocation;
  final double estimatedFare;
  final double minFare;
  final double maxFare;
  final String vehicleType;
  final double distanceKm;
  final bool isAutoRickshaw;

  TaxiFare({
    required this.id,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.estimatedFare,
    this.minFare = 0,
    this.maxFare = 0,
    this.vehicleType = 'sedan',
    this.distanceKm = 0,
    this.isAutoRickshaw = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pickupLocation': pickupLocation,
    'dropoffLocation': dropoffLocation,
    'estimatedFare': estimatedFare,
    'minFare': minFare,
    'maxFare': maxFare,
    'vehicleType': vehicleType,
    'distanceKm': distanceKm,
    'isAutoRickshaw': isAutoRickshaw,
  };

  factory TaxiFare.fromJson(Map<String, dynamic> json) => TaxiFare(
    id: json['id'],
    pickupLocation: json['pickupLocation'],
    dropoffLocation: json['dropoffLocation'],
    estimatedFare: (json['estimatedFare'] ?? 0).toDouble(),
    minFare: (json['minFare'] ?? 0).toDouble(),
    maxFare: (json['maxFare'] ?? 0).toDouble(),
    vehicleType: json['vehicleType'] ?? 'sedan',
    distanceKm: (json['distanceKm'] ?? 0).toDouble(),
    isAutoRickshaw: json['isAutoRickshaw'] ?? false,
  );
}
