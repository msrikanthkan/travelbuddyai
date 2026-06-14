import 'dart:convert';
import 'package:http/http.dart' as http;
import 'openweather_service.dart';
import 'firebase_destinations_service.dart';

class TrendingDestinationsService {
  final http.Client _client;
  final OpenWeatherService _weatherService;
  final FirebaseDestinationsService _firebaseDestinations;

  TrendingDestinationsService([
    http.Client? client,
    OpenWeatherService? weatherService,
    FirebaseDestinationsService? firebaseDestinations,
  ])  : _client = client ?? http.Client(),
        _weatherService = weatherService ?? OpenWeatherService(),
        _firebaseDestinations = firebaseDestinations ?? FirebaseDestinationsService();

  /// Get trending destinations with insights based on occasion type (with real-time weather)
  Future<List<Map<String, dynamic>>> getTrendingDestinations({
    required String occasionType,
    required double budget,
    required int duration,
    String? userDestination,
  }) async {
    print('\n🌍 ========== Trending Destinations Service ==========');
    print('🎯 Occasion: $occasionType | Budget: ₹$budget | Duration: $duration days');
    // Determine budget category
    String budgetCategory;
    if (budget < 10000) {
      budgetCategory = 'budget';
    } else if (budget < 50000) {
      budgetCategory = 'mid-range';
    } else {
      budgetCategory = 'luxury';
    }

    // Determine duration category
    String durationCategory;
    if (duration < 3) {
      durationCategory = 'short';
    } else if (duration <= 7) {
      durationCategory = 'medium';
    } else {
      durationCategory = 'long';
    }

    // If user has a specific destination, return it with trending info
    if (userDestination != null && userDestination.isNotEmpty) {
      final destinations = await _getDestinationTrends(userDestination, occasionType, budgetCategory);
      return await _enrichWithWeatherData(destinations);
    }

    // Otherwise, return trending destinations for the occasion
    final destinations = await _getTrendingByOccasion(
      occasionType,
      budgetCategory,
      durationCategory
    );
    
    // Enrich with real-time weather data
    return await _enrichWithWeatherData(destinations);
  }

  /// Get trending info for a specific destination
  Future<List<Map<String, dynamic>>> _getDestinationTrends(
    String destination,
    String occasionType,
    String budgetCategory,
  ) async {
    // Return the user's destination with relevant info
    return [
      {
        'name': destination,
        'country': 'India', // Default to India
        'description': _getOccasionDescription(destination, occasionType),
        'bestFor': occasionType,
        'budgetCategory': budgetCategory,
        'rating': 4.5,
        'isUserChoice': true,
      }
    ];
  }

  /// Get trending destinations by occasion type (from Firebase)
  Future<List<Map<String, dynamic>>> _getTrendingByOccasion(
    String occasionType,
    String budgetCategory,
    String durationCategory,
  ) async {
    print('🔥 Fetching destinations from Firebase for: $occasionType');
    
    // Get destinations from Firebase Remote Config
    final destinations = await _firebaseDestinations.getDestinations(occasionType);
    
    // Score destinations based on budget and duration match
    final scored = destinations.map((dest) {
      int score = 0;
      
      // Budget matching (more flexible)
      if (dest['budgetCategory'] == budgetCategory || dest['budgetCategory'] == 'all') {
        score += 10; // Exact match
      } else if (budgetCategory == 'mid-range') {
        // Mid-range can consider budget and luxury options
        score += 5;
      } else if (budgetCategory == 'budget' && dest['budgetCategory'] == 'mid-range') {
        score += 3; // Budget users can see mid-range as aspirational
      } else if (budgetCategory == 'luxury' && dest['budgetCategory'] == 'mid-range') {
        score += 3; // Luxury users can see mid-range as alternatives
      }
      
      // Duration matching (flexible)
      if (dest['durationCategory'] == durationCategory || dest['durationCategory'] == 'all') {
        score += 5; // Exact match
      } else {
        score += 2; // Still show, just lower priority
      }
      
      return {...dest, '_score': score};
    }).toList();
    
    // Sort by score (descending) and return top 5
    scored.sort((a, b) => (b['_score'] as int).compareTo(a['_score'] as int));
    
    print('✅ Returning ${scored.take(5).length} destinations');
    return scored.take(5).toList();
  }

