class FoodPlace {
  final String id;
  final String name;
  final String address;
  final String location;
  final String specialty;
  final double priceRange;
  final double rating;
  final bool isFamilyFriendly;
  final String cuisine;
  final List<String> popularDishes;
  final String imageUrl;

  FoodPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.specialty,
    this.priceRange = 0,
    this.rating = 0,
    this.isFamilyFriendly = true,
    this.cuisine = 'local',
    this.popularDishes = const [],
    this.imageUrl = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'location': location,
    'specialty': specialty,
    'priceRange': priceRange,
    'rating': rating,
    'isFamilyFriendly': isFamilyFriendly,
    'cuisine': cuisine,
    'popularDishes': popularDishes,
    'imageUrl': imageUrl,
  };

  factory FoodPlace.fromJson(Map<String, dynamic> json) => FoodPlace(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    location: json['location'],
    specialty: json['specialty'],
    priceRange: (json['priceRange'] ?? 0).toDouble(),
    rating: (json['rating'] ?? 0).toDouble(),
    isFamilyFriendly: json['isFamilyFriendly'] ?? true,
    cuisine: json['cuisine'] ?? 'local',
    popularDishes: List<String>.from(json['popularDishes'] ?? []),
    imageUrl: json['imageUrl'] ?? '',
  );
}
