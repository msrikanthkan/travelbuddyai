class ItineraryDay {
  final int dayNumber;
  final String title;
  final List<Activity> activities;
  final List<Meal> meals;
  final Accommodation? accommodation; // Primary/selected accommodation
  final List<Accommodation> availableAccommodations; // All available hotels
  final double estimatedCost;

  ItineraryDay({
    required this.dayNumber,
    required this.title,
    required this.activities,
    required this.meals,
    this.accommodation,
    this.availableAccommodations = const [],
    required this.estimatedCost,
  });

  String get formattedCost => '₹${estimatedCost.toStringAsFixed(0)}';
}

class Activity {
  final String name;
  final String time;
  final String duration;
  final String description;
  final double cost;
  final String icon;
  final String? location;

  Activity({
    required this.name,
    required this.time,
    required this.duration,
    required this.description,
    required this.cost,
    required this.icon,
    this.location,
  });

  String get formattedCost => cost > 0 ? '₹${cost.toStringAsFixed(0)}' : 'Free';
}

class Meal {
  final String type; // breakfast, lunch, dinner
  final String name;
  final String time;
  final double cost;
  final String? restaurant;

  Meal({
    required this.type,
    required this.name,
    required this.time,
    required this.cost,
    this.restaurant,
  });

  String get formattedCost => '₹${cost.toStringAsFixed(0)}';
  
  String get icon {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🍽️';
      case 'dinner':
        return '🍴';
      default:
        return '🍕';
    }
  }
}

class Accommodation {
  final String name;
  final String type; // hotel, resort, homestay
  final double costPerNight;
  final String? address;
  final double rating;
  final String? bookingUrl;

  Accommodation({
    required this.name,
    required this.type,
    required this.costPerNight,
    this.address,
    required this.rating,
    this.bookingUrl,
  });

  String get formattedCost => '₹${costPerNight.toStringAsFixed(0)}/night';
}

// Made with Bob
