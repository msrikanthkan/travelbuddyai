import 'dart:convert';
import 'package:http/http.dart' as http;
import 'openweather_service.dart';

class DestinationInsight {
  final String type;
  final String title;
  final String subtitle;
  final String? value;
  final String? icon;
  final String? url;

  DestinationInsight({
    required this.type,
    required this.title,
    required this.subtitle,
    this.value,
    this.icon,
    this.url,
  });
}

class DestinationInsightsService {
  final http.Client _client;
  final OpenWeatherService _weatherService;

  DestinationInsightsService([http.Client? client, OpenWeatherService? weatherService])
      : _client = client ?? http.Client(),
        _weatherService = weatherService ?? OpenWeatherService();

  /// Get comprehensive insights for a destination (Hybrid: Real-time Weather + Curated Data)
  Future<List<DestinationInsight>> getDestinationInsights(String destination) async {
    final insights = <DestinationInsight>[];
    
    print('\n🔍 ========== Destination Insights Service ==========');
    print('📍 Destination: $destination');
    print('🔄 Mode: Hybrid (Real-time Weather + Curated Data)');
    print('====================================================\n');
    
    try {
      // Try to fetch real-time weather data from OpenWeatherMap
      print('⏳ Calling OpenWeatherMap API...');
      final weatherData = await _weatherService.getCurrentWeather(destination);
      print('📥 Weather API call completed');
      
      if (weatherData != null) {
        // Use real-time weather data
        insights.add(DestinationInsight(
          type: 'weather',
          title: '$destination weather',
          subtitle: weatherData.description.capitalize(),
          value: '${weatherData.temperature.toStringAsFixed(1)}°C',
          icon: weatherData.icon,
        ));
        
        insights.add(DestinationInsight(
          type: 'temperature',
          title: '$destination temperature',
          subtitle: 'Current: ${weatherData.temperature.toStringAsFixed(1)}°C',
          value: 'High: ${weatherData.tempMax.toStringAsFixed(1)}°C, Low: ${weatherData.tempMin.toStringAsFixed(1)}°C',
          icon: '🌡️',
        ));
        
        print('✅ Using real-time weather data from OpenWeatherMap');
      } else {
        // Fallback to curated weather data
        final weatherInsights = _getSimulatedInsights(destination);
        insights.add(weatherInsights.firstWhere((i) => i.type == 'weather'));
        insights.add(weatherInsights.firstWhere((i) => i.type == 'temperature'));
        print('⚠️ Using curated weather data (OpenWeatherMap unavailable)');
      }
      
      // Use curated data for other insights (hotels, tours, transport, food)
      final curatedInsights = _getSimulatedInsights(destination);
      insights.add(curatedInsights.firstWhere((i) => i.type == 'hotels'));
      insights.add(curatedInsights.firstWhere((i) => i.type == 'tour_package'));
      insights.add(curatedInsights.firstWhere((i) => i.type == 'distance'));
      insights.add(curatedInsights.firstWhere((i) => i.type == 'popular_times'));
      insights.add(curatedInsights.firstWhere((i) => i.type == 'transport'));
      insights.add(curatedInsights.firstWhere((i) => i.type == 'food'));
      
      print('✅ Fetched ${insights.length} insights (Hybrid mode)');
    } catch (e) {
      print('❌ Error fetching insights: $e');
      // Complete fallback to curated data
      return _getSimulatedInsights(destination);
    }
    
    return insights;
  }


  /// Fallback simulated data when API is not configured or fails
  List<DestinationInsight> _getSimulatedInsights(String destination) {
    final dest = destination.toLowerCase();
    
    return [
      DestinationInsight(
        type: 'weather',
        title: '$destination weather',
        subtitle: _getWeatherCondition(dest),
        value: '${_getTemperature(dest)}°C',
        icon: _getWeatherIcon(dest),
      ),
      DestinationInsight(
        type: 'hotels',
        title: '$destination hotels',
        subtitle: '${_getHotelCount(dest)} hotels available',
        value: 'From ₹${_getMinHotelPrice(dest)}',
        icon: '🏨',
      ),
      DestinationInsight(
        type: 'temperature',
        title: '$destination temperature',
        subtitle: 'Current: ${_getTemperature(dest)}°C',
        value: 'High: ${_getHighTemp(dest)}°C, Low: ${_getLowTemp(dest)}°C',
        icon: '🌡️',
      ),
      DestinationInsight(
        type: 'tour_package',
        title: '$destination tour package',
        subtitle: '${_getPackageCount(dest)} packages available',
        value: 'Starting ₹${_getMinPackagePrice(dest)}',
        icon: '🎫',
      ),
      DestinationInsight(
        type: 'distance',
        title: '$destination distance',
        subtitle: 'From your location',
        value: 'Calculate route',
        icon: '📍',
      ),
      DestinationInsight(
        type: 'popular_times',
        title: 'Best time to visit $destination',
        subtitle: _getBestSeason(dest),
        value: _getSeasonReason(dest),
        icon: '📅',
      ),
      DestinationInsight(
        type: 'transport',
        title: '$destination local transport',
        subtitle: _getTransportTypes(dest),
        value: 'Avg fare: ₹${_getAvgFare(dest)}',
        icon: '🚕',
      ),
      DestinationInsight(
        type: 'food',
        title: '$destination food & restaurants',
        subtitle: _getFoodSpecialty(dest),
        value: 'Avg meal: ₹${_getAvgMeal(dest)}',
        icon: '🍽️',
      ),
    ];
  }

