class Attraction {
  final String id;
  final String name;
  final String description;
  final String location;
  final double ticketPrice;
  final double rating;
  final List<String> images;
  final List<String> timings;
  final bool isKidFriendly;
  final String category;
  final double latitude;
  final double longitude;

  Attraction({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    this.ticketPrice = 0,
    this.rating = 0,
    this.images = const [],
    this.timings = const [],
    this.isKidFriendly = true,
    this.category = 'general',
    this.latitude = 0,
    this.longitude = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'location': location,
    'ticketPrice': ticketPrice,
    'rating': rating,
    'images': images,
    'timings': timings,
    'isKidFriendly': isKidFriendly,
    'category': category,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory Attraction.fromJson(Map<String, dynamic> json) => Attraction(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    location: json['location'],
    ticketPrice: (json['ticketPrice'] ?? 0).toDouble(),
    rating: (json['rating'] ?? 0).toDouble(),
    images: List<String>.from(json['images'] ?? []),
    timings: List<String>.from(json['timings'] ?? []),
    isKidFriendly: json['isKidFriendly'] ?? true,
    category: json['category'] ?? 'general',
    latitude: (json['latitude'] ?? 0).toDouble(),
    longitude: (json['longitude'] ?? 0).toDouble(),
  );
}
