import '../models/itinerary_day_model.dart';
import 'hotel_service.dart';

class ItineraryGeneratorService {
  static final HotelService _hotelService = HotelService();
  
  /// Generate a complete itinerary based on trip details
  static Future<List<ItineraryDay>> generateItinerary({
    required String destination,
    required String occasion,
    required int tripDays,
    required int budget,
    required int totalTravelers,
  }) async {
    final List<ItineraryDay> itinerary = [];
    final dailyBudget = budget / tripDays;
    final accommodationBudget = dailyBudget * 0.4; // 40% of daily budget
    
    // Fetch more hotels to show all available options (up to 20)
    final hotels = await _hotelService.searchHotels(
      destination: destination,
      maxBudget: accommodationBudget,
      limit: 20, // Fetch more hotels for user to choose from
    );
    
    for (int day = 1; day <= tripDays; day++) {
      // Use different hotel for each day if available, otherwise reuse
      final hotelIndex = (day - 1) % hotels.length;
      final primaryHotel = hotels.isNotEmpty ? hotels[hotelIndex] : null;
      
      itinerary.add(_generateDay(
        dayNumber: day,
        destination: destination,
        occasion: occasion,
        dailyBudget: dailyBudget,
        totalDays: tripDays,
        accommodation: primaryHotel,
        availableAccommodations: hotels, // Pass all hotels
      ));
    }
    
    return itinerary;
  }

  static ItineraryDay _generateDay({
    required int dayNumber,
    required String destination,
    required String occasion,
    required double dailyBudget,
    required int totalDays,
    required Accommodation? accommodation,
    required List<Accommodation> availableAccommodations,
  }) {
    // Determine day type
    final isFirstDay = dayNumber == 1;
    final isLastDay = dayNumber == totalDays;
    
    String title;
    if (isFirstDay) {
      title = 'Arrival & Exploration';
    } else if (isLastDay) {
      title = 'Final Day & Departure';
    } else {
      title = _getDayTitle(dayNumber, destination, occasion);
    }

    // Generate activities based on occasion and day
    final activities = _generateActivities(
      dayNumber: dayNumber,
      destination: destination,
      occasion: occasion,
      isFirstDay: isFirstDay,
      isLastDay: isLastDay,
    );

    // Generate meals
    final meals = _generateMeals(destination, dailyBudget);

    // Use provided accommodation (except last day)
    final dayAccommodation = !isLastDay ? accommodation : null;

    // Calculate estimated cost
    final activityCost = activities.fold<double>(0, (sum, activity) => sum + activity.cost);
    final mealCost = meals.fold<double>(0, (sum, meal) => sum + meal.cost);
    final accommodationCost = dayAccommodation?.costPerNight ?? 0;
    final estimatedCost = activityCost + mealCost + accommodationCost;

    return ItineraryDay(
      dayNumber: dayNumber,
      title: title,
      activities: activities,
      meals: meals,
      accommodation: dayAccommodation,
      availableAccommodations: availableAccommodations,
      estimatedCost: estimatedCost,
    );
  }

  static String _getDayTitle(int day, String destination, String occasion) {
    final titles = {
      'casual': [
        'Beach & Relaxation',
        'Local Markets & Shopping',
        'Adventure Activities',
        'Cultural Exploration',
        'Nature & Sightseeing',
      ],
      'adventure': [
        'Trekking & Hiking',
        'Water Sports',
        'Mountain Exploration',
        'Wildlife Safari',
        'Extreme Activities',
      ],
      'cultural': [
        'Historical Sites',
        'Museums & Art',
        'Local Traditions',
        'Heritage Walk',
        'Cultural Shows',
      ],
      'devotional': [
        'Temple Visits',
        'Spiritual Rituals',
        'Meditation & Yoga',
        'Sacred Sites',
        'Religious Ceremonies',
      ],
      'wedding': [
        'Pre-Wedding Celebrations',
        'Wedding Ceremony',
        'Reception & Party',
        'Post-Wedding Rituals',
        'Relaxation Day',
      ],
      'honeymoon': [
        'Romantic Dinner',
        'Couple Activities',
        'Spa & Wellness',
        'Scenic Views',
        'Private Beach Time',
      ],
    };

    final occasionTitles = titles[occasion] ?? titles['casual']!;
    return occasionTitles[(day - 2) % occasionTitles.length];
  }

