import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/destination_model.dart';

class DestinationsLoaderService {
  static List<Destination>? _cachedDestinations;

  /// Load all destinations from JSON file
  static Future<List<Destination>> loadDestinations() async {
    if (_cachedDestinations != null) {
      return _cachedDestinations!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/destinations.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> destinationsJson = jsonData['destinations'] as List;

      _cachedDestinations = destinationsJson
          .map((json) => Destination.fromJson(json as Map<String, dynamic>))
          .toList();

      return _cachedDestinations!;
    } catch (e) {
      print('Error loading destinations: $e');
      return [];
    }
  }

  /// Filter destinations by occasion type and budget range
  static Future<List<Destination>> getFilteredDestinations({
    required String occasionType,
    required String budgetRange,
  }) async {
    final allDestinations = await loadDestinations();

    return allDestinations.where((destination) {
      final matchesOccasion = destination.occasionTypes.contains(occasionType.toLowerCase());
      final matchesBudget = destination.budgetRange == budgetRange.toLowerCase();
      return matchesOccasion && matchesBudget;
    }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating)); // Sort by rating descending
  }

  /// Get destinations by budget amount (not range)
  static Future<List<Destination>> getDestinationsByBudget({
    required String occasionType,
    required int budgetAmount,
  }) async {
    final allDestinations = await loadDestinations();

    return allDestinations.where((destination) {
      final matchesOccasion = destination.occasionTypes.contains(occasionType.toLowerCase());
      final withinBudget = destination.estimatedCost <= budgetAmount;
      return matchesOccasion && withinBudget;
    }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating)); // Sort by rating descending
  }

  /// Get budget range from amount
  static String getBudgetRangeFromAmount(int amount) {
    if (amount < 15000) {
      return 'budget';
    } else if (amount < 40000) {
      return 'mid';
    } else {
      return 'luxury';
    }
  }

  /// Search destinations by name
  static Future<List<Destination>> searchDestinations(String query) async {
    if (query.isEmpty) return [];

    final allDestinations = await loadDestinations();
    final lowerQuery = query.toLowerCase();

    return allDestinations.where((destination) {
      return destination.name.toLowerCase().contains(lowerQuery) ||
          destination.state.toLowerCase().contains(lowerQuery) ||
          destination.description.toLowerCase().contains(lowerQuery);
    }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  /// Get top rated destinations for an occasion
  static Future<List<Destination>> getTopDestinations({
    required String occasionType,
    int limit = 5,
  }) async {
    final allDestinations = await loadDestinations();

    final filtered = allDestinations.where((destination) {
      return destination.occasionTypes.contains(occasionType.toLowerCase());
    }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return filtered.take(limit).toList();
  }

  /// Clear cache (useful for testing or updates)
  static void clearCache() {
    _cachedDestinations = null;
  }
}

// Made with Bob
