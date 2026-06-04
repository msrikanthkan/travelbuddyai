import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class MapsService {
  static const _apiKey = '<YOUR_GOOGLE_MAPS_API_KEY>'; // Replace with your own API key

  Future<double?> getDistanceKm(String origin, String destination) async {
    final originEncoded = Uri.encodeComponent(origin);
    final destinationEncoded = Uri.encodeComponent(destination);
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=$originEncoded&destinations=$destinationEncoded&key=$_apiKey&mode=driving',
    );

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Maps API request timed out'),
      );
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK') return null;

      final rows = data['rows'] as List<dynamic>?;
      if (rows == null || rows.isEmpty) return null;

      final elements = rows[0]['elements'] as List<dynamic>?;
      if (elements == null || elements.isEmpty) return null;

      final element = elements[0] as Map<String, dynamic>;
      final elementStatus = element['status'] as String?;
      if (elementStatus != 'OK') return null;

      final distance = element['distance'] as Map<String, dynamic>?;
      if (distance == null) return null;

      final meters = distance['value'] as int?;
      if (meters == null) return null;

      return meters / 1000.0;
    } catch (e) {
      return null;
    }
  }
}
