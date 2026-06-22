import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/toll_plaza_model.dart';
import '../models/route_model.dart';

/// Service for loading and querying toll plaza data.
/// Follows singleton pattern per AGENTS.md.
class TollService {
  static final TollService _instance = TollService._internal();
  factory TollService() => _instance;
  TollService._internal();

  static const _cacheKey = 'toll_plazas_cache';
  static const _cacheVersionKey = 'toll_plazas_version';
  static const _assetVersion = '1.1';

  List<TollPlaza> _plazas = [];
  bool _initialized = false;

  /// Load toll plaza data from bundled asset (cached in SharedPreferences).
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedVersion = prefs.getString(_cacheVersionKey);

      if (cachedVersion == _assetVersion) {
        final cached = prefs.getString(_cacheKey);
        if (cached != null) {
          _plazas = _parsePlazas(jsonDecode(cached) as Map<String, dynamic>);
          _initialized = true;
          developer.log(
            'TollService: loaded ${_plazas.length} plazas from cache',
            name: 'TollService',
          );
          return;
        }
      }

      // Load from bundled asset
      final raw = await rootBundle.loadString('assets/toll_plazas.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _plazas = _parsePlazas(data);

      // Persist to cache
      await prefs.setString(_cacheKey, raw);
      await prefs.setString(_cacheVersionKey, _assetVersion);

      _initialized = true;
      developer.log(
        'TollService: loaded ${_plazas.length} plazas from asset',
        name: 'TollService',
      );
    } catch (e) {
      developer.log(
        'TollService: init error – $e',
        name: 'TollService',
        error: e,
      );
      _initialized = true; // prevent retry loops
    }
  }

  /// Find toll plazas that lie within [maxDistanceKm] of any point on the route.
  /// Uses a simple bounding-box pre-filter then Haversine for accuracy.
  Future<List<TollPlaza>> getTollPlazasOnRoute(
    RouteDetails route, {
    double maxDistanceKm = 35.0,
  }) async {
    await initialize();

    if (_plazas.isEmpty) return [];

    final points = route.polylinePoints;
    if (points.isEmpty) {
      developer.log(
        'TollService: no polyline points — cannot match plazas for '
        '${route.origin} → ${route.destination}',
        name: 'TollService',
      );
      return [];
    }

    final result = <TollPlaza>[];
    for (final plaza in _plazas) {
      for (final point in points) {
        final d = _haversineKm(
          plaza.location.latitude,
          plaza.location.longitude,
          point.latitude,
          point.longitude,
        );
        if (d <= maxDistanceKm) {
          result.add(plaza);
          break; // already close enough to the route
        }
      }
    }

    developer.log(
      'TollService: matched ${result.length}/${_plazas.length} plazas '
      'from ${points.length} polyline points (radius: ${maxDistanceKm}km)',
      name: 'TollService',
    );

    // Sort by distance from origin
    result.sort((a, b) =>
        a.distanceFromOriginKm.compareTo(b.distanceFromOriginKm));
    return result;
  }

  /// Sum toll charges for a list of plazas for the given vehicle type.
  double calculateTollCost(
    List<TollPlaza> plazas,
    TollVehicleType vehicleType,
  ) {
    return plazas.fold(0.0, (sum, p) => sum + p.chargeFor(vehicleType));
  }

  /// Return the nearest toll plaza to [location], or null if none loaded.
  TollPlaza? getNearestTollPlaza(LatLng location) {
    if (_plazas.isEmpty) return null;

    TollPlaza? nearest;
    double minDist = double.infinity;
    for (final plaza in _plazas) {
      final d = _haversineKm(
        plaza.location.latitude,
        plaza.location.longitude,
        location.latitude,
        location.longitude,
      );
      if (d < minDist) {
        minDist = d;
        nearest = plaza;
      }
    }
    return nearest;
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  List<TollPlaza> _parsePlazas(Map<String, dynamic> data) {
    final list = data['toll_plazas'] as List<dynamic>? ?? [];
    return list
        .map((e) => TollPlaza.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_rad(lat1)) * _cos(_rad(lat2)) * _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _asin(_sqrt(a));
    return r * c;
  }

  static const _pi = 3.141592653589793;
  double _rad(double deg) => deg * _pi / 180.0;

  double _sin(double x) {
    double r = 0, t = x;
    for (int n = 1; n <= 10; n++) {
      r += t;
      t *= -x * x / ((2 * n) * (2 * n + 1));
    }
    return r;
  }

  double _cos(double x) {
    double r = 0, t = 1;
    for (int n = 1; n <= 10; n++) {
      r += t;
      t *= -x * x / ((2 * n - 1) * (2 * n));
    }
    return r;
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double g = x / 2;
    for (int i = 0; i < 10; i++) { g = (g + x / g) / 2; }
    return g;
  }

  double _asin(double x) {
    x = x.clamp(-1.0, 1.0);
    double r = 0, t = x, xSq = x * x;
    for (int n = 0; n < 10; n++) {
      r += t / (2 * n + 1);
      t *= xSq * (2 * n + 1) * (2 * n + 1) / ((2 * n + 2) * (2 * n + 3));
    }
    return r;
  }
}

// Made with Bob
