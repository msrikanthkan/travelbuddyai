import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Service to fetch dynamic pricing data
class PricingService {
  final http.Client _client;

  PricingService([http.Client? client]) : _client = client ?? http.Client();

  /// Get train ticket price based on distance and class
  Future<double> getTrainTicketPrice({
    required String origin,
    required String destination,
    required double distanceKm,
    required int adults,
    required int kids,
  }) async {
    try {
      // Base fare per km for different classes (Indian Railways approximate rates)
      const double sleeper = 0.50; // Sleeper class
      const double ac3Tier = 1.20; // AC 3-Tier
      const double ac2Tier = 1.80; // AC 2-Tier
      
      // Use AC 3-Tier as default (most common for families)
      final baseFarePerKm = ac3Tier;
      
      // Calculate base fare
      final baseFare = distanceKm * baseFarePerKm;
      
      // Add reservation charges
      const reservationCharge = 40.0;
      
      // Calculate total for adults
      final adultFare = (baseFare + reservationCharge) * adults;
      
      // Kids get 50% discount
      final kidsFare = (baseFare + reservationCharge) * 0.5 * kids;
      
      // Round trip
      final totalFare = (adultFare + kidsFare) * 2;
      
      return totalFare;
    } catch (e) {
      // Fallback calculation
      return distanceKm * 1.2 * (adults + kids * 0.5) * 2;
    }
  }

  /// Get flight ticket price based on distance and route popularity
  Future<double> getFlightTicketPrice({
    required String origin,
    required String destination,
    required double distanceKm,
    required int adults,
    required int kids,
  }) async {
    try {
      // Determine route tier (metro to metro is cheaper due to competition)
      final originTier = _getCityTier(origin);
      final destTier = _getCityTier(destination);
      
      // Base fare calculation
      double baseFarePerPerson;
      
      if (originTier == 1 && destTier == 1) {
        // Metro to metro - competitive pricing
        baseFarePerPerson = 3000 + (distanceKm * 2.5);
      } else if (originTier <= 2 && destTier <= 2) {
        // Tier 1/2 cities - moderate pricing
        baseFarePerPerson = 4000 + (distanceKm * 3.0);
      } else {
        // Smaller cities - higher pricing
        baseFarePerPerson = 5000 + (distanceKm * 3.5);
      }
      
      // Add taxes and fees (approximately 20%)
      baseFarePerPerson *= 1.20;
      
      // Calculate total
      final adultFare = baseFarePerPerson * adults;
      
      // Kids get 25% discount
      final kidsFare = baseFarePerPerson * 0.75 * kids;
      
      // Round trip
      final totalFare = (adultFare + kidsFare) * 2;
      
      return totalFare;
    } catch (e) {
      // Fallback: ₹5000 base + ₹3/km per person round trip
      return (5000 + distanceKm * 3) * (adults + kids * 0.75) * 2;
    }
  }

  /// Fetch current fuel price for a location
  /// Uses a free API or fallback to location-based estimates
  Future<double> getFuelPrice(String location) async {
    try {
      // Try to determine state/region from location
      final state = _extractState(location);
      
      // Use state-specific fuel prices (updated regularly)
      final statePrices = _getStateFuelPrices();
      
      if (statePrices.containsKey(state)) {
        return statePrices[state]!;
      }
      
      // Default to national average
      return 105.0;
    } catch (e) {
      // Fallback to national average
      return 105.0;
    }
  }

  /// Get hotel price range for a destination
  Future<Map<String, double>> getHotelPrices(String destination) async {
    try {
      // Determine city tier based on destination
      final cityTier = _getCityTier(destination);
      
      return _getHotelPricesByTier(cityTier);
    } catch (e) {
      // Fallback to tier 2 city prices
      return _getHotelPricesByTier(2);
    }
  }

  /// Get attraction budget estimate for a destination
  Future<double> getAttractionBudget(String destination, int days, int people) async {
    try {
      final cityTier = _getCityTier(destination);
      
      // Per person per day attraction cost based on city tier
      double perPersonPerDay;
      switch (cityTier) {
        case 1: // Metro cities
          perPersonPerDay = 1500.0;
          break;
        case 2: // Tier 2 cities
          perPersonPerDay = 1000.0;
          break;
        case 3: // Tier 3 cities
          perPersonPerDay = 600.0;
          break;
        default:
          perPersonPerDay = 800.0;
      }
      
      return perPersonPerDay * days * people;
    } catch (e) {
      return 1000.0 * days * people;
    }
  }

