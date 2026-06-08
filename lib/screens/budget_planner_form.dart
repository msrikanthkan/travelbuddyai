import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/train_model.dart';
import '../services/attractions_service.dart';
import '../services/budget_service.dart';
import '../services/maps_service.dart';
import '../services/places_service.dart';
import '../services/pricing_service.dart';
import '../services/train_data_service.dart';
import '../services/live_destinations_api_service.dart';
import '../services/trending_destinations_service.dart';
import '../services/destination_insights_service.dart';
import 'budget_summary_screen.dart';

class BudgetPlannerForm extends StatefulWidget {
  const BudgetPlannerForm({super.key});

  @override
  State<BudgetPlannerForm> createState() => _BudgetPlannerFormState();
}

class _BudgetPlannerFormState extends State<BudgetPlannerForm> {
  final _formKey = GlobalKey<FormState>();
  
  // New fields for occasion-based planning
  String _occasionType = 'casual'; // casual, wedding, birthday, devotional, cultural, adventure, other
  final _numberOfPeopleController = TextEditingController(text: '2');
  final _budgetController = TextEditingController();
  List<Map<String, dynamic>> _trendingDestinations = [];
  bool _isLoadingTrending = false;
  bool _showDestinationSuggestions = true;
  
  final _originController = TextEditingController(text: 'Visakhapatnam');
  final _destinationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _daysController = TextEditingController(text: '3');
  final _adultsController = TextEditingController(text: '2');
  final _kidsController = TextEditingController(text: '0');
  String _hotelCategory = 'budget';
  String _travelType = 'road'; // road, train, or flight
  String _trainClass = 'ac3tier'; // sleeper, ac3tier, ac2tier, ac1st
  String _flightClass = 'economy'; // economy, premium_economy, business
  DateTime? _startDate;
  DateTime? _returnDate;
  double _attractionBudget = 3000;
  bool _isLoadingDistance = false;
  bool _isLoadingAttractions = false;
  bool _isSearchingDestination = false;
  bool _isSearchingOrigin = false;
  bool _isLoadingTrains = false;
  List<Train> _availableTrains = [];
  Train? _selectedTrain;
  String? _destinationSearchError;
  String? _originSearchError;
  String? _distanceError;
  DateTime? _lastEstimateTime;
  DateTime? _lastDestinationQueryTime;
  DateTime? _lastOriginQueryTime;
  List<String> _destinationSuggestions = [];
  List<String> _originSuggestions = [];
  List<Attraction> _suggestedAttractions = [];
  List<DestinationInsight> _destinationInsights = [];
  bool _isLoadingInsights = false;
  bool _showInsights = false;

  static final Map<String, double> _knownRouteFallbacks = {
    'visakhapatnam-hyderabad': 625.0,
    'hyderabad-visakhapatnam': 625.0,
    'visakhapatnam-tirupati': 445.0,
    'tirupati-visakhapatnam': 445.0,
    'hyderabad-tirupati': 555.0,
    'tirupati-hyderabad': 555.0,
    'hyderabad-vizag': 625.0,
    'vizag-hyderabad': 625.0,
    'tirupati-vizag': 445.0,
    'vizag-tirupati': 445.0,
    'visakhapatnam-vizag': 16.0,
    'vizag-visakhapatnam': 16.0,
  };

  @override
  void dispose() {
    _numberOfPeopleController.dispose();
    _budgetController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _distanceController.dispose();
    _daysController.dispose();
    _adultsController.dispose();
    _kidsController.dispose();
    super.dispose();
  }

  Future<void> _fetchTrendingDestinations() async {
    if (_budgetController.text.isEmpty || _daysController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingTrending = true;
      _showDestinationSuggestions = true; // Always show when fetching new data
    });

