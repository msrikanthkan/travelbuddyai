import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_trip_model.dart';

class SavedTripsService {
  static const String _tripsKey = 'saved_trips';
  static const int _maxTrips = 50;

  /// Get all saved trips
  static Future<List<SavedTrip>> getAllTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tripsJson = prefs.getString(_tripsKey);
      
      if (tripsJson == null || tripsJson.isEmpty) {
        return [];
      }

      final List<dynamic> tripsList = json.decode(tripsJson);
      return tripsList
          .map((json) => SavedTrip.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by newest first
    } catch (e) {
      print('Error loading trips: $e');
      return [];
    }
  }

  /// Save a new trip
  static Future<bool> saveTrip(SavedTrip trip) async {
    try {
      final trips = await getAllTrips();
      
      // Check if max limit reached
      if (trips.length >= _maxTrips) {
        throw Exception('Maximum trip limit ($_maxTrips) reached. Please delete some trips first.');
      }

      // Check if trip with same ID already exists
      final existingIndex = trips.indexWhere((t) => t.id == trip.id);
      if (existingIndex != -1) {
        // Update existing trip
        trips[existingIndex] = trip;
      } else {
        // Add new trip
        trips.add(trip);
      }

      return await _saveTrips(trips);
    } catch (e) {
      print('Error saving trip: $e');
      return false;
    }
  }

  /// Update an existing trip
  static Future<bool> updateTrip(SavedTrip trip) async {
    try {
      final trips = await getAllTrips();
      final index = trips.indexWhere((t) => t.id == trip.id);
      
      if (index == -1) {
        throw Exception('Trip not found');
      }

      trips[index] = trip;
      return await _saveTrips(trips);
    } catch (e) {
      print('Error updating trip: $e');
      return false;
    }
  }

  /// Delete a trip
  static Future<bool> deleteTrip(String tripId) async {
    try {
      final trips = await getAllTrips();
      trips.removeWhere((trip) => trip.id == tripId);
      return await _saveTrips(trips);
    } catch (e) {
      print('Error deleting trip: $e');
      return false;
    }
  }

  /// Get a specific trip by ID
  static Future<SavedTrip?> getTripById(String tripId) async {
    try {
      final trips = await getAllTrips();
      return trips.firstWhere(
        (trip) => trip.id == tripId,
        orElse: () => throw Exception('Trip not found'),
      );
    } catch (e) {
      print('Error getting trip: $e');
      return null;
    }
  }

  /// Get trips by destination
  static Future<List<SavedTrip>> getTripsByDestination(String destination) async {
    final trips = await getAllTrips();
    return trips.where((trip) => 
      trip.destination.toLowerCase().contains(destination.toLowerCase())
    ).toList();
  }

  /// Get trips by occasion
  static Future<List<SavedTrip>> getTripsByOccasion(String occasion) async {
    final trips = await getAllTrips();
    return trips.where((trip) => trip.occasion == occasion).toList();
  }

  /// Get upcoming trips (trips with start date in the future)
  static Future<List<SavedTrip>> getUpcomingTrips() async {
    final trips = await getAllTrips();
    final now = DateTime.now();
    return trips.where((trip) => 
      trip.startDate != null && trip.startDate!.isAfter(now)
    ).toList()
      ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
  }

  /// Get past trips
  static Future<List<SavedTrip>> getPastTrips() async {
    final trips = await getAllTrips();
    final now = DateTime.now();
    return trips.where((trip) => 
      trip.endDate != null && trip.endDate!.isBefore(now)
    ).toList()
      ..sort((a, b) => b.endDate!.compareTo(a.endDate!));
  }

  /// Clear all trips (use with caution)
  static Future<bool> clearAllTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_tripsKey);
    } catch (e) {
      print('Error clearing trips: $e');
      return false;
    }
  }

  /// Get trip count
  static Future<int> getTripCount() async {
    final trips = await getAllTrips();
    return trips.length;
  }

  /// Check if storage limit is reached
  static Future<bool> isStorageLimitReached() async {
    final count = await getTripCount();
    return count >= _maxTrips;
  }

  /// Private helper to save trips list
  static Future<bool> _saveTrips(List<SavedTrip> trips) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripsJson = json.encode(trips.map((trip) => trip.toJson()).toList());
      return await prefs.setString(_tripsKey, tripsJson);
    } catch (e) {
      print('Error saving trips to storage: $e');
      return false;
    }
  }

  /// Generate a unique ID for a new trip
  static String generateTripId() {
    return 'trip_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Export trips as JSON string (for backup)
  static Future<String> exportTrips() async {
    final trips = await getAllTrips();
    return json.encode(trips.map((trip) => trip.toJson()).toList());
  }

  /// Import trips from JSON string (for restore)
  static Future<bool> importTrips(String tripsJson) async {
    try {
      final List<dynamic> tripsList = json.decode(tripsJson);
      final trips = tripsList
          .map((json) => SavedTrip.fromJson(json as Map<String, dynamic>))
          .toList();
      return await _saveTrips(trips);
    } catch (e) {
      print('Error importing trips: $e');
      return false;
    }
  }
}

// Made with Bob
