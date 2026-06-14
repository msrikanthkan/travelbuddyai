class Destination {
  final String id;
  final String name;
  final String country;
  final String state;
  final double rating;
  final int estimatedCost;
  final String budgetRange;
  final List<String> occasionTypes;
  final String bestSeason;
  final String description;
  final String imageUrl;
  final List<String> popularActivities;

  Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.state,
    required this.rating,
    required this.estimatedCost,
    required this.budgetRange,
    required this.occasionTypes,
    required this.bestSeason,
    required this.description,
    required this.imageUrl,
    required this.popularActivities,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      state: json['state'] as String,
      rating: (json['rating'] as num).toDouble(),
      estimatedCost: json['estimated_cost'] as int,
      budgetRange: json['budget_range'] as String,
      occasionTypes: List<String>.from(json['occasion_types'] as List),
      bestSeason: json['best_season'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      popularActivities: List<String>.from(json['popular_activities'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'state': state,
      'rating': rating,
      'estimated_cost': estimatedCost,
      'budget_range': budgetRange,
      'occasion_types': occasionTypes,
      'best_season': bestSeason,
      'description': description,
      'image_url': imageUrl,
      'popular_activities': popularActivities,
    };
  }

  String get formattedCost => '₹${estimatedCost.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}

// Made with Bob
