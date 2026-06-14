import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDestinationsService {
  static final FirebaseDestinationsService _instance = FirebaseDestinationsService._internal();
  factory FirebaseDestinationsService() => _instance;
  FirebaseDestinationsService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _cacheKeyPrefix = 'cached_destinations_';
  static const String _versionKeyPrefix = 'destinations_version_';
  
  bool _isInitialized = false;
  final Map<String, List<Map<String, dynamic>>> _cachedDestinations = {};

  /// Initialize Firebase Remote Config for destinations
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 12),
      ));

      // Set default values for all occasion types
      await _remoteConfig.setDefaults({
        'destinations_casual': _getDefaultCasualDestinations(),
        'destinations_wedding': _getDefaultWeddingDestinations(),
        'destinations_devotional': _getDefaultDevotionalDestinations(),
        'destinations_adventure': _getDefaultAdventureDestinations(),
        'destinations_birthday': _getDefaultBirthdayDestinations(),
        'destinations_cultural': _getDefaultCulturalDestinations(),
      });

      // Try to fetch and activate
      await _remoteConfig.fetchAndActivate();
      
      print('✅ Firebase Destinations Service initialized');
      _isInitialized = true;
    } catch (e) {
      print('⚠️ Error initializing Firebase Destinations Service: $e');
      // Will use default values
      _isInitialized = true;
    }
  }

  /// Get destinations for a specific occasion type
  Future<List<Map<String, dynamic>>> getDestinations(String occasionType) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check cache first
    if (_cachedDestinations.containsKey(occasionType)) {
      print('📦 Using cached destinations for $occasionType');
      return _cachedDestinations[occasionType]!;
    }

    try {
      final paramKey = 'destinations_$occasionType';
      final jsonString = _remoteConfig.getString(paramKey);
      
      if (jsonString.isEmpty) {
        print('⚠️ No data for $occasionType, using defaults');
        return _getDefaultDestinationsByOccasion(occasionType);
      }

      final data = json.decode(jsonString);
      final destinations = (data['destinations'] as List)
          .map((dest) => Map<String, dynamic>.from(dest))
          .toList();
      
      // Cache the destinations
      _cachedDestinations[occasionType] = destinations;
      
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cacheKeyPrefix$occasionType', jsonString);
      await prefs.setString('$_versionKeyPrefix$occasionType', data['version'] ?? '1.0.0');
      
      print('✅ Loaded ${destinations.length} destinations for $occasionType from Firebase');
      return destinations;
    } catch (e) {
      print('❌ Error loading destinations for $occasionType: $e');
      // Try to load from local cache
      return await _loadFromLocalCache(occasionType);
    }
  }

  /// Load destinations from local cache
  Future<List<Map<String, dynamic>>> _loadFromLocalCache(String occasionType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_cacheKeyPrefix$occasionType');
      
      if (cachedData != null) {
        final data = json.decode(cachedData);
        final destinations = (data['destinations'] as List)
            .map((dest) => Map<String, dynamic>.from(dest))
            .toList();
        
        print('📦 Loaded ${destinations.length} destinations for $occasionType from local cache');
        return destinations;
      }
    } catch (e) {
      print('❌ Error loading from local cache: $e');
    }
    
    // Final fallback to hardcoded defaults
    return _getDefaultDestinationsByOccasion(occasionType);
  }

  /// Log user search to Firestore for analytics
  Future<void> logUserSearch({
    required String destination,
    required String occasionType,
    required String budgetCategory,
    required int duration,
  }) async {
    try {
      await _firestore.collection('user_searches').add({
        'destination': destination,
        'occasionType': occasionType,
        'budgetCategory': budgetCategory,
        'duration': duration,
        'timestamp': FieldValue.serverTimestamp(),
        'found': await _isDestinationInFirebase(destination, occasionType),
      });
      
      print('📊 Logged user search: $destination ($occasionType)');
    } catch (e) {
      print('⚠️ Error logging user search: $e');
      // Non-critical, don't throw
    }
  }

  /// Check if destination exists in Firebase
  Future<bool> _isDestinationInFirebase(String destination, String occasionType) async {
    try {
      final destinations = await getDestinations(occasionType);
      return destinations.any((dest) => 
        dest['name'].toString().toLowerCase() == destination.toLowerCase()
      );
    } catch (e) {
      return false;
    }
  }

  /// Get default destinations by occasion type (fallback)
  List<Map<String, dynamic>> _getDefaultDestinationsByOccasion(String occasionType) {
    switch (occasionType) {
      case 'casual':
        return json.decode(_getDefaultCasualDestinations())['destinations'];
      case 'wedding':
        return json.decode(_getDefaultWeddingDestinations())['destinations'];
      case 'devotional':
        return json.decode(_getDefaultDevotionalDestinations())['destinations'];
      case 'adventure':
        return json.decode(_getDefaultAdventureDestinations())['destinations'];
      case 'birthday':
        return json.decode(_getDefaultBirthdayDestinations())['destinations'];
      case 'cultural':
        return json.decode(_getDefaultCulturalDestinations())['destinations'];
      default:
        return json.decode(_getDefaultCasualDestinations())['destinations'];
    }
  }

  /// Default casual destinations JSON
  String _getDefaultCasualDestinations() {
    return '''
{
  "version": "1.0.0",
  "last_updated": "2024-06-09",
  "destinations": [
    {
      "name": "Goa",
      "country": "India",
      "description": "Beaches, nightlife, and Portuguese heritage",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.7,
      "highlights": ["Beaches", "Churches", "Nightlife"],
      "avgCost": "₹12,000-28,000",
      "bestTime": "November-February",
      "popularityScore": 90
    },
    {
      "name": "Manali",
      "country": "India",
      "description": "Himalayan hill station with scenic beauty",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.6,
      "highlights": ["Rohtang Pass", "Solang Valley", "Mall Road"],
      "avgCost": "₹15,000-32,000",
      "bestTime": "May-June (summer)",
      "popularityScore": 88
    },
    {
      "name": "Jaipur",
      "country": "India",
      "description": "Pink City - Forts, palaces, and culture",
      "bestFor": "casual",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.7,
      "highlights": ["Amber Fort", "City Palace", "Markets"],
      "avgCost": "₹10,000-22,000",
      "bestTime": "November-February",
      "popularityScore": 85
    },
    {
      "name": "Coorg",
      "country": "India",
      "description": "Scotland of India - Coffee plantations",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "short",
      "rating": 4.6,
      "highlights": ["Coffee estates", "Abbey Falls", "Nature"],
      "avgCost": "₹12,000-25,000",
      "bestTime": "October-March",
      "popularityScore": 82
    },
    {
      "name": "Udaipur",
      "country": "India",
      "description": "City of Lakes - Romantic and scenic",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.8,
      "highlights": ["Lake Palace", "City Palace", "Boat rides"],
      "avgCost": "₹15,000-35,000",
      "bestTime": "October-March",
      "popularityScore": 87
    },
    {
      "name": "Rishikesh",
      "country": "India",
      "description": "Yoga capital and adventure sports hub",
      "bestFor": "casual",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.5,
      "highlights": ["River rafting", "Yoga", "Temples"],
      "avgCost": "₹8,000-18,000",
      "bestTime": "September-November",
      "popularityScore": 80
    },
    {
      "name": "Ooty",
      "country": "India",
      "description": "Queen of Hill Stations",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "short",
      "rating": 4.4,
      "highlights": ["Tea gardens", "Botanical garden", "Toy train"],
      "avgCost": "₹10,000-22,000",
      "bestTime": "April-June",
      "popularityScore": 78
    },
    {
      "name": "Shimla",
      "country": "India",
      "description": "Colonial hill station with scenic views",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.5,
      "highlights": ["Mall Road", "Jakhu Temple", "Ridge"],
      "avgCost": "₹12,000-25,000",
      "bestTime": "May-June",
      "popularityScore": 83
    },
    {
      "name": "Munnar",
      "country": "India",
      "description": "Tea plantations and misty mountains",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "short",
      "rating": 4.6,
      "highlights": ["Tea estates", "Eravikulam Park", "Mattupetty Dam"],
      "avgCost": "₹11,000-24,000",
      "bestTime": "September-March",
      "popularityScore": 81
    },
    {
      "name": "Andaman",
      "country": "India",
      "description": "Pristine beaches and water sports",
      "bestFor": "casual",
      "budgetCategory": "luxury",
      "durationCategory": "long",
      "rating": 4.8,
      "highlights": ["Radhanagar Beach", "Scuba diving", "Havelock Island"],
      "avgCost": "₹35,000-60,000",
      "bestTime": "November-April",
      "popularityScore": 89
    }
  ]
}
''';
  }

  /// Default wedding destinations JSON
  String _getDefaultWeddingDestinations() {
    return '''
{
  "version": "1.0.0",
  "destinations": [
    {
      "name": "Udaipur",
      "country": "India",
      "description": "City of Lakes - Perfect for royal destination weddings",
      "bestFor": "wedding",
      "budgetCategory": "luxury",
      "durationCategory": "medium",
      "rating": 4.8,
      "highlights": ["Lake Palace", "City Palace", "Royal venues"],
      "avgCost": "₹15-50 lakhs",
      "bestTime": "November-February",
      "popularityScore": 95
    },
    {
      "name": "Jaipur",
      "country": "India",
      "description": "Pink City - Heritage palaces for grand weddings",
      "bestFor": "wedding",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.7,
      "highlights": ["Amber Fort", "City Palace", "Heritage hotels"],
      "avgCost": "₹8-25 lakhs",
      "bestTime": "November-February",
      "popularityScore": 88
    },
    {
      "name": "Goa",
      "country": "India",
      "description": "Beach weddings with Portuguese charm",
      "bestFor": "wedding",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.6,
      "highlights": ["Beach venues", "Churches", "Resorts"],
      "avgCost": "₹5-20 lakhs",
      "bestTime": "December-January",
      "popularityScore": 85
    },
    {
      "name": "Jim Corbett",
      "country": "India",
      "description": "Wildlife resort weddings in nature",
      "bestFor": "wedding",
      "budgetCategory": "mid-range",
      "durationCategory": "short",
      "rating": 4.5,
      "highlights": ["Resorts", "Nature", "Wildlife"],
      "avgCost": "₹6-18 lakhs",
      "bestTime": "November-February",
      "popularityScore": 75
    },
    {
      "name": "Kerala Backwaters",
      "country": "India",
      "description": "Houseboat weddings in serene backwaters",
      "bestFor": "wedding",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.7,
      "highlights": ["Houseboats", "Backwaters", "Traditional venues"],
      "avgCost": "₹7-22 lakhs",
      "bestTime": "November-February",
      "popularityScore": 82
    }
  ]
}
''';
  }

  /// Default devotional destinations JSON
  String _getDefaultDevotionalDestinations() {
    return '''
{
  "version": "1.0.0",
  "destinations": [
    {
      "name": "Tirupati",
      "country": "India",
      "description": "Lord Venkateswara Temple - Most visited pilgrimage",
      "bestFor": "devotional",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.9,
      "highlights": ["Tirumala Temple", "Sri Padmavathi Temple"],
      "avgCost": "₹3,000-8,000",
      "bestTime": "September-February",
      "popularityScore": 98
    },
    {
      "name": "Varanasi",
      "country": "India",
      "description": "Spiritual capital on the Ganges",
      "bestFor": "devotional",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.8,
      "highlights": ["Kashi Vishwanath", "Ganga Aarti", "Ghats"],
      "avgCost": "₹4,000-10,000",
      "bestTime": "October-March",
      "popularityScore": 96
    },
    {
      "name": "Shirdi",
      "country": "India",
      "description": "Sai Baba Temple - Popular pilgrimage",
      "bestFor": "devotional",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.7,
      "highlights": ["Sai Baba Temple", "Dwarkamai", "Chavadi"],
      "avgCost": "₹3,500-9,000",
      "bestTime": "October-March",
      "popularityScore": 92
    },
    {
      "name": "Amritsar",
      "country": "India",
      "description": "Golden Temple - Sikh pilgrimage center",
      "bestFor": "devotional",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.9,
      "highlights": ["Golden Temple", "Jallianwala Bagh", "Wagah Border"],
      "avgCost": "₹5,000-12,000",
      "bestTime": "November-March",
      "popularityScore": 94
    },
    {
      "name": "Haridwar",
      "country": "India",
      "description": "Gateway to the Gods on the Ganges",
      "bestFor": "devotional",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.6,
      "highlights": ["Har Ki Pauri", "Ganga Aarti", "Temples"],
      "avgCost": "₹4,000-10,000",
      "bestTime": "September-November",
      "popularityScore": 90
    }
  ]
}
''';
  }

  /// Default adventure destinations JSON
  String _getDefaultAdventureDestinations() {
    return '''
{
  "version": "1.0.0",
  "destinations": [
    {
      "name": "Leh-Ladakh",
      "country": "India",
      "description": "High-altitude adventure paradise",
      "bestFor": "adventure",
      "budgetCategory": "mid-range",
      "durationCategory": "long",
      "rating": 4.9,
      "highlights": ["Pangong Lake", "Khardung La", "Monasteries"],
      "avgCost": "₹25,000-45,000",
      "bestTime": "June-September",
      "popularityScore": 95
    },
    {
      "name": "Rishikesh",
      "country": "India",
      "description": "Adventure sports capital",
      "bestFor": "adventure",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.7,
      "highlights": ["River rafting", "Bungee jumping", "Camping"],
      "avgCost": "₹8,000-18,000",
      "bestTime": "September-November",
      "popularityScore": 88
    },
    {
      "name": "Spiti Valley",
      "country": "India",
      "description": "Remote Himalayan adventure",
      "bestFor": "adventure",
      "budgetCategory": "mid-range",
      "durationCategory": "long",
      "rating": 4.8,
      "highlights": ["Key Monastery", "Chandratal Lake", "Trekking"],
      "avgCost": "₹20,000-40,000",
      "bestTime": "June-September",
      "popularityScore": 90
    },
    {
      "name": "Goa",
      "country": "India",
      "description": "Water sports and beach adventures",
      "bestFor": "adventure",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.6,
      "highlights": ["Parasailing", "Scuba diving", "Jet skiing"],
      "avgCost": "₹15,000-30,000",
      "bestTime": "November-February",
      "popularityScore": 85
    },
    {
      "name": "Manali",
      "country": "India",
      "description": "Mountain adventure hub",
      "bestFor": "adventure",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.7,
      "highlights": ["Skiing", "Paragliding", "Trekking"],
      "avgCost": "₹18,000-35,000",
      "bestTime": "December-February (skiing)",
      "popularityScore": 87
    }
  ]
}
''';
  }

  /// Default birthday destinations JSON
  String _getDefaultBirthdayDestinations() {
    return '''
{
  "version": "1.0.0",
  "destinations": [
    {
      "name": "Goa",
      "country": "India",
      "description": "Beach parties and celebrations",
      "bestFor": "birthday",
      "budgetCategory": "mid-range",
      "durationCategory": "short",
      "rating": 4.7,
      "highlights": ["Beach parties", "Nightlife", "Resorts"],
      "avgCost": "₹10,000-25,000",
      "bestTime": "November-February",
      "popularityScore": 90
    },
    {
      "name": "Lonavala",
      "country": "India",
      "description": "Quick getaway near Mumbai/Pune",
      "bestFor": "birthday",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.5,
      "highlights": ["Hill station", "Resorts", "Nature"],
      "avgCost": "₹8,000-18,000",
      "bestTime": "October-May",
      "popularityScore": 82
    },
    {
      "name": "Udaipur",
      "country": "India",
      "description": "Royal celebration in City of Lakes",
      "bestFor": "birthday",
      "budgetCategory": "luxury",
      "durationCategory": "short",
      "rating": 4.8,
      "highlights": ["Lake Palace", "Rooftop dining", "Boat rides"],
      "avgCost": "₹15,000-35,000",
      "bestTime": "October-March",
      "popularityScore": 85
    }
  ]
}
''';
  }

  /// Default cultural destinations JSON
  String _getDefaultCulturalDestinations() {
    return '''
{
  "version": "1.0.0",
  "destinations": [
    {
      "name": "Jaipur",
      "country": "India",
      "description": "Pink City - Rich Rajasthani culture",
      "bestFor": "cultural",
      "budgetCategory": "mid-range",
      "durationCategory": "short",
      "rating": 4.7,
      "highlights": ["Forts", "Palaces", "Folk performances"],
      "avgCost": "₹10,000-22,000",
      "bestTime": "November-February",
      "popularityScore": 88
    },
    {
      "name": "Varanasi",
      "country": "India",
      "description": "Ancient city with spiritual culture",
      "bestFor": "cultural",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.8,
      "highlights": ["Ghats", "Temples", "Classical music"],
      "avgCost": "₹5,000-12,000",
      "bestTime": "October-March",
      "popularityScore": 92
    },
    {
      "name": "Hampi",
      "country": "India",
      "description": "UNESCO World Heritage Site",
      "bestFor": "cultural",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.6,
      "highlights": ["Ancient ruins", "Temples", "History"],
      "avgCost": "₹6,000-14,000",
      "bestTime": "October-February",
      "popularityScore": 85
    }
  ]
}
''';
  }

  /// Force refresh destinations from Firebase
  Future<void> forceRefresh() async {
    _cachedDestinations.clear();
    await _remoteConfig.fetchAndActivate();
    print('🔄 Forced refresh of destinations from Firebase');
  }
}

// Made with Bob
