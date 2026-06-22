import 'dart:convert';
import 'dart:developer' as developer;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/fuel_station_model.dart';
import '../models/route_model.dart';
import '../models/vehicle_profile_model.dart';
import 'pricing_service.dart';

/// Service for finding fuel stations using OpenStreetMap Overpass API.
/// Follows singleton pattern per AGENTS.md.
class FuelStationService {
  static final FuelStationService _instance = FuelStationService._internal();
  factory FuelStationService() => _instance;
  FuelStationService._internal();

  final PricingService _pricingService = PricingService();
  final http.Client _client = http.Client();

  // Simple in-memory cache: key = "lat,lon,radius"
  final Map<String, List<FuelStation>> _cache = {};

  /// Find fuel stations within [radiusKm] of [location] using Overpass API.
  Future<List<FuelStation>> findNearbyStations(
    LatLng location,
    double radiusKm,
  ) async {
    final radiusM = (radiusKm * 1000).round();
    final cacheKey =
        '${location.latitude.toStringAsFixed(3)},${location.longitude.toStringAsFixed(3)},$radiusM';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final stations = await _queryOverpass(location, radiusM);
      _cache[cacheKey] = stations;
      return stations;
    } catch (e) {
      developer.log(
        'FuelStationService: Overpass query failed – $e',
        name: 'FuelStationService',
        error: e,
      );
      return [];
    }
  }

  /// Find fuel stations within [maxDistanceKm] of the route polyline.
  /// Samples the polyline every ~50 km and aggregates unique results.
  Future<List<FuelStation>> getFuelStationsOnRoute(
    RouteDetails route, {
    double maxDistanceKm = 5.0,
  }) async {
    final points = route.polylinePoints;

    if (points.isEmpty) {
      developer.log(
        'FuelStationService: no polyline points – returning empty list',
        name: 'FuelStationService',
      );
      return [];
    }

    // Sample every Nth point to limit API calls
    final step = (points.length / 5).ceil().clamp(1, points.length);
    final samplePoints = <LatLng>[];
    for (int i = 0; i < points.length; i += step) {
      samplePoints.add(points[i]);
    }
    if (points.length > 1) samplePoints.add(points.last);

    final seen = <String>{};
    final stations = <FuelStation>[];

    for (final pt in samplePoints) {
      final nearby = await findNearbyStations(pt, maxDistanceKm);
      for (final s in nearby) {
        if (seen.add(s.id)) {
          stations.add(s);
        }
      }
    }

    // Sort by distance from route start
    stations.sort(
        (a, b) => a.distanceFromRouteKm.compareTo(b.distanceFromRouteKm));
    return stations;
  }

  /// Suggest optimal refueling stops for the vehicle profile.
  /// Returns stations where the driver should refuel (tank < 25 %).
  Future<List<FuelStation>> getOptimalRefuelingStops(
    RouteDetails route,
    VehicleProfile vehicle,
    List<FuelStation> stationsOnRoute,
  ) async {
    final rangeKm =
        vehicle.fuelTankCapacityLiters * vehicle.averageMileageKmpl;
    final safeRangeKm = rangeKm * 0.75; // refuel before 25 % remaining

    final stops = <FuelStation>[];
    double distanceSinceLastFuel = 0;

    for (final station in stationsOnRoute) {
      distanceSinceLastFuel += station.distanceFromRouteKm;
      if (distanceSinceLastFuel >= safeRangeKm) {
        stops.add(station);
        distanceSinceLastFuel = 0;
      }
    }

    return stops;
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<List<FuelStation>> _queryOverpass(
    LatLng center,
    int radiusMeters,
  ) async {
    final lat = center.latitude;
    final lon = center.longitude;

    // Overpass QL query for fuel stations (amenity=fuel)
    final query = '[out:json][timeout:15];'
        'node["amenity"="fuel"](around:$radiusMeters,$lat,$lon);'
        'out body;';

    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    final response = await _client
        .post(url, body: {'data': query})
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Overpass API ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>? ?? [];

    // Get fuel price for this region (approximate from lat/lon → city)
    final cityHint = _latLonToRegionHint(lat, lon);
    final petrolPrice = await _pricingService.getFuelPrice(cityHint);
    final dieselPrice = petrolPrice * 0.88; // diesel ≈ 88 % of petrol

    return elements.map((e) {
      final el = e as Map<String, dynamic>;
      final tags = el['tags'] as Map<String, dynamic>? ?? {};
      final elLat = (el['lat'] as num).toDouble();
      final elLon = (el['lon'] as num).toDouble();
      final id = el['id'].toString();
      final name = tags['name'] as String? ??
          tags['brand'] as String? ??
          'Fuel Station';
      final brand = tags['brand'] as String? ?? 'Unknown';

      return FuelStation(
        id: id,
        name: name,
        brand: brand,
        location: LatLng(elLat, elLon),
        prices: FuelPrices(petrol: petrolPrice, diesel: dieselPrice),
        isOpen24x7: tags['opening_hours'] == '24/7',
        amenities: _extractAmenities(tags),
      );
    }).toList();
  }

  List<String> _extractAmenities(Map<String, dynamic> tags) {
    final amenities = <String>[];
    if (tags['amenity:toilets'] == 'yes' || tags['toilets'] == 'yes') {
      amenities.add('Restroom');
    }
    if (tags['shop'] == 'convenience') amenities.add('Convenience Store');
    if (tags['amenity:atm'] == 'yes' || tags['atm'] == 'yes') {
      amenities.add('ATM');
    }
    if (tags['car_wash'] == 'yes') amenities.add('Car Wash');
    return amenities;
  }

  /// Very rough region hint from lat/lon for PricingService
  String _latLonToRegionHint(double lat, double lon) {
    if (lat > 28.0 && lon > 76.5 && lon < 78.0) return 'Delhi';
    if (lat > 18.5 && lat < 20.0 && lon > 72.5 && lon < 74.0) return 'Mumbai';
    if (lat > 12.5 && lat < 13.5 && lon > 77.0 && lon < 78.0) return 'Bangalore';
    if (lat > 12.8 && lat < 13.5 && lon > 79.5 && lon < 81.0) return 'Chennai';
    if (lat > 17.0 && lat < 18.0 && lon > 78.0 && lon < 79.0) return 'Hyderabad';
    if (lat > 22.0 && lat < 23.5 && lon > 72.5 && lon < 73.5) return 'Ahmedabad';
    return 'India';
  }
}

// Made with Bob
