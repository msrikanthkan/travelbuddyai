class Hotel {
  final String id;
  final String name;
  final String address;
  final String location;
  final double pricePerNight;
  final double rating;
  final List<String> amenities;
  final bool isFamilyFriendly;
  final bool isPetFriendly;
  final String imageUrl;
  final String category;

  Hotel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.pricePerNight,
    this.rating = 0,
    this.amenities = const [],
    this.isFamilyFriendly = true,
    this.isPetFriendly = false,
    this.imageUrl = '',
    this.category = 'standard',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'location': location,
    'pricePerNight': pricePerNight,
    'rating': rating,
    'amenities': amenities,
    'isFamilyFriendly': isFamilyFriendly,
    'isPetFriendly': isPetFriendly,
    'imageUrl': imageUrl,
    'category': category,
  };

  factory Hotel.fromJson(Map<String, dynamic> json) => Hotel(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    location: json['location'],
    pricePerNight: (json['pricePerNight'] ?? 0).toDouble(),
    rating: (json['rating'] ?? 0).toDouble(),
    amenities: List<String>.from(json['amenities'] ?? []),
    isFamilyFriendly: json['isFamilyFriendly'] ?? true,
    isPetFriendly: json['isPetFriendly'] ?? false,
    imageUrl: json['imageUrl'] ?? '',
    category: json['category'] ?? 'standard',
  );
}