  // Helper methods for simulated data
  String _getWeatherCondition(String dest) {
    if (dest.contains('manali') || dest.contains('shimla')) return 'Cold & Pleasant';
    if (dest.contains('goa') || dest.contains('mumbai')) return 'Warm & Humid';
    if (dest.contains('kerala') || dest.contains('ooty')) return 'Pleasant & Rainy';
    return 'Partly cloudy';
  }

  String _getWeatherIcon(String dest) {
    if (dest.contains('manali') || dest.contains('shimla')) return '❄️';
    if (dest.contains('goa') || dest.contains('mumbai')) return '☀️';
    if (dest.contains('kerala') || dest.contains('ooty')) return '🌧️';
    return '⛅';
  }

  String _getTemperature(String dest) {
    if (dest.contains('manali') || dest.contains('shimla')) return '15';
    if (dest.contains('goa') || dest.contains('mumbai')) return '28';
    return '25';
  }

  String _getHighTemp(String dest) {
    if (dest.contains('manali') || dest.contains('shimla')) return '18';
    if (dest.contains('goa') || dest.contains('mumbai')) return '32';
    return '30';
  }

  String _getLowTemp(String dest) {
    if (dest.contains('manali') || dest.contains('shimla')) return '8';
    if (dest.contains('goa') || dest.contains('mumbai')) return '24';
    return '20';
  }

  String _getHotelCount(String dest) {
    if (dest.contains('manali') || dest.contains('shimla')) return '150';
    if (dest.contains('goa')) return '300';
    if (dest.contains('delhi') || dest.contains('mumbai')) return '500';
    return '100';
  }

  String _getMinHotelPrice(String dest) {
    if (dest.contains('manali') || dest.contains('shimla')) return '1200';
    if (dest.contains('goa')) return '1500';
    if (dest.contains('delhi') || dest.contains('mumbai')) return '1000';
    return '800';
  }

  String _getPackageCount(String dest) {
    if (dest.contains('manali') || dest.contains('shimla')) return '25';
    if (dest.contains('goa')) return '40';
    return '15';
  }

  String _getMinPackagePrice(String dest) {
    if (dest.contains('manali') || dest.contains('shimla')) return '8000';
    if (dest.contains('goa')) return '12000';
    return '6000';
  }

  String _getBestSeason(String dest) {
    if (dest.contains('manali') || dest.contains('shimla')) return 'December to February';
    if (dest.contains('goa')) return 'November to February';
    if (dest.contains('kerala')) return 'September to March';
    return 'October to March';
  }

  String _getSeasonReason(String dest) {
    if (dest.contains('manali') || dest.contains('shimla')) return 'Snowfall season';
    if (dest.contains('goa')) return 'Pleasant weather';
    if (dest.contains('kerala')) return 'Post-monsoon beauty';
    return 'Pleasant weather';
  }

  String _getTransportTypes(String dest) {
    if (dest.contains('delhi') || dest.contains('mumbai')) return 'Metro, Auto, Taxi, Bus';
    if (dest.contains('goa')) return 'Bike, Taxi, Bus';
    return 'Auto, Taxi, Bus';
  }

  String _getAvgFare(String dest) {
    if (dest.contains('delhi') || dest.contains('mumbai')) return '150';
    if (dest.contains('goa')) return '200';
    return '100';
  }

  String _getFoodSpecialty(String dest) {
    if (dest.contains('delhi')) return 'North Indian, Street Food';
    if (dest.contains('goa')) return 'Seafood, Portuguese';
    if (dest.contains('kerala')) return 'South Indian, Seafood';
    return 'Local cuisine';
  }

  String _getAvgMeal(String dest) {
    if (dest.contains('delhi')) return '300';
    if (dest.contains('goa')) return '400';
    if (dest.contains('kerala')) return '250';
    return '200';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

// Made with Bob