  List<Map<String, dynamic>> _getDestinationsByOccasion(String occasionType) {
    switch (occasionType) {
      case 'wedding':
        return [
          {
            'name': 'Udaipur',
            'country': 'India',
            'description': 'City of Lakes - Perfect for royal destination weddings',
            'bestFor': 'wedding',
            'budgetCategory': 'luxury',
            'durationCategory': 'medium',
            'rating': 4.8,
            'highlights': ['Lake Palace', 'City Palace', 'Royal venues'],
            'insights': {
              'trendScore': 95,
              'popularityRank': 1,
              'avgVisitors': '50,000+ weddings/year',
              'peakSeason': 'October - March',
              'avgCost': '₹15-50 lakhs',
              'bestTime': 'November - February',
              'crowdLevel': 'High',
              'weatherRating': 4.8,
              'trendingReason': 'Royal palaces and lake venues make it #1 wedding destination',
              'recentTrend': '+35% bookings in 2024',
              'topVenues': ['Taj Lake Palace', 'Oberoi Udaivilas', 'Leela Palace'],
              'uniqueFeature': 'Boat processions on Lake Pichola',
            },
          },
          {
            'name': 'Jaipur',
            'country': 'India',
            'description': 'Pink City - Heritage palaces and forts for grand weddings',
            'bestFor': 'wedding',
            'budgetCategory': 'mid-range',
            'durationCategory': 'medium',
            'rating': 4.7,
            'highlights': ['Amber Fort', 'City Palace', 'Heritage hotels'],
            'insights': {
              'trendScore': 88,
              'popularityRank': 2,
              'avgVisitors': '40,000+ weddings/year',
              'peakSeason': 'October - March',
              'avgCost': '₹8-25 lakhs',
              'bestTime': 'November - February',
              'crowdLevel': 'Medium-High',
              'weatherRating': 4.6,
              'trendingReason': 'Royal Rajasthani heritage venues at affordable prices',
              'recentTrend': '+28% bookings in 2024',
              'topVenues': ['Samode Palace', 'Rambagh Palace', 'Fairmont Jaipur'],
              'uniqueFeature': 'Elephant processions and folk performances',
            },
          },
          {
            'name': 'Goa',
            'country': 'India',
            'description': 'Beach weddings with Portuguese charm',
            'bestFor': 'wedding',
            'budgetCategory': 'mid-range',
            'durationCategory': 'medium',
            'rating': 4.6,
            'highlights': ['Beach venues', 'Churches', 'Resorts'],
            'insights': {
              'trendScore': 85,
              'popularityRank': 3,
              'avgVisitors': '35,000+ weddings/year',
              'peakSeason': 'November - February',
              'avgCost': '₹5-20 lakhs',
              'bestTime': 'December - January',
              'crowdLevel': 'High',
              'weatherRating': 4.7,
              'trendingReason': 'Beach weddings with vibrant nightlife',
              'recentTrend': '+22% bookings in 2024',
              'topVenues': ['Taj Exotica', 'Park Hyatt', 'Alila Diwa'],
              'uniqueFeature': 'Sunset beach ceremonies',
            },
          },
          {
            'name': 'Bali',
            'country': 'Indonesia',
            'description': 'Tropical paradise for intimate destination weddings',
            'bestFor': 'wedding',
            'budgetCategory': 'luxury',
            'durationCategory': 'long',
            'rating': 4.9,
            'highlights': ['Beach resorts', 'Temples', 'Villas'],
            'insights': {
              'trendScore': 92,
              'popularityRank': 1,
              'avgVisitors': '15,000+ Indian weddings/year',
              'peakSeason': 'April - October',
              'avgCost': '₹20-60 lakhs',
              'bestTime': 'May - September',
              'crowdLevel': 'Medium',
              'weatherRating': 4.8,
              'trendingReason': 'Exotic international destination with stunning venues',
              'recentTrend': '+45% bookings from India in 2024',
              'topVenues': ['Ayana Resort', 'The Mulia', 'Bulgari Resort'],
              'uniqueFeature': 'Clifftop ocean-view ceremonies',
            },
          },
          {
            'name': 'Jim Corbett',
            'country': 'India',
            'description': 'Wildlife resort weddings in nature',
            'bestFor': 'wedding',
            'budgetCategory': 'mid-range',
            'durationCategory': 'short',
            'rating': 4.5,
            'highlights': ['Resorts', 'Nature', 'Wildlife'],
            'insights': {
              'trendScore': 75,
              'popularityRank': 5,
              'avgVisitors': '8,000+ weddings/year',
              'peakSeason': 'November - March',
              'avgCost': '₹6-18 lakhs',
              'bestTime': 'November - February',
              'crowdLevel': 'Low-Medium',
              'weatherRating': 4.5,
              'trendingReason': 'Unique wildlife resort weddings',
              'recentTrend': '+18% bookings in 2024',
              'topVenues': ['The Solluna Resort', 'Aahana Resort', 'Jim\'s Jungle Retreat'],
              'uniqueFeature': 'Safari experiences for guests',
            },
          },
        ];

      case 'devotional':
        return [
          {
            'name': 'Tirupati',
            'country': 'India',
            'description': 'Lord Venkateswara Temple - Most visited pilgrimage site',
            'bestFor': 'devotional',
            'budgetCategory': 'budget',
            'durationCategory': 'short',
            'rating': 4.9,
            'highlights': ['Tirumala Temple', 'Sri Padmavathi Temple'],
            'insights': {
              'trendScore': 98,
              'popularityRank': 1,
              'avgVisitors': '75,000+ pilgrims/day',
              'peakSeason': 'Year-round (peak: festivals)',
              'avgCost': '₹3,000-8,000',
              'bestTime': 'September - February',
              'crowdLevel': 'Very High',
              'weatherRating': 4.5,
              'trendingReason': 'World\'s most visited religious site',
              'recentTrend': '50+ million visitors annually',
              'topAttractions': ['Tirumala Temple', 'Padmavathi Temple', 'Kapila Theertham'],
              'uniqueFeature': 'Free food (Annadanam) for all pilgrims',
            },
          },
          {
            'name': 'Varanasi',
            'country': 'India',
            'description': 'Spiritual capital on the banks of Ganges',
            'bestFor': 'devotional',
            'budgetCategory': 'budget',
            'durationCategory': 'short',
            'rating': 4.8,
            'highlights': ['Kashi Vishwanath', 'Ganga Aarti', 'Ghats'],
            'insights': {
              'trendScore': 96,
              'popularityRank': 2,
              'avgVisitors': '3 million+ pilgrims/year',
              'peakSeason': 'October - March',
              'avgCost': '₹4,000-10,000',
              'bestTime': 'November - February',
              'crowdLevel': 'Very High',
              'weatherRating': 4.3,
              'trendingReason': 'Oldest living city and holiest Hindu site',
              'recentTrend': '+15% spiritual tourism in 2024',
              'topAttractions': ['Kashi Vishwanath', 'Dashashwamedh Ghat', 'Sarnath'],
              'uniqueFeature': 'Evening Ganga Aarti ceremony',
            },
          },
          {
            'name': 'Shirdi',
            'country': 'India',
            'description': 'Home of Sai Baba - Popular pilgrimage destination',
            'bestFor': 'devotional',
            'budgetCategory': 'budget',
            'durationCategory': 'short',
            'rating': 4.7,
            'highlights': ['Sai Baba Temple', 'Dwarkamai', 'Chavadi'],
            'insights': {
              'trendScore': 90,
              'popularityRank': 3,
              'avgVisitors': '25,000+ pilgrims/day',
              'peakSeason': 'Year-round',
              'avgCost': '₹3,000-7,000',
              'bestTime': 'October - March',
              'crowdLevel': 'High',
              'weatherRating': 4.4,
              'trendingReason': 'Universal appeal across religions',
              'recentTrend': '20+ million visitors annually',
              'topAttractions': ['Sai Baba Temple', 'Dwarkamai', 'Chavadi'],
              'uniqueFeature': 'Free accommodation and meals',
            },
          },
          {
            'name': 'Amritsar',
            'country': 'India',
            'description': 'Golden Temple - Sikh spiritual center',
            'bestFor': 'devotional',
            'budgetCategory': 'budget',
            'durationCategory': 'short',
            'rating': 4.9,
            'highlights': ['Golden Temple', 'Jallianwala Bagh', 'Wagah Border'],
            'insights': {
              'trendScore': 94,
              'popularityRank': 2,
              'avgVisitors': '100,000+ visitors/day',
              'peakSeason': 'October - March',
              'avgCost': '₹4,000-9,000',
              'bestTime': 'November - February',
              'crowdLevel': 'Very High',
              'weatherRating': 4.2,
              'trendingReason': 'Most beautiful temple with free langar',
              'recentTrend': '30+ million visitors annually',
              'topAttractions': ['Golden Temple', 'Jallianwala Bagh', 'Wagah Border'],
              'uniqueFeature': 'World\'s largest free kitchen (langar)',
            },
          },
          {
            'name': 'Haridwar',
            'country': 'India',
            'description': 'Gateway to the Gods on the Ganges',
            'bestFor': 'devotional',
            'budgetCategory': 'budget',
            'durationCategory': 'short',
            'rating': 4.6,
            'highlights': ['Har Ki Pauri', 'Ganga Aarti', 'Temples'],
            'insights': {
              'trendScore': 85,
              'popularityRank': 4,
              'avgVisitors': '2 million+ pilgrims/year',
              'peakSeason': 'March - April (Kumbh)',
              'avgCost': '₹3,500-8,000',
              'bestTime': 'October - February',
              'crowdLevel': 'High',
              'weatherRating': 4.4,
              'trendingReason': 'Gateway to Char Dham Yatra',
              'recentTrend': 'Kumbh Mela attracts millions',
              'topAttractions': ['Har Ki Pauri', 'Mansa Devi', 'Chandi Devi'],
              'uniqueFeature': 'Evening Ganga Aarti at Har Ki Pauri',
            },
          },
        ];

      case 'adventure':
        return [
          {
            'name': 'Manali',
            'country': 'India',
            'description': 'Himalayan adventure hub - Trekking, skiing, rafting',
            'bestFor': 'adventure',
            'budgetCategory': 'mid-range',
            'durationCategory': 'medium',
            'rating': 4.7,
            'highlights': ['Rohtang Pass', 'Solang Valley', 'Trekking'],
            'insights': {
              'trendScore': 92,
              'popularityRank': 1,
              'avgVisitors': '2 million+ tourists/year',
              'peakSeason': 'May-June, Dec-Feb',
              'avgCost': '₹15,000-35,000',
              'bestTime': 'May-June (summer), Dec-Feb (snow)',
              'crowdLevel': 'High',
              'weatherRating': 4.6,
              'trendingReason': '#1 adventure destination',
              'recentTrend': '+40% adventure bookings',
              'topActivities': ['Paragliding', 'Skiing', 'Rafting', 'Trekking'],
              'uniqueFeature': 'Year-round adventure activities',
            },
          },
          {
            'name': 'Rishikesh',
            'country': 'India',
            'description': 'Yoga capital and adventure sports destination',
            'bestFor': 'adventure',
            'budgetCategory': 'budget',
            'durationCategory': 'short',
            'rating': 4.8,
            'highlights': ['River rafting', 'Bungee jumping', 'Camping'],
            'insights': {
              'trendScore': 90,
              'popularityRank': 2,
              'avgVisitors': '1.5 million+ tourists/year',
              'peakSeason': 'Sep-Nov, Mar-May',
              'avgCost': '₹8,000-20,000',
              'bestTime': 'September-November',
              'crowdLevel': 'Medium-High',
              'weatherRating': 4.7,
              'trendingReason': 'Best white water rafting',
              'recentTrend': '+35% adventure tourism',
              'topActivities': ['Rafting', 'Bungee', 'Flying fox', 'Camping'],
              'uniqueFeature': 'India\'s highest bungee (83m)',
            },
          },
          {
            'name': 'Leh-Ladakh',
            'country': 'India',
            'description': 'High altitude desert adventure',
            'bestFor': 'adventure',
            'budgetCategory': 'mid-range',
            'durationCategory': 'long',
            'rating': 4.9,
            'highlights': ['Pangong Lake', 'Nubra Valley', 'Bike trips'],
            'insights': {
              'trendScore': 95,
              'popularityRank': 1,
              'avgVisitors': '300,000+ tourists/year',
              'peakSeason': 'June-September',
              'avgCost': '₹35,000-70,000',
              'bestTime': 'June-September',
              'crowdLevel': 'Medium',
              'weatherRating': 4.8,
              'trendingReason': 'Ultimate bike trip destination',
              'recentTrend': '+50% bike trips in 2024',
              'topActivities': ['Bike trips', 'Trekking', 'Camping', 'Photography'],
              'uniqueFeature': 'World\'s highest motorable roads',
            },
          },
          {
            'name': 'Goa',
            'country': 'India',
            'description': 'Water sports and beach adventures',
            'bestFor': 'adventure',
            'budgetCategory': 'mid-range',
            'durationCategory': 'medium',
            'rating': 4.6,
            'highlights': ['Scuba diving', 'Parasailing', 'Jet skiing'],
            'insights': {
              'trendScore': 85,
              'popularityRank': 3,
              'avgVisitors': '8 million+ tourists/year',
              'peakSeason': 'November-February',
              'avgCost': '₹12,000-30,000',
              'bestTime': 'November-February',
              'crowdLevel': 'Very High',
              'weatherRating': 4.7,
              'trendingReason': 'Best water sports destination',
              'recentTrend': '+25% water sports bookings',
              'topActivities': ['Scuba', 'Parasailing', 'Jet ski', 'Kayaking'],
              'uniqueFeature': 'Affordable scuba certification',
            },
          },
          {
            'name': 'Andaman Islands',
            'country': 'India',
            'description': 'Tropical island adventures and diving',
            'bestFor': 'adventure',
            'budgetCategory': 'luxury',
            'durationCategory': 'long',
            'rating': 4.8,
            'highlights': ['Scuba diving', 'Snorkeling', 'Island hopping'],
            'insights': {
              'trendScore': 88,
              'popularityRank': 2,
              'avgVisitors': '500,000+ tourists/year',
              'peakSeason': 'October-May',
              'avgCost': '₹40,000-80,000',
              'bestTime': 'November-April',
              'crowdLevel': 'Medium',
              'weatherRating': 4.9,
              'trendingReason': 'Best diving spots in India',
              'recentTrend': '+30% diving tourism',
              'topActivities': ['Scuba', 'Snorkeling', 'Sea walking', 'Island hopping'],
              'uniqueFeature': 'Crystal clear waters & coral reefs',
            },
          },
        ];

      case 'cultural':
        return [
          {
            'name': 'Jaipur',
            'country': 'India',
            'description': 'Pink City - Rajasthani culture and heritage',
            'bestFor': 'cultural',
            'budgetCategory': 'mid-range',
            'durationCategory': 'medium',
            'rating': 4.7,
            'highlights': ['Amber Fort', 'City Palace', 'Hawa Mahal'],
            'insights': {
              'trendScore': 90,
              'popularityRank': 1,
              'avgVisitors': '5 million+ tourists/year',
              'peakSeason': 'October-March',
              'avgCost': '₹10,000-25,000',
              'bestTime': 'November-February',
              'crowdLevel': 'High',
              'weatherRating': 4.5,
              'trendingReason': 'Rich Rajasthani heritage & architecture',
              'recentTrend': '+20% cultural tourism in 2024',
              'topAttractions': ['Amber Fort', 'City Palace', 'Hawa Mahal', 'Jantar Mantar'],
              'uniqueFeature': 'UNESCO World Heritage Sites',
            },
          },
          {
            'name': 'Hampi',
            'country': 'India',
            'description': 'UNESCO World Heritage Site - Ancient Vijayanagara Empire',
            'bestFor': 'cultural',
            'budgetCategory': 'budget',
            'durationCategory': 'short',
            'rating': 4.8,
            'highlights': ['Virupaksha Temple', 'Stone Chariot', 'Ruins'],
            'insights': {
              'trendScore': 88,
              'popularityRank': 2,
              'avgVisitors': '500,000+ tourists/year',
              'peakSeason': 'October-February',
              'avgCost': '₹6,000-15,000',
              'bestTime': 'November-February',
              'crowdLevel': 'Medium',
              'weatherRating': 4.6,
              'trendingReason': 'Ancient ruins & UNESCO heritage',
              'recentTrend': '+25% heritage tourism',
              'topAttractions': ['Virupaksha Temple', 'Vittala Temple', 'Stone Chariot', 'Royal Enclosure'],
              'uniqueFeature': '14th century Vijayanagara capital',
            },
          },
          {
            'name': 'Khajuraho',
            'country': 'India',
            'description': 'Medieval temples with intricate sculptures',
            'bestFor': 'cultural',
            'budgetCategory': 'budget',
            'durationCategory': 'short',
            'rating': 4.6,
            'highlights': ['Temple complex', 'Light & Sound show', 'Sculptures'],
            'insights': {
              'trendScore': 82,
              'popularityRank': 3,
              'avgVisitors': '300,000+ tourists/year',
              'peakSeason': 'October-March',
              'avgCost': '₹7,000-18,000',
              'bestTime': 'October-February',
              'crowdLevel': 'Low-Medium',
              'weatherRating': 4.4,
              'trendingReason': 'Exquisite temple sculptures',
              'recentTrend': '+15% art & culture tourism',
              'topAttractions': ['Kandariya Temple', 'Lakshmana Temple', 'Light & Sound Show'],
              'uniqueFeature': 'Intricate erotic sculptures',
            },
          },
          {
            'name': 'Mysore',
            'country': 'India',
            'description': 'City of Palaces - Royal heritage and culture',
            'bestFor': 'cultural',
            'budgetCategory': 'mid-range',
            'durationCategory': 'short',
            'rating': 4.7,
            'highlights': ['Mysore Palace', 'Chamundi Hills', 'Brindavan Gardens'],
            'insights': {
              'trendScore': 86,
              'popularityRank': 2,
              'avgVisitors': '3 million+ tourists/year',
              'peakSeason': 'October-February',
              'avgCost': '₹8,000-20,000',
              'bestTime': 'October-February',
              'crowdLevel': 'Medium-High',
              'weatherRating': 4.6,
              'trendingReason': 'Royal palaces & Dasara festival',
              'recentTrend': '+18% palace tourism',
              'topAttractions': ['Mysore Palace', 'Chamundi Hills', 'Brindavan Gardens', 'St. Philomena\'s Church'],
              'uniqueFeature': 'Illuminated palace on Sundays',
            },
          },
          {
            'name': 'Kolkata',
            'country': 'India',
            'description': 'Cultural capital - Art, literature, and heritage',
            'bestFor': 'cultural',
            'budgetCategory': 'budget',
            'durationCategory': 'medium',
            'rating': 4.5,
            'highlights': ['Victoria Memorial', 'Howrah Bridge', 'Museums'],
            'insights': {
              'trendScore': 80,
              'popularityRank': 4,
              'avgVisitors': '2 million+ tourists/year',
              'peakSeason': 'October-March',
              'avgCost': '₹8,000-18,000',
              'bestTime': 'October-February',
              'crowdLevel': 'High',
              'weatherRating': 4.3,
              'trendingReason': 'Cultural capital with colonial heritage',
              'recentTrend': '+12% cultural tourism',
              'topAttractions': ['Victoria Memorial', 'Howrah Bridge', 'Indian Museum', 'Dakshineswar Temple'],
              'uniqueFeature': 'City of Joy with rich literary heritage',
            },
          },
        ];

      case 'birthday':
        return [
          {
            'name': 'Goa',
            'country': 'India',
            'description': 'Beach parties and vibrant nightlife',
            'bestFor': 'birthday',
            'budgetCategory': 'mid-range',
            'durationCategory': 'short',
            'rating': 4.7,
            'highlights': ['Beach clubs', 'Nightlife', 'Water sports'],
            'insights': {
              'trendScore': 92,
              'popularityRank': 1,
              'avgVisitors': '8 million+ tourists/year',
              'peakSeason': 'November-February',
              'avgCost': '₹12,000-30,000',
              'bestTime': 'November-February',
              'crowdLevel': 'Very High',
              'weatherRating': 4.7,
              'trendingReason': '#1 party destination in India',
              'recentTrend': '+30% birthday celebrations',
              'topActivities': ['Beach parties', 'Nightclubs', 'Water sports', 'Casino'],
              'uniqueFeature': 'Vibrant nightlife & beach clubs',
            },
          },
          {
            'name': 'Lonavala',
            'country': 'India',
            'description': 'Hill station getaway near Mumbai/Pune',
            'bestFor': 'birthday',
            'budgetCategory': 'budget',
            'durationCategory': 'short',
            'rating': 4.5,
            'highlights': ['Resorts', 'Waterfalls', 'Scenic views'],
            'insights': {
              'trendScore': 78,
              'popularityRank': 3,
              'avgVisitors': '2 million+ tourists/year',
              'peakSeason': 'June-September (monsoon)',
              'avgCost': '₹6,000-15,000',
              'bestTime': 'June-September',
              'crowdLevel': 'High',
              'weatherRating': 4.6,
              'trendingReason': 'Quick weekend getaway',
              'recentTrend': '+15% weekend trips',
              'topActivities': ['Trekking', 'Waterfall visits', 'Resort stays', 'Camping'],
              'uniqueFeature': 'Beautiful in monsoon season',
            },
          },
          {
            'name': 'Ooty',
            'country': 'India',
            'description': 'Queen of Hill Stations - Peaceful celebration',
            'bestFor': 'birthday',
            'budgetCategory': 'mid-range',
            'durationCategory': 'short',
            'rating': 4.6,
            'highlights': ['Botanical Gardens', 'Toy train', 'Lakes'],
            'insights': {
              'trendScore': 82,
              'popularityRank': 2,
              'avgVisitors': '2.5 million+ tourists/year',
              'peakSeason': 'April-June, September-November',
              'avgCost': '₹10,000-22,000',
              'bestTime': 'April-June',
              'crowdLevel': 'Medium-High',
              'weatherRating': 4.8,
              'trendingReason': 'Scenic hill station with pleasant weather',
              'recentTrend': '+18% family celebrations',
              'topActivities': ['Toy train ride', 'Boating', 'Gardens', 'Tea estates'],
              'uniqueFeature': 'UNESCO Nilgiri Mountain Railway',
            },
          },
          {
            'name': 'Dubai',
            'country': 'UAE',
            'description': 'Luxury celebration in the desert city',
            'bestFor': 'birthday',
            'budgetCategory': 'luxury',
            'durationCategory': 'medium',
            'rating': 4.8,
            'highlights': ['Burj Khalifa', 'Desert safari', 'Shopping'],
            'insights': {
              'trendScore': 95,
              'popularityRank': 1,
              'avgVisitors': '1 million+ Indian tourists/year',
              'peakSeason': 'November-March',
              'avgCost': '₹50,000-1,50,000',
              'bestTime': 'November-March',
              'crowdLevel': 'High',
              'weatherRating': 4.5,
              'trendingReason': 'Luxury shopping & entertainment',
              'recentTrend': '+40% luxury celebrations',
              'topActivities': ['Burj Khalifa', 'Desert safari', 'Shopping', 'Fine dining'],
              'uniqueFeature': 'World\'s tallest building & luxury malls',
            },
          },
          {
            'name': 'Pondicherry',
            'country': 'India',
            'description': 'French colonial charm and beaches',
            'bestFor': 'birthday',
            'budgetCategory': 'budget',
            'durationCategory': 'short',
            'rating': 4.6,
            'highlights': ['French Quarter', 'Auroville', 'Beaches'],
            'insights': {
              'trendScore': 80,
              'popularityRank': 3,
              'avgVisitors': '1.5 million+ tourists/year',
              'peakSeason': 'October-March',
              'avgCost': '₹8,000-18,000',
              'bestTime': 'October-March',
              'crowdLevel': 'Medium',
              'weatherRating': 4.6,
              'trendingReason': 'French charm with beach vibes',
              'recentTrend': '+22% young travelers',
              'topActivities': ['Beach cafes', 'French Quarter walk', 'Auroville', 'Water sports'],
              'uniqueFeature': 'French colonial architecture',
            },
          },
        ];

      case 'casual':
      default:
        return [
          {
            'name': 'Goa',
            'country': 'India',
            'description': 'Beaches, nightlife, and Portuguese heritage',
            'bestFor': 'casual',
            'budgetCategory': 'mid-range',
            'durationCategory': 'medium',
            'rating': 4.7,
            'highlights': ['Beaches', 'Churches', 'Nightlife'],
            'insights': {
              'trendScore': 90,
              'popularityRank': 1,
              'avgVisitors': '8 million+ tourists/year',
              'peakSeason': 'November-February',
              'avgCost': '₹12,000-28,000',
              'bestTime': 'November-February',
              'crowdLevel': 'Very High',
              'weatherRating': 4.7,
              'trendingReason': 'Perfect beach vacation destination',
              'recentTrend': '+25% domestic tourism',
              'topActivities': ['Beach hopping', 'Water sports', 'Nightlife', 'Church visits'],
              'uniqueFeature': 'Portuguese heritage & beaches',
            },
          },
          {
            'name': 'Manali',
            'country': 'India',
            'description': 'Himalayan hill station with scenic beauty',
            'bestFor': 'casual',
            'budgetCategory': 'mid-range',
            'durationCategory': 'medium',
            'rating': 4.6,
            'highlights': ['Rohtang Pass', 'Solang Valley', 'Mall Road'],
            'insights': {
              'trendScore': 88,
              'popularityRank': 2,
              'avgVisitors': '2 million+ tourists/year',
              'peakSeason': 'May-June, Dec-Feb',
              'avgCost': '₹15,000-32,000',
              'bestTime': 'May-June (summer)',
              'crowdLevel': 'High',
              'weatherRating': 4.6,
              'trendingReason': 'Popular hill station getaway',
              'recentTrend': '+30% summer bookings',
              'topActivities': ['Sightseeing', 'Shopping', 'Cafes', 'Nature walks'],
              'uniqueFeature': 'Snow-capped mountains & valleys',
            },
          },
          {
            'name': 'Jaipur',
            'country': 'India',
            'description': 'Pink City - Forts, palaces, and culture',
            'bestFor': 'casual',
            'budgetCategory': 'budget',
            'durationCategory': 'short',
            'rating': 4.7,
            'highlights': ['Amber Fort', 'City Palace', 'Markets'],
            'insights': {
              'trendScore': 85,
              'popularityRank': 3,
              'avgVisitors': '5 million+ tourists/year',
              'peakSeason': 'October-March',
              'avgCost': '₹10,000-22,000',
              'bestTime': 'November-February',
              'crowdLevel': 'High',
              'weatherRating': 4.5,
              'trendingReason': 'Heritage & shopping destination',
              'recentTrend': '+18% weekend trips',
              'topActivities': ['Fort visits', 'Shopping', 'Food tours', 'Photography'],
              'uniqueFeature': 'Pink City architecture',
            },
          },
          {
            'name': 'Coorg',
            'country': 'India',
            'description': 'Scotland of India - Coffee plantations',
            'bestFor': 'casual',
            'budgetCategory': 'mid-range',
            'durationCategory': 'short',
            'rating': 4.6,
            'highlights': ['Coffee estates', 'Abbey Falls', 'Nature'],
            'insights': {
              'trendScore': 82,
              'popularityRank': 4,
              'avgVisitors': '1 million+ tourists/year',
              'peakSeason': 'October-March',
              'avgCost': '₹12,000-25,000',
              'bestTime': 'October-March',
              'crowdLevel': 'Medium',
              'weatherRating': 4.7,
              'trendingReason': 'Peaceful nature retreat',
              'recentTrend': '+20% nature tourism',
              'topActivities': ['Coffee plantation tours', 'Waterfall visits', 'Trekking', 'Wildlife'],
              'uniqueFeature': 'Lush coffee plantations',
            },
          },
          {
            'name': 'Udaipur',
            'country': 'India',
            'description': 'City of Lakes - Romantic and scenic',
            'bestFor': 'casual',
            'budgetCategory': 'mid-range',
            'durationCategory': 'medium',
            'rating': 4.8,
            'highlights': ['Lake Palace', 'City Palace', 'Boat rides'],
            'insights': {
              'trendScore': 87,
              'popularityRank': 2,
              'avgVisitors': '1.5 million+ tourists/year',
              'peakSeason': 'October-March',
              'avgCost': '₹15,000-35,000',
              'bestTime': 'October-March',
              'crowdLevel': 'Medium-High',
              'weatherRating': 4.6,
              'trendingReason': 'Most romantic city in India',
              'recentTrend': '+22% couple travel',
              'topActivities': ['Lake boat rides', 'Palace visits', 'Sunset views', 'Rooftop dining'],
              'uniqueFeature': 'Venice of the East',
            },
          },
        ];
    }
  }