    try {
      final budget = double.tryParse(_budgetController.text) ?? 0;
      final duration = int.tryParse(_daysController.text) ?? 3;
      
      List<Map<String, dynamic>> destinations = [];
      
      // Try live API first (Google Custom Search)
      try {
        final liveService = LiveDestinationsApiService();
        destinations = await liveService.getTrendingDestinations(
          occasionType: _occasionType,
          budget: budget,
          duration: duration,
        );
        print('✅ Fetched ${destinations.length} destinations from live API');
      } catch (e) {
        print('⚠️ Live API failed: $e');
      }
      
      // Fallback to curated destinations if live API fails or returns empty
      if (destinations.isEmpty) {
        print('📋 Using fallback curated destinations');
        final trendingService = TrendingDestinationsService();
        destinations = await trendingService.getTrendingDestinations(
          occasionType: _occasionType,
          budget: budget,
          duration: duration,
          userDestination: _destinationController.text.isNotEmpty
              ? _destinationController.text
              : null,
        );
      }

      setState(() {
        _trendingDestinations = destinations;
        _isLoadingTrending = false;
      });
    } catch (e) {
      print('❌ Error fetching trending destinations: $e');
      setState(() {
        _isLoadingTrending = false;
      });
    }
  }

  void _onOccasionChanged(String? value) {
    if (value != null) {
      setState(() {
        _occasionType = value;
        _trendingDestinations = [];
        _showDestinationSuggestions = true; // Show suggestions again
      });
      _fetchTrendingDestinations();
    }
  }

  void _showDestinationInsights(BuildContext context, Map<String, dynamic> destination) {
    final insights = destination['insights'] as Map<String, dynamic>?;
    if (insights == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination['name'],
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                destination['country'],
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              if (destination['weather'] != null) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF7F00FF), Color(0xFFB400D9)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        destination['weather']['icon'] ?? '🌤️',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${destination['weather']['temperature'].toStringAsFixed(1)}°C',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7F00FF), Color(0xFFB400D9)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${insights['trendScore']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Trending Reason
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F00FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Color(0xFF7F00FF)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insights['trendingReason'],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                // Live Weather Section (if available)
                if (destination['weather'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00B4DB).withOpacity(0.15),
                          const Color(0xFF0083B0).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.wb_sunny, color: Color(0xFF00B4DB), size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Live Weather',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              destination['weather']['icon'] ?? '🌤️',
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${destination['weather']['temperature'].toStringAsFixed(1)}°C',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00B4DB),
                                    ),
                                  ),
                                  Text(
                                    destination['weather']['description'].toString().toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildWeatherDetail(
                              '🌡️',
                              'Feels Like',
                              '${destination['weather']['feelsLike'].toStringAsFixed(0)}°C',
                            ),
                            _buildWeatherDetail(
                              '💧',
                              'Humidity',
                              '${destination['weather']['humidity']}%',
                            ),
                            _buildWeatherDetail(
                              '💨',
                              'Wind',
                              '${destination['weather']['windSpeed'].toStringAsFixed(1)} m/s',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'High: ${destination['weather']['tempMax'].toStringAsFixed(0)}°C',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Low: ${destination['weather']['tempMin'].toStringAsFixed(0)}°C',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 20),
                
                // Key Stats
                const Text(
                  'Travel Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildInsightRow(Icons.people, 'Popularity', '#${insights['popularityRank']} in ${destination['bestFor']}'),
                _buildInsightRow(Icons.visibility, 'Visitors', insights['avgVisitors']),
                _buildInsightRow(Icons.calendar_today, 'Peak Season', insights['peakSeason']),
                _buildInsightRow(Icons.wb_sunny, 'Best Time', insights['bestTime']),
                _buildInsightRow(Icons.currency_rupee, 'Avg Cost', insights['avgCost']),
                _buildInsightRow(Icons.groups, 'Crowd Level', insights['crowdLevel']),
                _buildInsightRow(Icons.cloud, 'Weather Rating', '${insights['weatherRating']}/5'),
                _buildInsightRow(Icons.trending_up, 'Recent Trend', insights['recentTrend']),
                _buildInsightRow(Icons.star, 'Unique Feature', insights['uniqueFeature']),
                
                const SizedBox(height: 20),
                
                // Top Activities/Attractions
                if (insights['topActivities'] != null) ...[
                  const Text(
                    'Top Activities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (insights['topActivities'] as List).map((activity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7F00FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF7F00FF).withOpacity(0.3)),
                        ),
                        child: Text(
                          activity,
                          style: const TextStyle(color: Color(0xFF7F00FF), fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Select Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _destinationController.text = destination['name'];
                        _showDestinationSuggestions = false;
                      });
                      _estimateDistance();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F00FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Select This Destination', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF7F00FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(DestinationInsight insight) {
    // Color schemes for different insight types
    final colorSchemes = {
      'weather': [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
      'hotels': [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F)],
      'temperature': [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
      'tour_package': [const Color(0xFF7F00FF), const Color(0xFFB400D9)],
      'distance': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      'popular_times': [const Color(0xFFFFB75E), const Color(0xFFED8F03)],
      'transport': [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
      'food': [const Color(0xFFFF6B95), const Color(0xFFFFC796)],
    };

    final colors = colorSchemes[insight.type] ?? [const Color(0xFF7F00FF), const Color(0xFFB400D9)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[0].withOpacity(0.1),
            colors[1].withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[0].withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Show detailed insight in a dialog
            _showInsightDetails(insight);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: colors[0].withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        insight.icon ?? '📍',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 12, color: colors[0].withOpacity(0.5)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  insight.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (insight.value != null)
                  Text(
                    insight.value!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors[0],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInsightDetails(DestinationInsight insight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7F00FF), Color(0xFFB400D9)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            insight.icon ?? '📍',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                insight.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                insight.subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (insight.value != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7F00FF).withOpacity(0.1),
                              const Color(0xFFB400D9).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF7F00FF)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                insight.value!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F00FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Got it',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _estimateDistance() async {
    final now = DateTime.now();
    if (_lastEstimateTime != null && now.difference(_lastEstimateTime!).inSeconds < 2) {
      return;
    }
    _lastEstimateTime = now;

    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      setState(() {
        _distanceError = 'Enter both origin and destination';
      });
      return;
    }

    setState(() {
      _isLoadingDistance = true;
      _distanceError = null;
    });

    final mapsService = MapsService();
    final distance = await mapsService.getDistanceKm(
      _originController.text.trim(),
      _destinationController.text.trim(),
    );

    final fallback = _estimateDistanceFallback(
      _originController.text.trim(),
      _destinationController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isLoadingDistance = false;
      if (distance != null) {
        _distanceController.text = distance.toStringAsFixed(1);
        _distanceError = null;
      } else if (fallback != null) {
        _distanceController.text = fallback.toStringAsFixed(1);
        _distanceError = 'Could not fetch live distance. Using fallback route estimate.';
      } else {
        _distanceError = 'Could not fetch distance. Try manually.';
      }
    });

    _fetchAttractions();
  }

  Future<void> _searchDestinationSuggestions(String query) async {
    final now = DateTime.now();
    _lastDestinationQueryTime = now;

    if (query.trim().length < 2) {
      setState(() {
        _destinationSuggestions = [];
        _destinationSearchError = null;
        _destinationInsights = [];
        _showInsights = false;
      });
      return;
    }

    setState(() {
      _isSearchingDestination = true;
      _destinationSearchError = null;
      _showInsights = true;
    });

    try {
      final service = PlacesService();
      final suggestions = await service.searchPlaceSuggestions(query);
      if (!mounted) return;
      if (_lastDestinationQueryTime != now) return;

      setState(() {
        _destinationSuggestions = suggestions;
      });
      
      // Fetch insights for the query
      _fetchDestinationInsights(query);
    } catch (error) {
      if (!mounted) return;
      if (_lastDestinationQueryTime != now) return;
      setState(() {
        _destinationSearchError = error.toString();
        _destinationSuggestions = [];
      });
    } finally {
      if (!mounted) return;
      if (_lastDestinationQueryTime == now) {
        setState(() {
          _isSearchingDestination = false;
        });
      }
    }
  }

  Future<void> _fetchDestinationInsights(String destination) async {
    if (destination.trim().length < 3) return;

    setState(() {
      _isLoadingInsights = true;
    });

    try {
      final insightsService = DestinationInsightsService();
      final insights = await insightsService.getDestinationInsights(destination);
      
      if (!mounted) return;
      
      setState(() {
        _destinationInsights = insights;
        _isLoadingInsights = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInsights = false;
      });
    }
  }

  Future<void> _searchOriginSuggestions(String query) async {
    final now = DateTime.now();
    _lastOriginQueryTime = now;

    if (query.trim().length < 2) {
      setState(() {
        _originSuggestions = [];
        _originSearchError = null;
      });
      return;
    }

    setState(() {
      _isSearchingOrigin = true;
      _originSearchError = null;
    });

    try {
      final service = PlacesService();
      final suggestions = await service.searchPlaceSuggestions(query);
      if (!mounted) return;
      if (_lastOriginQueryTime != now) return;

      setState(() {
        _originSuggestions = suggestions;
      });
    } catch (error) {
      if (!mounted) return;
      if (_lastOriginQueryTime != now) return;
      setState(() {
        _originSearchError = error.toString();
        _originSuggestions = [];
      });
    } finally {
      if (!mounted) return;
      if (_lastOriginQueryTime == now) {
        setState(() {
          _isSearchingOrigin = false;
        });
      }
    }
  }

  double? _estimateDistanceFallback(String origin, String destination) {
    final o = origin.toLowerCase();
    final d = destination.toLowerCase();
    for (final entry in _knownRouteFallbacks.entries) {
      final parts = entry.key.split('-');
      if (parts.length != 2) continue;
      final a = parts[0];
      final b = parts[1];
      if ((o.contains(a) && d.contains(b)) || (o.contains(b) && d.contains(a))) {
        return entry.value;
      }
    }
    // Try matching by city tokens (very fuzzy)
    final tokensO = o.split(RegExp(r'[^a-z0-9]+'));
    final tokensD = d.split(RegExp(r'[^a-z0-9]+'));
    for (final entry in _knownRouteFallbacks.entries) {
      final parts = entry.key.split('-');
      final a = parts[0];
      final b = parts[1];
      if (tokensO.contains(a) && tokensD.contains(b)) return entry.value;
      if (tokensO.contains(b) && tokensD.contains(a)) return entry.value;
    }
    return null;
  }

  Future<void> _fetchAttractions() async {
    if (_destinationController.text.isEmpty) return;

    setState(() {
      _isLoadingAttractions = true;
    });

    final attractionsService = AttractionsService();
    final attractions = await attractionsService.getAttractionsByDestination(
      _destinationController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isLoadingAttractions = false;
      _suggestedAttractions = attractions;
    });
    
    // Also update attraction budget based on destination
    _updateAttractionBudget();
  }

  Future<void> _updateAttractionBudget() async {
    if (_destinationController.text.isEmpty) return;
    
    final days = int.tryParse(_daysController.text) ?? 3;
    final adults = int.tryParse(_adultsController.text) ?? 2;
    final kids = int.tryParse(_kidsController.text) ?? 0;
    final familySize = adults + kids;
    
    try {
      final pricingService = PricingService();
      final suggestedBudget = await pricingService.getAttractionBudget(
        _destinationController.text.trim(),
        days,
        familySize,
      );
      
      if (!mounted) return;
      setState(() {
        _attractionBudget = suggestedBudget;
      });
    } catch (e) {
      // Keep current budget if fetch fails
    }
  }

  Future<void> _fetchAvailableTrains() async {
    if (_travelType != 'train' || _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select travel date first')),
      );
      return;
    }

    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter origin and destination')),
      );
      return;
    }

    setState(() {
      _isLoadingTrains = true;
      _availableTrains = [];
      _selectedTrain = null;
    });

    try {
      final trainService = TrainDataService();
      final trains = await trainService.getAvailableTrains(
        origin: _originController.text.trim(),
        destination: _destinationController.text.trim(),
        trainClass: _trainClass,
        travelDate: _startDate!,
      );

      if (!mounted) return;
      setState(() {
        _availableTrains = trains;
        _isLoadingTrains = false;
      });

      if (trains.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No trains found for this route and class. Try different options.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTrains = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching trains: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final distance = double.parse(_distanceController.text);
    final days = int.parse(_daysController.text);
    final adults = int.parse(_adultsController.text);
    final kids = int.parse(_kidsController.text);
    final familySize = adults + kids;
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final service = BudgetService();
      final budget = await service.calculateTotalBudget(
        tripId: destination.isEmpty ? 'trip' : destination,
        origin: origin,
        destination: destination,
        distanceKm: distance,
        days: days,
        adults: adults,
        kids: kids,
        hotelCategory: _hotelCategory,
        travelType: _travelType,
        trainClass: _trainClass,
        flightClass: _flightClass,
        attractionBudget: _attractionBudget,
      );

      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to budget summary
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BudgetSummaryScreen(
            budget: budget,
            destination: destination,
            days: days,
            familySize: familySize,
            hotelCategory: _hotelCategory,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating budget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Your Trip'),
        backgroundColor: const Color(0xFF7F00FF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7F00FF), Color(0xFFB400D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Trip Budget Planner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Calculate your complete trip cost',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            // Form section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Occasion Type Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'What\'s the Occasion?',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _occasionType,
                              decoration: InputDecoration(
                                labelText: 'Select Occasion Type',
                                prefixIcon: const Icon(Icons.celebration),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'casual', child: Text('Casual Trip')),
                                DropdownMenuItem(value: 'wedding', child: Text('Wedding')),
                                DropdownMenuItem(value: 'birthday', child: Text('Birthday')),
                                DropdownMenuItem(value: 'devotional', child: Text('Devotional')),
                                DropdownMenuItem(value: 'cultural', child: Text('Cultural')),
                                DropdownMenuItem(value: 'adventure', child: Text('Adventure')),
                                DropdownMenuItem(value: 'other', child: Text('Other')),
                              ],
                              onChanged: _onOccasionChanged,
                              validator: (value) => value == null ? 'Select occasion type' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _numberOfPeopleController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Number of People',
                                      prefixIcon: const Icon(Icons.people),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Enter number of people';
                                      if (int.tryParse(value) == null || int.parse(value) < 1) {
                                        return 'Enter valid number';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) => _fetchTrendingDestinations(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _daysController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Duration (Days)',
                                      prefixIcon: const Icon(Icons.calendar_today),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Enter days';
                                      if (int.tryParse(value) == null || int.parse(value) < 1) {
                                        return 'Enter valid days';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) => _fetchTrendingDestinations(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Total Budget (₹)',
                                prefixIcon: const Icon(Icons.currency_rupee),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                helperText: 'Enter your approximate budget',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter budget';
                                if (double.tryParse(value) == null || double.parse(value) < 1000) {
                                  return 'Enter valid budget (min ₹1000)';
                                }
                                return null;
                              },
                              onChanged: (value) => _fetchTrendingDestinations(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Trending Destinations Section
                    if (_isLoadingTrending)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Finding best destinations for you...'),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (_trendingDestinations.isNotEmpty && _showDestinationSuggestions)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Trending Destinations',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _showDestinationSuggestions = false;
                                      });
                                    },
                                    child: const Text('Skip'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 180,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _trendingDestinations.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final dest = _trendingDestinations[index];
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _destinationController.text = dest['name'];
                                          _showDestinationSuggestions = false;
                                        });
                                        _estimateDistance();
                                      },
                                      child: Container(
                                        width: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF7F00FF).withOpacity(0.8),
                                              const Color(0xFFB400D9).withOpacity(0.8),
                                            ],
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    dest['name'],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.3),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        dest['rating'].toString(),
                                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  dest['country'],
                                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                                                ),
                                                if (dest['weather'] != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.25),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          dest['weather']['icon'] ?? '🌤️',
                                                          style: const TextStyle(fontSize: 12),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${dest['weather']['temperature'].toStringAsFixed(0)}°C',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: Text(
                                                dest['description'],
                                                style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                if (dest['highlights'] != null)
                                                  Expanded(
                                                    child: Wrap(
                                                      spacing: 4,
                                                      runSpacing: 4,
                                                      children: (dest['highlights'] as List).take(2).map((highlight) {
                                                        return Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white.withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            highlight,
                                                            style: const TextStyle(color: Colors.white, fontSize: 10),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                if (dest['insights'] != null)
                                                  IconButton(
                                                    icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                                                    onPressed: () => _showDestinationInsights(context, dest),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Origin & Destination Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trip Details',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _originController,
                              decoration: InputDecoration(
                                labelText: 'Origin',
                                prefixIcon: const Icon(Icons.location_on),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (value) {
                                _searchOriginSuggestions(value);
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Enter origin' : null,
                            ),
                            if (_originSuggestions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                                ),
                                child: Column(
                                  children: _originSuggestions.map((suggestion) {
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _originController.text = suggestion;
                                          _originSuggestions = [];
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 18, color: Color(0xFF7F00FF)),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(suggestion, style: const TextStyle(fontSize: 14))),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                            if (_originSearchError != null) ...[
                              const SizedBox(height: 8),
                              Text(_originSearchError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                labelText: 'Destination',
                                prefixIcon: const Icon(Icons.location_on_outlined),
                                suffixIcon: _showInsights && _destinationController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _destinationController.clear();
                                            _destinationSuggestions = [];
                                            _destinationInsights = [];
                                            _showInsights = false;
                                          });
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (value) {
                                _searchDestinationSuggestions(value);
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Enter destination' : null,
                            ),
                            // Insane UI for Destination Insights
                            if (_showInsights && (_destinationSuggestions.isNotEmpty || _destinationInsights.isNotEmpty)) ...[
                              const SizedBox(height: 12),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 500),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      const Color(0xFF7F00FF).withOpacity(0.02),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF7F00FF).withOpacity(0.2), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7F00FF).withOpacity(0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header with gradient
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF7F00FF).withOpacity(0.1),
                                                const Color(0xFFB400D9).withOpacity(0.05),
                                              ],
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF7F00FF).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.search, color: Color(0xFF7F00FF), size: 20),
                                              ),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                child: Text(
                                                  'Travel Insights & Suggestions',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF7F00FF),
                                                  ),
                                                ),
                                              ),
                                              if (_isLoadingInsights)
                                                const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7F00FF)),
                                                ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Place Suggestions
                                        if (_destinationSuggestions.isNotEmpty) ...[
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 4,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF7F00FF), Color(0xFFB400D9)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Destinations',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF7F00FF),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ...(_destinationSuggestions.take(3).map((suggestion) {
                                            return InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _destinationController.text = suggestion;
                                                  _destinationSuggestions = [];
                                                  _showInsights = false;
                                                });
                                                _estimateDistance();
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.03),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            const Color(0xFF7F00FF).withOpacity(0.1),
                                                            const Color(0xFFB400D9).withOpacity(0.1),
                                                          ],
                                                        ),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Icon(Icons.location_on, size: 20, color: Color(0xFF7F00FF)),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        suggestion,
                                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                                      ),
                                                    ),
                                                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList()),
                                          const SizedBox(height: 8),
                                        ],
                                        
                                        // Travel Insights Grid
                                        if (_destinationInsights.isNotEmpty) ...[
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 4,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Quick Insights',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF00B4DB),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: GridView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                childAspectRatio: 1.5,
                                                crossAxisSpacing: 8,
                                                mainAxisSpacing: 8,
                                              ),
                                              itemCount: _destinationInsights.length,
                                              itemBuilder: (context, index) {
                                                final insight = _destinationInsights[index];
                                                return _buildInsightCard(insight);
                                              },
                                            ),
                                          ),
                                        ],
                                        
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (_destinationSearchError != null) ...[
                              const SizedBox(height: 8),
                              Text(_destinationSearchError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _distanceController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Distance (km)',
                                      prefixIcon: const Icon(Icons.straighten),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Enter distance';
                                      if (double.tryParse(value) == null) return 'Enter valid distance';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00B4DB),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _isLoadingDistance ? null : _estimateDistance,
                                    icon: _isLoadingDistance
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.search),
                                    label: const Text('Get', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                            if (_distanceError != null) ...[
                              const SizedBox(height: 8),
                              Text(_distanceError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Travel Type & Dates Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Travel Details',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            // Travel Type Dropdown
                            DropdownButtonFormField<String>(
                              value: _travelType,
                              decoration: InputDecoration(
                                labelText: 'Travel Type',
                                prefixIcon: const Icon(Icons.directions),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'road', child: Text('🚗 Road Trip')),
                                DropdownMenuItem(value: 'train', child: Text('🚂 Train')),
                                DropdownMenuItem(value: 'flight', child: Text('✈️ Flight')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _travelType = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            // Train Class Dropdown (shown only when train is selected)
                            if (_travelType == 'train')
                              DropdownButtonFormField<String>(
                                value: _trainClass,
                                decoration: InputDecoration(
                                  labelText: 'Train Coach Type',
                                  prefixIcon: const Icon(Icons.airline_seat_recline_normal),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'sleeper', child: Text('Sleeper Class')),
                                  DropdownMenuItem(value: 'ac3tier', child: Text('AC 3-Tier')),
                                  DropdownMenuItem(value: 'ac2tier', child: Text('AC 2-Tier')),
                                  DropdownMenuItem(value: 'ac1st', child: Text('AC 1st Class')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _trainClass = value!;
                                    _availableTrains = [];
                                    _selectedTrain = null;
                                  });
                                },
                              ),
                            if (_travelType == 'train')
                              const SizedBox(height: 16),
                            // Find Trains Button (shown only when train is selected)
                            if (_travelType == 'train')
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7F00FF),
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isLoadingTrains ? null : _fetchAvailableTrains,
                                icon: _isLoadingTrains
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.search, color: Colors.white),
                                label: Text(
                                  _isLoadingTrains ? 'Searching Trains...' : 'Find Available Trains',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            if (_travelType == 'train' && _availableTrains.isNotEmpty)
                              const SizedBox(height: 16),
                            // Train Selection Dropdown
                            if (_travelType == 'train' && _availableTrains.isNotEmpty)
                              DropdownButtonFormField<Train>(
                                value: _selectedTrain,
                                decoration: InputDecoration(
                                  labelText: 'Select Train',
                                  prefixIcon: const Icon(Icons.train),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  helperText: '${_availableTrains.length} trains available',
                                ),
                                isExpanded: true,
                                itemHeight: 60,
                                selectedItemBuilder: (BuildContext context) {
                                  return _availableTrains.map((train) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        train.displayName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList();
                                },
                                items: _availableTrains.map((train) {
                                  return DropdownMenuItem<Train>(
                                    value: train,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          train.displayName,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${train.timingInfo} • ${train.durationInfo}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (train) {
                                  setState(() {
                                    _selectedTrain = train;
                                  });
                                },
                              ),
                            if (_travelType == 'train')
                              const SizedBox(height: 16),
                            // Flight Class Dropdown (shown only when flight is selected)
                            if (_travelType == 'flight')
                              DropdownButtonFormField<String>(
                                value: _flightClass,
                                decoration: InputDecoration(
                                  labelText: 'Flight Class',
                                  prefixIcon: const Icon(Icons.airline_seat_flat),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'economy', child: Text('Economy')),
                                  DropdownMenuItem(value: 'premium_economy', child: Text('Premium Economy')),
                                  DropdownMenuItem(value: 'business', child: Text('Business Class')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _flightClass = value!;
                                  });
                                },
                              ),
                            if (_travelType == 'train' || _travelType == 'flight')
                              const SizedBox(height: 16),
                            // Start Date
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _startDate = date;
                                    // Auto-calculate return date if days are set
                                    if (_daysController.text.isNotEmpty) {
                                      final days = int.tryParse(_daysController.text) ?? 0;
                                      if (days > 0) {
                                        _returnDate = date.add(Duration(days: days));
                                      }
                                    }
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  _startDate == null
                                      ? 'Select start date'
                                      : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                                  style: TextStyle(
                                    color: _startDate == null ? Colors.grey : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Return Date
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _returnDate ?? _startDate?.add(const Duration(days: 3)) ?? DateTime.now().add(const Duration(days: 3)),
                                  firstDate: _startDate ?? DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _returnDate = date;
                                    // Auto-calculate days
                                    if (_startDate != null) {
                                      final days = date.difference(_startDate!).inDays;
                                      _daysController.text = days.toString();
                                    }
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Return Date',
                                  prefixIcon: const Icon(Icons.event),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  _returnDate == null
                                      ? 'Select return date'
                                      : '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}',
                                  style: TextStyle(
                                    color: _returnDate == null ? Colors.grey : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Trip Duration & Family Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Traveler Info',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _daysController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Trip Duration (Days)',
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter days';
                                if (int.tryParse(value) == null) return 'Enter valid days';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _adultsController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Adults',
                                      prefixIcon: const Icon(Icons.person),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Required';
                                      if (int.tryParse(value) == null) return 'Valid #';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _kidsController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Kids',
                                      prefixIcon: const Icon(Icons.child_care),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Required';
                                      if (int.tryParse(value) == null) return 'Valid #';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Hotel & Attraction Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preferences',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _hotelCategory,
                              decoration: InputDecoration(
                                labelText: 'Hotel Category',
                                prefixIcon: const Icon(Icons.hotel),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'budget', child: Text('Budget')),
                                DropdownMenuItem(value: 'premium', child: Text('Premium')),
                                DropdownMenuItem(value: 'luxury', child: Text('Luxury')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _hotelCategory = value);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: _attractionBudget.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Attraction Budget (₹)',
                                prefixIcon: const Icon(Icons.local_activity),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (value) {
                                final parsed = double.tryParse(value);
                                if (parsed != null) _attractionBudget = parsed;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7F00FF),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submit,
                      child: const Text('Calculate Trip Cost', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            // Attractions section
            if (_suggestedAttractions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suggested Attractions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestedAttractions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final attraction = _suggestedAttractions[index];
                          return Container(
                            width: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: attraction.images.isNotEmpty ? attraction.images[0] : 'https://picsum.photos/800/600?random=0',
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black87, Colors.transparent],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          attraction.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              attraction.rating.toStringAsFixed(1),
                                              style: const TextStyle(color: Colors.white, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            else if (_isLoadingAttractions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text('Loading attractions...'),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00B4DB),
          ),
        ),
      ],
    );
  }
}
