enum RestStopType {
  petrolPump,
  restaurant,
  restroom,
  parking,
  medicalStore,
  hospital,
}

class RestStop {
  final String id;
  final String name;
  final String address;
  final RestStopType type;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final String rating;
  final List<String> facilities;

  RestStop({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    this.distanceKm = 0,
    this.latitude = 0,
    this.longitude = 0,
    this.isOpen = true,
    this.rating = '0',
    this.facilities = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'type': type.name,
        'distanceKm': distanceKm,
        'latitude': latitude,
        'longitude': longitude,
        'isOpen': isOpen,
        'rating': rating,
        'facilities': facilities,
      };

  factory RestStop.fromJson(Map<String, dynamic> json) => RestStop(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        type: RestStopType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => RestStopType.restaurant,
        ),
        distanceKm: (json['distanceKm'] ?? 0).toDouble(),
        latitude: (json['latitude'] ?? 0).toDouble(),
        longitude: (json['longitude'] ?? 0).toDouble(),
        isOpen: json['isOpen'] ?? true,
        rating: json['rating'] ?? '0',
        facilities: List<String>.from(json['facilities'] ?? []),
      );
}