  String _getOccasionDescription(String destination, String occasionType) {
    switch (occasionType) {
      case 'wedding':
        return 'Perfect destination for your special wedding celebration';
      case 'devotional':
        return 'Spiritual journey to $destination';
      case 'adventure':
        return 'Thrilling adventure experiences in $destination';
      case 'cultural':
        return 'Explore the rich cultural heritage of $destination';
      case 'birthday':
        return 'Celebrate your special day in $destination';
      case 'casual':
      default:
        return 'Relaxing getaway to $destination';
    }
  }

  /// Enrich destinations with real-time weather data from OpenWeatherMap
  Future<List<Map<String, dynamic>>> _enrichWithWeatherData(List<Map<String, dynamic>> destinations) async {
    print('🌤️ Enriching ${destinations.length} destinations with real-time weather...');
    
    final enrichedDestinations = <Map<String, dynamic>>[];
    
    for (var dest in destinations) {
      final destName = dest['name'] as String;
      
      try {
        // Fetch real-time weather
        final weatherData = await _weatherService.getCurrentWeather(destName);
        
        if (weatherData != null) {
          // Add weather data to destination
          dest['weather'] = {
            'temperature': weatherData.temperature,
            'tempMin': weatherData.tempMin,
            'tempMax': weatherData.tempMax,
            'description': weatherData.description,
            'icon': weatherData.icon,
            'humidity': weatherData.humidity,
            'windSpeed': weatherData.windSpeed,
          };
          print('✅ $destName: ${weatherData.temperature.toStringAsFixed(1)}°C - ${weatherData.description}');
        } else {
          print('⚠️ $destName: Weather data unavailable, using defaults');
          dest['weather'] = null;
        }
      } catch (e) {
        print('❌ $destName: Weather fetch error - $e');
        dest['weather'] = null;
      }
      
      enrichedDestinations.add(dest);
    }
    
    print('✅ Weather enrichment complete!\n');
    return enrichedDestinations;
  }
}

// Made with Bob