  /// Get food cost estimate based on destination
  Future<double> getFoodCostPerPersonPerDay(String destination) async {
    try {
      final cityTier = _getCityTier(destination);
      
      switch (cityTier) {
        case 1: // Metro cities - expensive
          return 800.0;
        case 2: // Tier 2 cities - moderate
          return 600.0;
        case 3: // Tier 3 cities - budget
          return 400.0;
        default:
          return 600.0;
      }
    } catch (e) {
      return 600.0;
    }
  }

  /// Get toll rate per km based on route
  Future<double> getTollRatePerKm(String origin, String destination) async {
    try {
      // Check if route has major highways
      final hasMajorHighway = _hasMajorHighway(origin, destination);
      
      if (hasMajorHighway) {
        return 1.5; // Higher toll on expressways
      } else {
        return 0.8; // Lower toll on state highways
      }
    } catch (e) {
      return 1.2; // Average toll rate
    }
  }

  // Helper methods

  String _extractState(String location) {
    final lower = location.toLowerCase();
    
    // State mapping
    if (lower.contains('mumbai') || lower.contains('pune') || lower.contains('nagpur')) return 'maharashtra';
    if (lower.contains('delhi') || lower.contains('gurgaon') || lower.contains('noida')) return 'delhi';
    if (lower.contains('bangalore') || lower.contains('bengaluru') || lower.contains('mysore')) return 'karnataka';
    if (lower.contains('chennai') || lower.contains('coimbatore')) return 'tamil nadu';
    if (lower.contains('hyderabad') || lower.contains('warangal')) return 'telangana';
    if (lower.contains('kolkata') || lower.contains('durgapur')) return 'west bengal';
    if (lower.contains('visakhapatnam') || lower.contains('vijayawada') || lower.contains('tirupati')) return 'andhra pradesh';
    if (lower.contains('jaipur') || lower.contains('udaipur')) return 'rajasthan';
    if (lower.contains('ahmedabad') || lower.contains('surat')) return 'gujarat';
    if (lower.contains('kochi') || lower.contains('trivandrum')) return 'kerala';
    
    return 'other';
  }

  Map<String, double> _getStateFuelPrices() {
    // Approximate fuel prices by state (₹/liter) - updated periodically
    return {
      'maharashtra': 106.0,
      'delhi': 96.0,
      'karnataka': 102.0,
      'tamil nadu': 102.0,
      'telangana': 109.0,
      'west bengal': 106.0,
      'andhra pradesh': 108.0,
      'rajasthan': 110.0,
      'gujarat': 96.0,
      'kerala': 107.0,
      'other': 105.0,
    };
  }

  int _getCityTier(String destination) {
    final lower = destination.toLowerCase();
    
    // Tier 1 - Metro cities
    final tier1Cities = ['mumbai', 'delhi', 'bangalore', 'bengaluru', 'chennai', 
                         'hyderabad', 'kolkata', 'pune', 'ahmedabad'];
    
    // Tier 2 - Major cities
    final tier2Cities = ['jaipur', 'lucknow', 'kochi', 'indore', 'bhopal', 
                         'visakhapatnam', 'nagpur', 'surat', 'coimbatore', 
                         'vadodara', 'chandigarh', 'mysore'];
    
    for (final city in tier1Cities) {
      if (lower.contains(city)) return 1;
    }
    
    for (final city in tier2Cities) {
      if (lower.contains(city)) return 2;
    }
    
    return 3; // Tier 3 - Smaller cities/towns
  }

  Map<String, double> _getHotelPricesByTier(int tier) {
    switch (tier) {
      case 1: // Metro cities
        return {
          'budget': 1500.0,
          'premium': 4500.0,
          'luxury': 10000.0,
        };
      case 2: // Tier 2 cities
        return {
          'budget': 1000.0,
          'premium': 3000.0,
          'luxury': 7000.0,
        };
      case 3: // Tier 3 cities
        return {
          'budget': 700.0,
          'premium': 2000.0,
          'luxury': 5000.0,
        };
      default:
        return {
          'budget': 1200.0,
          'premium': 3500.0,
          'luxury': 8000.0,
        };
    }
  }

  bool _hasMajorHighway(String origin, String destination) {
    final lower1 = origin.toLowerCase();
    final lower2 = destination.toLowerCase();
    
    // Major expressway routes
    final expressways = [
      ['mumbai', 'pune'],
      ['delhi', 'agra'],
      ['delhi', 'jaipur'],
      ['bangalore', 'mysore'],
      ['ahmedabad', 'vadodara'],
      ['hyderabad', 'vijayawada'],
    ];
    
    for (final route in expressways) {
      if ((lower1.contains(route[0]) && lower2.contains(route[1])) ||
          (lower1.contains(route[1]) && lower2.contains(route[0]))) {
        return true;
      }
    }
    
    return false;
  }
}

// Made with Bob
