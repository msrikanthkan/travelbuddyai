import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// PlacesService using OpenStreetMap Nominatim API (free, no API key required)
class PlacesService {
  // Using Nominatim API - free and open source, no API key needed
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  final http.Client _client;

  PlacesService([http.Client? client]) : _client = client ?? http.Client();

  Future<List<String>> searchPlaceSuggestions(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return [];

    try {
      // Nominatim API parameters - removed invalid featuretype parameter
      final url = Uri.parse(
        '$_baseUrl?q=${Uri.encodeQueryComponent(trimmed)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=10'
      );

      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'TravelBuddyAI/1.0', // Required by Nominatim usage policy
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('Nominatim API returned status ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      
      if (data is! List) {
        return [];
      }
      
      // Extract display names from results
      final suggestions = data
          .cast<Map<String, dynamic>>()
          .map((item) => item['display_name'] as String? ?? '')
          .where((text) => text.isNotEmpty)
          .take(10)
          .toList();

      return suggestions;
    } catch (e) {
      // Return empty list on error instead of throwing
      return [];
    }
  }
}
