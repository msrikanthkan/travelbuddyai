import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class PlacesService {
  static const _apiKey = '<YOUR_GOOGLE_MAPS_API_KEY>'; // Replace with your own API key
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  final http.Client _client;

  PlacesService([http.Client? client]) : _client = client ?? http.Client();

  Future<List<String>> searchPlaceSuggestions(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return [];

    final url = Uri.parse('$_baseUrl?input=${Uri.encodeQueryComponent(trimmed)}&types=(cities)&key=$_apiKey');
    final response = await _client.get(url).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Places API returned status ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String?;
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final errorMessage = data['error_message'] as String?;
      throw Exception('Places API error: $status${errorMessage != null ? ' - $errorMessage' : ''}');
    }

    final predictions = (data['predictions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return predictions.map((item) => item['description'] as String? ?? '').where((text) => text.isNotEmpty).toList();
  }
}
