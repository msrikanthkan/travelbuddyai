import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class AttractionsService {
  final http.Client _client;
  
  // Overpass API for fetching real POI data from OpenStreetMap
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  
  // Wikimedia Commons API for fetching real images
  static const String _wikimediaUrl = 'https://commons.wikimedia.org/w/api.php';

  AttractionsService([http.Client? client]) : _client = client ?? http.Client();

  /// Fetch real attractions from OpenStreetMap using Overpass API
  Future<List<Attraction>> getAttractionsByDestination(String destination) async {
    try {
      // First, get coordinates for the destination
      final coords = await _getCoordinates(destination);
      if (coords == null) {
        return _generateFallbackAttractions(destination);
      }

      // Fetch real POIs from OpenStreetMap
      final attractions = await _fetchRealAttractions(
        coords['lat']!,
        coords['lon']!,
        destination,
      );

      return attractions.isNotEmpty ? attractions : _generateFallbackAttractions(destination);
    } catch (e) {
      print('Error fetching attractions: $e');
      return _generateFallbackAttractions(destination);
    }
  }

  /// Get coordinates for a location using Nominatim
  Future<Map<String, double>?> _getCoordinates(String location) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeQueryComponent(location)}'
        '&format=json&limit=1'
      );

      final response = await _client.get(
        url,
        headers: {'User-Agent': 'TravelBuddyAI/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty) return null;

      final result = data[0] as Map<String, dynamic>;
      final lat = double.tryParse(result['lat']?.toString() ?? '');
      final lon = double.tryParse(result['lon']?.toString() ?? '');

      if (lat == null || lon == null) return null;
      return {'lat': lat, 'lon': lon};
    } catch (e) {
      return null;
    }
  }

  /// Fetch real attractions using Overpass API
  Future<List<Attraction>> _fetchRealAttractions(
    double lat,
    double lon,
    String cityName,
  ) async {
    try {
      // Search radius in meters (10km)
      const radius = 10000;

      // Overpass QL query to fetch tourist attractions, museums, monuments, etc.
      final query = '''
[out:json][timeout:25];
(
  node["tourism"="attraction"](around:$radius,$lat,$lon);
  node["tourism"="museum"](around:$radius,$lat,$lon);
  node["historic"](around:$radius,$lat,$lon);
  node["amenity"="place_of_worship"](around:$radius,$lat,$lon);
  way["tourism"="attraction"](around:$radius,$lat,$lon);
  way["tourism"="museum"](around:$radius,$lat,$lon);
  way["historic"](around:$radius,$lat,$lon);
);
out body 20;
>;
out skel qt;
''';

      final response = await _client.post(
        Uri.parse(_overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: query,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = (data['elements'] as List<dynamic>?) ?? [];

      final attractions = <Attraction>[];
      var index = 0;

      for (final element in elements) {
        if (index >= 10) break; // Limit to 10 attractions
        
        final tags = element['tags'] as Map<String, dynamic>?;
        if (tags == null) continue;

        final name = tags['name'] as String?;
        if (name == null || name.isEmpty) continue;

        // Skip if already added
        if (attractions.any((a) => a.name == name)) continue;

        final description = tags['description'] as String? ??
                          tags['tourism'] as String? ??
                          tags['historic'] as String? ??
                          'Popular attraction in $cityName';

        final category = _determineCategory(tags);
        
        // Fetch real image for this attraction
        final images = await _fetchAttractionImages(name, cityName);
        
        attractions.add(Attraction(
          id: 'osm_${element['id']}',
          name: name,
          description: description,
          location: cityName,
          ticketPrice: _estimateTicketPrice(category, tags),
          rating: 4.0 + (index % 10) / 10, // Simulated rating
          images: images,
          category: category,
          isKidFriendly: _isKidFriendly(category),
        ));

        index++;
      }

      return attractions;
    } catch (e) {
      print('Error fetching from Overpass API: $e');
      return [];
    }
  }

  /// Fetch real images for an attraction from Wikipedia
  Future<List<String>> _fetchAttractionImages(String attractionName, String cityName) async {
    // Try multiple search variations
    final searchQueries = [
      attractionName,
      '$attractionName $cityName',
      '$attractionName temple',
      '$attractionName india',
    ];

    for (final query in searchQueries) {
      try {
        final wikipediaUrl = 'https://en.wikipedia.org/w/api.php';
        
        // Search for the page
        final searchUrl = Uri.parse(
          '$wikipediaUrl?action=query&format=json&list=search&srsearch=${Uri.encodeQueryComponent(query)}&srlimit=3&origin=*'
        );

        final searchResponse = await _client.get(searchUrl).timeout(const Duration(seconds: 5));

        if (searchResponse.statusCode == 200) {
          final searchData = jsonDecode(searchResponse.body) as Map<String, dynamic>;
          final searchResults = searchData['query']?['search'] as List<dynamic>?;
          
          if (searchResults != null && searchResults.isNotEmpty) {
            // Try each search result
            for (final result in searchResults) {
              final pageTitle = result['title'] as String;
              
              // Get the page image
              final imageUrl = Uri.parse(
                '$wikipediaUrl?action=query&format=json&prop=pageimages&piprop=original&titles=${Uri.encodeQueryComponent(pageTitle)}&origin=*'
              );

              final imageResponse = await _client.get(imageUrl).timeout(const Duration(seconds: 5));

              if (imageResponse.statusCode == 200) {
                final imageData = jsonDecode(imageResponse.body) as Map<String, dynamic>;
                final pages = imageData['query']?['pages'] as Map<String, dynamic>?;
                
                if (pages != null) {
                  for (final page in pages.values) {
                    final original = page['original'] as Map<String, dynamic>?;
                    final imageUrl = original?['source'] as String?;
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      print('Found image for $attractionName: $imageUrl');
                      return [imageUrl];
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching images from Wikipedia for query "$query": $e');
        continue;
      }
    }

    // Fallback: Use seeded placeholder images
    print('No Wikipedia image found for $attractionName, using placeholder');
    return [
      'https://picsum.photos/seed/${attractionName.hashCode}/800/600',
    ];
  }

  String _determineCategory(Map<String, dynamic> tags) {
    if (tags.containsKey('tourism')) {
      final tourism = tags['tourism'] as String;
      if (tourism == 'museum') return 'Museum';
      if (tourism == 'attraction') return 'Attraction';
      if (tourism == 'viewpoint') return 'Nature';
    }
    if (tags.containsKey('historic')) return 'Historical';
    if (tags.containsKey('amenity') && tags['amenity'] == 'place_of_worship') return 'Religious';
    if (tags.containsKey('natural')) return 'Nature';
    return 'Attraction';
  }

  double _estimateTicketPrice(String category, Map<String, dynamic> tags) {
    // Check if free entry is mentioned
    final fee = tags['fee'] as String?;
    if (fee == 'no') return 0;

    // Estimate based on category
    switch (category) {
      case 'Museum':
        return 150;
      case 'Historical':
        return 100;
      case 'Religious':
        return 0;
      case 'Nature':
        return 50;
      default:
        return 100;
    }
  }

  bool _isKidFriendly(String category) {
    // Most attractions are kid-friendly
    return true;
  }

  /// Fallback attractions when API fails
  List<Attraction> _generateFallbackAttractions(String cityName) {
    final hash = cityName.hashCode.abs();
    final random = hash % 100;
    
    return [
      Attraction(
        id: 'fb${hash}1',
        name: '$cityName City Museum',
        description: 'Explore the rich history and culture of $cityName',
        location: cityName,
        ticketPrice: 100 + (random % 200).toDouble(),
        rating: 4.0 + (random % 10) / 10,
        images: ['https://picsum.photos/seed/${cityName}museum/800/600'],
        category: 'Museum',
        isKidFriendly: true,
      ),
      Attraction(
        id: 'fb${hash}2',
        name: '$cityName Central Park',
        description: 'Beautiful green space perfect for families',
        location: cityName,
        ticketPrice: 0,
        rating: 4.2 + (random % 8) / 10,
        images: ['https://picsum.photos/seed/${cityName}park/800/600'],
        category: 'Nature',
        isKidFriendly: true,
      ),
      Attraction(
        id: 'fb${hash}3',
        name: '$cityName Heritage Site',
        description: 'Historic landmark showcasing local architecture',
        location: cityName,
        ticketPrice: (50 + (random % 150)).toDouble(),
        rating: 4.1 + (random % 9) / 10,
        images: ['https://picsum.photos/seed/${cityName}heritage/800/600'],
        category: 'Historical',
        isKidFriendly: true,
      ),
    ];
  }
}

// Made with Bob