  static List<Activity> _generateActivities({
    required int dayNumber,
    required String destination,
    required String occasion,
    required bool isFirstDay,
    required bool isLastDay,
  }) {
    if (isFirstDay) {
      return [
        Activity(
          name: 'Hotel Check-in',
          time: '12:00 PM',
          duration: '1 hour',
          description: 'Arrive at hotel, complete check-in formalities, and freshen up',
          cost: 0,
          icon: '🏨',
          location: destination,
        ),
        Activity(
          name: 'Local Area Exploration',
          time: '2:00 PM',
          duration: '2 hours',
          description: 'Walk around the neighborhood, get familiar with nearby shops and restaurants',
          cost: 0,
          icon: '🚶',
          location: destination,
        ),
        Activity(
          name: 'Welcome Dinner',
          time: '7:00 PM',
          duration: '2 hours',
          description: 'Enjoy local cuisine at a popular restaurant',
          cost: 800,
          icon: '🍽️',
          location: destination,
        ),
      ];
    }

    if (isLastDay) {
      return [
        Activity(
          name: 'Hotel Check-out',
          time: '10:00 AM',
          duration: '1 hour',
          description: 'Complete check-out formalities and prepare for departure',
          cost: 0,
          icon: '🏨',
          location: destination,
        ),
        Activity(
          name: 'Last-minute Shopping',
          time: '11:00 AM',
          duration: '2 hours',
          description: 'Buy souvenirs and local specialties',
          cost: 500,
          icon: '🛍️',
          location: destination,
        ),
        Activity(
          name: 'Departure',
          time: '2:00 PM',
          duration: '1 hour',
          description: 'Head to airport/station for return journey',
          cost: 0,
          icon: '✈️',
          location: destination,
        ),
      ];
    }

    // Regular day activities based on occasion
    return _getOccasionActivities(destination, occasion, dayNumber);
  }

  static List<Activity> _getOccasionActivities(String destination, String occasion, int day) {
    final activities = {
      'casual': [
        Activity(
          name: 'Beach Visit',
          time: '9:00 AM',
          duration: '3 hours',
          description: 'Relax on the beach, swim, and enjoy water activities',
          cost: 500,
          icon: '🏖️',
          location: destination,
        ),
        Activity(
          name: 'Local Market Tour',
          time: '2:00 PM',
          duration: '2 hours',
          description: 'Explore local markets, shop for handicrafts and souvenirs',
          cost: 1000,
          icon: '🛍️',
          location: destination,
        ),
        Activity(
          name: 'Sunset Point Visit',
          time: '5:30 PM',
          duration: '1.5 hours',
          description: 'Watch beautiful sunset at popular viewpoint',
          cost: 200,
          icon: '🌅',
          location: destination,
        ),
      ],
      'adventure': [
        Activity(
          name: 'Trekking Expedition',
          time: '6:00 AM',
          duration: '5 hours',
          description: 'Guided trek through scenic trails with experienced guide',
          cost: 2000,
          icon: '🥾',
          location: destination,
        ),
        Activity(
          name: 'Water Sports',
          time: '2:00 PM',
          duration: '3 hours',
          description: 'Parasailing, jet skiing, and banana boat rides',
          cost: 3000,
          icon: '🏄',
          location: destination,
        ),
        Activity(
          name: 'Campfire & BBQ',
          time: '7:00 PM',
          duration: '2 hours',
          description: 'Evening campfire with BBQ dinner',
          cost: 1500,
          icon: '🔥',
          location: destination,
        ),
      ],
      'cultural': [
        Activity(
          name: 'Museum Visit',
          time: '10:00 AM',
          duration: '2 hours',
          description: 'Explore local history and art at the museum',
          cost: 300,
          icon: '🏛️',
          location: destination,
        ),
        Activity(
          name: 'Heritage Walk',
          time: '3:00 PM',
          duration: '3 hours',
          description: 'Guided tour of historical monuments and heritage sites',
          cost: 800,
          icon: '🚶',
          location: destination,
        ),
        Activity(
          name: 'Cultural Show',
          time: '7:00 PM',
          duration: '2 hours',
          description: 'Traditional dance and music performance',
          cost: 1000,
          icon: '🎭',
          location: destination,
        ),
      ],
      'devotional': [
        Activity(
          name: 'Temple Visit',
          time: '6:00 AM',
          duration: '2 hours',
          description: 'Morning prayers and darshan at main temple',
          cost: 200,
          icon: '🛕',
          location: destination,
        ),
        Activity(
          name: 'Spiritual Discourse',
          time: '10:00 AM',
          duration: '2 hours',
          description: 'Attend spiritual talk and meditation session',
          cost: 0,
          icon: '🧘',
          location: destination,
        ),
        Activity(
          name: 'Evening Aarti',
          time: '6:00 PM',
          duration: '1 hour',
          description: 'Participate in evening prayer ceremony',
          cost: 100,
          icon: '🪔',
          location: destination,
        ),
      ],
    };

    return activities[occasion] ?? activities['casual']!;
  }

  static List<Meal> _generateMeals(String destination, double dailyBudget) {
    final mealBudget = dailyBudget * 0.3; // 30% of daily budget for meals
    
    return [
      Meal(
        type: 'breakfast',
        name: 'Continental Breakfast',
        time: '8:00 AM',
        cost: mealBudget * 0.25,
        restaurant: 'Hotel Restaurant',
      ),
      Meal(
        type: 'lunch',
        name: 'Local Cuisine',
        time: '1:00 PM',
        cost: mealBudget * 0.35,
        restaurant: 'Popular Local Restaurant',
      ),
      Meal(
        type: 'dinner',
        name: 'Multi-cuisine Dinner',
        time: '8:00 PM',
        cost: mealBudget * 0.40,
        restaurant: 'Fine Dining Restaurant',
      ),
    ];
  }

}

// Made with Bob
