import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/itinerary_day_model.dart';
import 'real_hotels_data.dart';

class HotelService {
  final http.Client _client;
  
  // Firebase Cloud Function URL for hotel search
  static const String _firebaseFunctionUrl = 'https://searchhotels-i57v6hnxaa-el.a.run.app';
  
  // Fallback: Google Places API key (for direct calls if needed)
  static const String _googlePlacesApiKey = 'AIzaSyDR0ASsQnR8XGH_5w0alG2jDVpHkkNZkWc';

  HotelService([http.Client? client]) : _client = client ?? http.Client();

  /// Search for real hotels using Firebase Cloud Function (Google Places API)
  Future<List<Accommodation>> searchHotels({
    required String destination,
    required double maxBudget,
    int limit = 3,
  }) async {
    try {
      print('🔍 Fetching hotels from Firebase Function for $destination...');
      
      // Call Firebase Cloud Function
      final uri = Uri.parse(_firebaseFunctionUrl).replace(
        queryParameters: {
          'destination': destination,
          'maxBudget': maxBudget.toString(),
        },
      );
      
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Firebase Function timeout, using curated data');
          throw Exception('Timeout');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('📊 Parsed data: $data');
        
        if (data['success'] == true && data['hotels'] != null) {
          final hotelsList = data['hotels'] as List;
          
          if (hotelsList.isEmpty) {
            print('⚠️ Hotels list is empty');
            throw Exception('No hotels in response');
          }
          
          final hotels = hotelsList
              .take(limit)
              .map((hotel) => _convertToAccommodation(hotel, maxBudget))
              .toList();
          
          print('✅ Got ${hotels.length} hotels from Firebase Function');
          return hotels;
        } else {
          print('⚠️ Response format unexpected: success=${data['success']}, hotels=${data['hotels']}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
      
      print('⚠️ Firebase Function returned no usable results, using curated data');
      throw Exception('No hotels found');
      
    } catch (e) {
      print('❌ Error fetching from Firebase Function: $e');
      print('📚 Falling back to curated database');
      
      // Fallback to curated database
      if (RealHotelsData.hasDataForDestination(destination)) {
        return _getRealHotelsFromDatabase(destination, maxBudget, limit);
      }
      
      // Final fallback
      return _getFallbackHotels(destination, maxBudget);
    }
  }

  /// Convert Firebase Function hotel data to Accommodation model
  Accommodation _convertToAccommodation(Map<String, dynamic> hotel, double maxBudget) {
    final name = hotel['name'] as String;
    final rating = (hotel['rating'] as num?)?.toDouble() ?? 3.5;
    final address = hotel['address'] as String? ?? 'Address not available';
    final priceLevel = hotel['priceLevel'] as int?;
    
    // Estimate price based on price level (1-4 scale from Google)
    double estimatedPrice;
    String type;
    
    if (priceLevel == null || priceLevel <= 1) {
      estimatedPrice = maxBudget * 0.4;
      type = 'Budget Hotel';
    } else if (priceLevel == 2) {
      estimatedPrice = maxBudget * 0.6;
      type = 'Mid-range Hotel';
    } else if (priceLevel == 3) {
      estimatedPrice = maxBudget * 0.8;
      type = 'Upscale Hotel';
    } else {
      estimatedPrice = maxBudget * 0.95;
      type = 'Luxury Hotel';
    }
    
    // Generate booking URL
    final bookingUrl = _generateBookingUrl(name, address, estimatedPrice);
    
    return Accommodation(
      name: name,
      type: type,
      costPerNight: estimatedPrice,
      address: address,
      rating: rating,
      bookingUrl: bookingUrl,
    );
  }

  /// Get real hotels from curated database
  List<Accommodation> _getRealHotelsFromDatabase(
    String destination,
    double maxBudget,
    int limit,
  ) {
    final hotelsData = RealHotelsData.getHotelsForDestination(destination, maxBudget);
    
    if (hotelsData.isEmpty) {
      return _getFallbackHotels(destination, maxBudget);
    }

    final hotels = <Accommodation>[];
    
    for (var hotelData in hotelsData.take(limit)) {
      final estimatedPrice = _estimatePriceFromRange(
        hotelData['priceRange'] as String,
        maxBudget,
      );
      
      hotels.add(Accommodation(
        name: hotelData['name'] as String,
        type: hotelData['type'] as String,
        costPerNight: estimatedPrice,
        address: hotelData['address'] as String,
        rating: (hotelData['rating'] as num).toDouble(),
        bookingUrl: hotelData['bookingUrl'] as String,
      ));
      
      print('   📍 Real Hotel: ${hotelData['name']} (${hotelData['rating']}⭐)');
    }
    
    return hotels;
  }

  /// Estimate price based on price range category
  double _estimatePriceFromRange(String priceRange, double maxBudget) {
    switch (priceRange) {
      case 'luxury':
        return maxBudget * 0.85;
      case 'mid':
        return maxBudget * 0.65;
      case 'budget':
        return maxBudget * 0.45;
      default:
        return maxBudget * 0.6;
    }
  }

  /// Estimate hotel price based on rating and budget
  double _estimatePrice(double rating, double maxBudget) {
    if (rating >= 4.5) {
      return maxBudget * 0.8; // Luxury: 80% of budget
    } else if (rating >= 3.5) {
      return maxBudget * 0.6; // Mid-range: 60% of budget
    } else {
      return maxBudget * 0.4; // Budget: 40% of budget
    }
  }

  /// Generate booking URL based on hotel type
  String _generateBookingUrl(String hotelName, String address, double price) {
    // Extract city name from address (usually the last part before country)
    String cityName = _extractCityFromAddress(address);
    
    // Clean hotel name for URL
    final cleanHotelName = Uri.encodeComponent(hotelName);
    final cleanCity = Uri.encodeComponent(cityName);
    
    if (price < 2000) {
      // OYO Rooms - search by hotel name and city
      return 'https://www.oyorooms.com/search/?location=$cleanCity&searchText=$cleanHotelName';
    } else if (price < 5000) {
      // MakeMyTrip - search by hotel name
      return 'https://www.makemytrip.com/hotels/hotel-listing/?city=$cleanCity&checkin=&checkout=&roomStayQualifier=&locusId=&country=IN&locusType=city&searchText=$cleanHotelName';
    } else {
      // Booking.com - search by hotel name and city
      return 'https://www.booking.com/searchresults.html?ss=$cleanHotelName+$cleanCity';
    }
  }

  /// Extract city name from full address
  String _extractCityFromAddress(String address) {
    // Remove country name (usually "India" at the end)
    String cleaned = address.replaceAll(', India', '').replaceAll(' India', '');
    
    // Split by comma and get the last meaningful part (usually city)
    final parts = cleaned.split(',').map((s) => s.trim()).toList();
    
    // Try to find the city (usually second to last or last part)
    if (parts.length >= 2) {
      // Check if last part is a state/region, if so use second to last
      final lastPart = parts.last.toLowerCase();
      if (lastPart.contains('goa') || lastPart.contains('karnataka') ||
          lastPart.contains('kerala') || lastPart.contains('maharashtra') ||
          lastPart.contains('rajasthan') || lastPart.contains('delhi') ||
          lastPart.contains('himachal')) {
        return parts[parts.length - 2];
      }
      return parts.last;
    }
    
    return parts.isNotEmpty ? parts.first : address;
  }

  /// Fallback hotels when API is not available or fails
  List<Accommodation> _getFallbackHotels(String destination, double maxBudget) {
    String type;
    String name;
    double rating;
    String bookingUrl;
    
    if (maxBudget < 2000) {
      type = 'Budget Hotel';
      name = '$destination Budget Inn';
      rating = 3.5;
      bookingUrl = 'https://www.oyorooms.com/search/?location=${Uri.encodeComponent(destination)}&price_max=2000';
    } else if (maxBudget < 5000) {
      type = 'Mid-range Hotel';
      name = '$destination Comfort Hotel';
      rating = 4.0;
      bookingUrl = 'https://www.makemytrip.com/hotels/hotel-listing/?city=${Uri.encodeComponent(destination)}&price_max=5000';
    } else {
      type = 'Luxury Resort';
      name = '$destination Grand Resort';
      rating = 4.5;
      bookingUrl = 'https://www.booking.com/searchresults.html?ss=${Uri.encodeComponent(destination)}&price_min=5000';
    }
    
    return [
      Accommodation(
        name: name,
        type: type,
        costPerNight: maxBudget,
        address: 'Central $destination',
        rating: rating,
        bookingUrl: bookingUrl,
      ),
    ];
  }
}

// Made with Bob
