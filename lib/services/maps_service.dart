import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;

import 'package:http/http.dart' as http;

/// MapsService using OpenStreetMap Nominatim for geocoding and OSRM for routing
/// Both are free and open source, no API key required
class MapsService {
  // Nominatim for geocoding (converting place names to coordinates)
  static const _geocodeUrl = 'https://nominatim.openstreetmap.org/search';
  
  // OSRM for routing and distance calculation
  static const _routeUrl = 'https://router.project-osrm.org/route/v1/driving';

  Future<double?> getDistanceKm(String origin, String destination) async {
    try {
      // Step 1: Geocode origin and destination to get coordinates
      final originCoords = await _geocodePlace(origin);
      if (originCoords == null) return null;

      final destCoords = await _geocodePlace(destination);
      if (destCoords == null) return null;

      // Step 2: Get route distance using OSRM
      final distance = await _getRouteDistance(originCoords, destCoords);
      return distance;
    } catch (e) {
      // Fallback to straight-line distance if routing fails
      try {
        final originCoords = await _geocodePlace(origin);
        final destCoords = await _geocodePlace(destination);
        if (originCoords != null && destCoords != null) {
          return _calculateHaversineDistance(
            originCoords['lat']!,
            originCoords['lon']!,
            destCoords['lat']!,
            destCoords['lon']!,
          );
        }
      } catch (_) {}
      return null;
    }
  }

  /// Geocode a place name to coordinates using Nominatim
  Future<Map<String, double>?> _geocodePlace(String place) async {
    final url = Uri.parse(
      '$_geocodeUrl?q=${Uri.encodeQueryComponent(place)}'
      '&format=json'
      '&limit=1'
    );

    final response = await http.get(
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
  }

  /// Get driving route distance using OSRM
  Future<double?> _getRouteDistance(
    Map<String, double> origin,
    Map<String, double> destination,
  ) async {
    final url = Uri.parse(
      '$_routeUrl/${origin['lon']},${origin['lat']};${destination['lon']},${destination['lat']}'
      '?overview=false'
      '&alternatives=false'
      '&steps=false'
    );

    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('OSRM request timed out'),
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final code = data['code'] as String?;
    if (code != 'Ok') return null;

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;

    final route = routes[0] as Map<String, dynamic>;
    final distanceMeters = route['distance'] as num?;
    if (distanceMeters == null) return null;

    return distanceMeters / 1000.0; // Convert to kilometers
  }

  /// Calculate straight-line distance using Haversine formula (fallback)
  double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  double sin(double x) => _sin(x);
  double cos(double x) => _cos(x);
  double sqrt(double x) => _sqrt(x);
  double asin(double x) => _asin(x);
  
  static const pi = 3.141592653589793;
  
  double _sin(double x) {
    // Taylor series approximation for sin
    double result = 0;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      result += term;
      term *= -x * x / ((2 * n) * (2 * n + 1));
    }
    return result;
  }
  
  double _cos(double x) {
    // Taylor series approximation for cos
    double result = 0;
    double term = 1;
    for (int n = 1; n <= 10; n++) {
      result += term;
      term *= -x * x / ((2 * n - 1) * (2 * n));
    }
    return result;
  }
  
  double _sqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  
  double _asin(double x) {
    // Taylor series approximation for asin
    if (x < -1 || x > 1) return double.nan;
    double result = 0;
    double term = x;
    double xSquared = x * x;
    for (int n = 0; n < 10; n++) {
      result += term / (2 * n + 1);
      term *= xSquared * (2 * n + 1) * (2 * n + 1) / ((2 * n + 2) * (2 * n + 3));
    }
    return result;
  }
}
