import 'dart:convert';

import 'package:http/http.dart' as http;

class LocalFareEstimate {
  final double? minFare;
  final double? maxFare;
  final String snippet;

  LocalFareEstimate({this.minFare, this.maxFare, required this.snippet});

  double? get averageFare {
    if (minFare != null && maxFare != null) {
      return (minFare! + maxFare!) / 2;
    }
    return minFare ?? maxFare;
  }

  String get displayText {
    if (minFare != null && maxFare != null) {
      return '₹${minFare!.toStringAsFixed(0)} - ₹${maxFare!.toStringAsFixed(0)}';
    }
    if (minFare != null) {
      return '₹${minFare!.toStringAsFixed(0)}';
    }
    return snippet;
  }
}

class GoogleSearchService {
  static const _apiKey = '<YOUR_GOOGLE_CUSTOM_SEARCH_API_KEY>';
  static const _searchEngineId = '<YOUR_SEARCH_ENGINE_ID>';
  static const _baseUrl = 'https://www.googleapis.com/customsearch/v1';

  final http.Client _client;

  GoogleSearchService([http.Client? client]) : _client = client ?? http.Client();

  Future<LocalFareEstimate> searchLocalFare(String transportType, String route) async {
    if (_apiKey.contains('<') || _searchEngineId.contains('<')) {
      throw Exception('Google Search API key or Search Engine ID not configured');
    }

    final query = _buildQuery(transportType, route);
    final url = Uri.parse('$_baseUrl?key=$_apiKey&cx=$_searchEngineId&q=${Uri.encodeQueryComponent(query)}');

    final response = await _client.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Search request failed with status ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final snippet = items.isNotEmpty ? items.first['snippet'] as String? ?? '' : 'No search snippet available.';

    final fareRange = _extractFareRange(snippet);
    return LocalFareEstimate(minFare: fareRange?.item1, maxFare: fareRange?.item2, snippet: snippet);
  }

  String _buildQuery(String transportType, String route) {
    final transportLabel = transportType == 'auto' ? 'auto-rickshaw' : 'taxi';
    return 'local $transportLabel fare for $route';
  }

  Tuple2<double, double>? _extractFareRange(String text) {
    final regex = RegExp(r'₹\s?([0-9,]+)(?:\s*(?:-|to|–)\s*₹\s?([0-9,]+))?');
    final match = regex.firstMatch(text);
    if (match == null) return null;

    final minValue = _parseAmount(match.group(1));
    final maxValue = match.group(2) != null ? _parseAmount(match.group(2)) : minValue;
    if (minValue == null) return null;
    return Tuple2(minValue, maxValue ?? minValue);
  }

  double? _parseAmount(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(',', '');
    return double.tryParse(cleaned);
  }
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);
}
