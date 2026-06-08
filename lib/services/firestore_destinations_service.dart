import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirestoreDestinationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _client;
  
  // Google Places API key - Replace with your actual key
  static const String _googlePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';

  FirestoreDestinationsService([http.Client? client]) 
      : _client = client ?? http.Client();

  /// Fetch trending destinations from Firestore with real-time filtering
  Future<List<Map<String, dynamic>>> getTrendingDestinations({
    required String occasionType,
    required double budget,
    required int duration,
  }) async {
    try {
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

      // Query Firestore for matching destinations
      final querySnapshot = await _firestore
          .collection('trending_destinations')
          .where('occasionTypes', arrayContains: occasionType)
          .where('budgetCategory', isEqualTo: budgetCategory)
          .orderBy('trendScore', descending: true)
          .limit(10)
          .get();

      final destinations = <Map<String, dynamic>>[];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Filter by duration if specified
        if (data['durationCategory'] == durationCategory || 
            data['durationCategory'] == 'all') {
          destinations.add({
            'id': doc.id,
            ...data,
          });
        }
      }

      // If we have destinations, return top 5
      if (destinations.isNotEmpty) {
        return destinations.take(5).toList();
      }

      // If no exact matches, get popular destinations for the occasion
      return await _getPopularDestinations(occasionType);
      
    } catch (e) {
      print('Error fetching from Firestore: $e');
      return [];
    }
  }

  /// Get popular destinations for an occasion (fallback)
  Future<List<Map<String, dynamic>>> _getPopularDestinations(String occasionType) async {
    try {
      final querySnapshot = await _firestore
          .collection('trending_destinations')
          .where('occasionTypes', arrayContains: occasionType)
          .orderBy('trendScore', descending: true)
          .limit(5)
          .get();

      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error fetching popular destinations: $e');
      return [];
    }
  }

  /// Fetch real destination data from Google Places API
  Future<Map<String, dynamic>?> fetchRealDestinationData(String destinationName) async {
    try {
      // Search for the place
      final searchUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?'
        'input=${Uri.encodeQueryComponent(destinationName)}&'
        'inputtype=textquery&'
        'fields=place_id,name,formatted_address,rating,user_ratings_total,photos&'
        'key=$_googlePlacesApiKey'
      );

      final searchResponse = await _client.get(searchUrl).timeout(const Duration(seconds: 10));

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);
        final candidates = searchData['candidates'] as List<dynamic>?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final place = candidates[0];
          final placeId = place['place_id'];

          // Get detailed place information
          final detailsUrl = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/details/json?'
            'place_id=$placeId&'
            'fields=name,formatted_address,rating,user_ratings_total,reviews,photos,types,website&'
            'key=$_googlePlacesApiKey'
          );

          final detailsResponse = await _client.get(detailsUrl).timeout(const Duration(seconds: 10));

          if (detailsResponse.statusCode == 200) {
            final detailsData = jsonDecode(detailsResponse.body);
            final result = detailsData['result'];

            return {
              'name': result['name'],
              'address': result['formatted_address'],
              'rating': result['rating'] ?? 4.0,
              'totalRatings': result['user_ratings_total'] ?? 0,
              'types': result['types'] ?? [],
              'website': result['website'],
              'photos': _extractPhotoUrls(result['photos']),
            };
          }
        }
      }
    } catch (e) {
      print('Error fetching real destination data: $e');
    }
    return null;
  }

  List<String> _extractPhotoUrls(List<dynamic>? photos) {
    if (photos == null) return [];
    
    return photos.take(3).map((photo) {
      final photoReference = photo['photo_reference'];
      return 'https://maps.googleapis.com/maps/api/place/photo?'
          'maxwidth=800&'
          'photo_reference=$photoReference&'
          'key=$_googlePlacesApiKey';
    }).toList();
  }

  /// Add or update a destination in Firestore
  Future<void> addOrUpdateDestination(Map<String, dynamic> destinationData) async {
    try {
      final destinationId = destinationData['name'].toString().toLowerCase().replaceAll(' ', '_');
      
      await _firestore
          .collection('trending_destinations')
          .doc(destinationId)
          .set({
        ...destinationData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('Destination added/updated: ${destinationData['name']}');
    } catch (e) {
      print('Error adding destination: $e');
    }
  }

  /// Seed initial data to Firestore (run once to populate database)
  Future<void> seedInitialDestinations() async {
    // This method would be called once to populate Firestore with initial data
    // You can fetch real data from APIs and store it
    print('Seeding destinations to Firestore...');
    
    // Example: Add destinations with real data
    final destinations = [
      {
        'name': 'Jaipur',
        'country': 'India',
        'description': 'Pink City - Rajasthani culture and heritage',
        'occasionTypes': ['cultural', 'casual', 'wedding'],
        'budgetCategory': 'mid-range',
        'durationCategory': 'medium',
        'rating': 4.7,
        'trendScore': 90,
        'highlights': ['Amber Fort', 'City Palace', 'Hawa Mahal'],
        'insights': {
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
      // Add more destinations...
    ];

    for (var destination in destinations) {
      await addOrUpdateDestination(destination);
    }
    
    print('Seeding complete!');
  }

  /// Update destination with real-time data from Google Places
  Future<void> updateDestinationWithRealData(String destinationName) async {
    final realData = await fetchRealDestinationData(destinationName);
    
    if (realData != null) {
      final destinationId = destinationName.toLowerCase().replaceAll(' ', '_');
      
      await _firestore
          .collection('trending_destinations')
          .doc(destinationId)
          .update({
        'realRating': realData['rating'],
        'totalRatings': realData['totalRatings'],
        'photos': realData['photos'],
        'website': realData['website'],
        'lastRealDataUpdate': FieldValue.serverTimestamp(),
      });
      
      print('Updated $destinationName with real data');
    }
  }

  /// Fetch trending destinations from travel blogs/APIs
  Future<List<String>> fetchTrendingFromWeb(String occasionType) async {
    // This would scrape or call travel APIs to get trending destinations
    // For now, returning empty list - implement based on your data source
    return [];
  }
}

// Made with Bob
