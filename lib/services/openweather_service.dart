import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final double tempMin;
  final double tempMax;
  final String condition;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;

  WeatherData({
    required this.temperature,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;

    return WeatherData(
      temperature: (main['temp'] as num).toDouble() - 273.15, // Convert Kelvin to Celsius
      tempMin: (main['temp_min'] as num).toDouble() - 273.15,
      tempMax: (main['temp_max'] as num).toDouble() - 273.15,
      condition: weather['main'] as String,
      description: weather['description'] as String,
      icon: _getWeatherIcon(weather['main'] as String),
      humidity: main['humidity'] as int,
      windSpeed: (wind['speed'] as num).toDouble(),
    );
  }

  static String _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '⛅';
    }
  }
}

class OpenWeatherService {
  // OpenWeatherMap API - Free tier: 1,000 calls/day
  static const String _apiKey = '25da965568021246b04e61c908a1fa25';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  final http.Client _client;

  OpenWeatherService([http.Client? client]) : _client = client ?? http.Client();

  /// Get current weather for a city
  Future<WeatherData?> getCurrentWeather(String cityName) async {
    print('\n🌤️ ========== OpenWeather API Call ==========');
    print('📍 City: $cityName');
    print('🔑 API Key: ${_apiKey.substring(0, 8)}...');
    
    try {
      if (_apiKey == 'YOUR_OPENWEATHER_API_KEY' || _apiKey.isEmpty) {
        print('❌ API key not configured');
        print('============================================\n');
        return null;
      }

      final url = Uri.parse('$_baseUrl/weather?q=$cityName,IN&appid=$_apiKey');
      print('🌐 URL: $_baseUrl/weather?q=$cityName,IN&appid=***');
      print('⏳ Making API call...');

      final response = await _client.get(url).timeout(const Duration(seconds: 5));
      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Success! Parsing data...');
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final weatherData = WeatherData.fromJson(data);
        
        print('🌡️ Temp: ${weatherData.temperature.toStringAsFixed(1)}°C (High: ${weatherData.tempMax.toStringAsFixed(1)}°C, Low: ${weatherData.tempMin.toStringAsFixed(1)}°C)');
        print('☁️ ${weatherData.condition} - ${weatherData.description}');
        print('💨 Wind: ${weatherData.windSpeed} m/s | 💧 Humidity: ${weatherData.humidity}%');
        print('✅ Weather data fetched successfully!');
        print('============================================\n');
        return weatherData;
      } else if (response.statusCode == 404) {
        print('⚠️ City not found: $cityName');
        print('============================================\n');
        return null;
      } else if (response.statusCode == 401) {
        print('❌ Invalid API key (wait 10-15 min if just created)');
        print('============================================\n');
        return null;
      } else if (response.statusCode == 429) {
        print('⚠️ Rate limit exceeded (1,000/day)');
        print('============================================\n');
        return null;
      } else {
        print('❌ Error: ${response.statusCode}');
        print('============================================\n');
        return null;
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('============================================\n');
      return null;
    }
  }

  /// Get weather forecast for next 5 days
  Future<List<WeatherData>> getForecast(String cityName) async {
    try {
      if (_apiKey == 'YOUR_OPENWEATHER_API_KEY' || _apiKey.isEmpty) {
        return [];
      }

      final url = Uri.parse('$_baseUrl/forecast?q=$cityName,IN&appid=$_apiKey&cnt=5');
      final response = await _client.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['list'] as List;
        return list.map((item) => WeatherData.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching forecast: $e');
      return [];
    }
  }
}

// Made with Bob
