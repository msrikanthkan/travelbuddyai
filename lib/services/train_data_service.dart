import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/train_model.dart';

class TrainDataService {
  static final TrainDataService _instance = TrainDataService._internal();
  factory TrainDataService() => _instance;
  TrainDataService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static const String _cacheKey = 'cached_train_data';
  static const String _versionKey = 'train_data_version';
  
  bool _isInitialized = false;
  List<Train> _cachedTrains = [];

  /// Initialize Firebase Remote Config
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 12),
      ));

      // Set default values
      await _remoteConfig.setDefaults({
        'train_schedules_json': _getDefaultTrainData(),
        'data_version': '1.0.0',
        'last_updated': DateTime.now().toIso8601String(),
      });

      // Try to fetch and activate
      await _remoteConfig.fetchAndActivate();
      
      // Load trains into cache
      await _loadTrains();
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing TrainDataService: $e');
      // Load from local cache or defaults
      await _loadFromCache();
      _isInitialized = true;
    }
  }

  /// Load trains from Remote Config or cache
  Future<void> _loadTrains() async {
    try {
      final jsonString = _remoteConfig.getString('train_schedules_json');
      final data = json.decode(jsonString);
      
      if (data['trains'] != null) {
        _cachedTrains = (data['trains'] as List)
            .map((json) => Train.fromJson(json))
            .toList();
        
        // Save to local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonString);
        await prefs.setString(_versionKey, _remoteConfig.getString('data_version'));
      }
    } catch (e) {
      print('Error loading trains: $e');
      await _loadFromCache();
    }
  }

  /// Load trains from local cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData != null) {
        final data = json.decode(cachedData);
        _cachedTrains = (data['trains'] as List)
            .map((json) => Train.fromJson(json))
            .toList();
      } else {
        // Use default data
        final data = json.decode(_getDefaultTrainData());
        _cachedTrains = (data['trains'] as List)
            .map((json) => Train.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading from cache: $e');
      _cachedTrains = [];
    }
  }

  /// Get available trains for a route
  Future<List<Train>> getAvailableTrains({
    required String origin,
    required String destination,
    required String trainClass,
    required DateTime travelDate,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final dayOfWeek = _getDayName(travelDate);
    final classCode = _getClassCode(trainClass);

    return _cachedTrains.where((train) {
      final matchesRoute = _matchesRoute(train, origin, destination);
      final runsOnDay = train.runsOn.contains(dayOfWeek);
      final hasClass = train.classesAvailable.contains(classCode);

      return matchesRoute && runsOnDay && hasClass;
    }).toList();
  }

  /// Get all trains (for admin/testing)
  Future<List<Train>> getAllTrains() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _cachedTrains;
  }

  /// Get data version
  String getDataVersion() {
    return _remoteConfig.getString('data_version');
  }

  /// Get last updated date
  String getLastUpdated() {
    return _remoteConfig.getString('last_updated');
  }

  /// Force refresh from Remote Config
  Future<bool> forceRefresh() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      if (updated) {
        await _loadTrains();
      }
      return updated;
    } catch (e) {
      print('Error force refreshing: $e');
      return false;
    }
  }

  // Helper methods

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getClassCode(String trainClass) {
    const classMap = {
      'sleeper': 'SL',
      'ac3tier': '3A',
      'ac2tier': '2A',
      'ac1st': '1A',
    };
    return classMap[trainClass] ?? '3A';
  }

  bool _matchesRoute(Train train, String origin, String destination) {
    final originLower = origin.toLowerCase();
    final destLower = destination.toLowerCase();

    final matchesOrigin = train.originName.toLowerCase().contains(originLower) ||
        train.origin.toLowerCase().contains(originLower) ||
        originLower.contains(train.originName.toLowerCase()) ||
        originLower.contains(train.origin.toLowerCase());

    final matchesDest = train.destinationName.toLowerCase().contains(destLower) ||
        train.destination.toLowerCase().contains(destLower) ||
        destLower.contains(train.destinationName.toLowerCase()) ||
        destLower.contains(train.destination.toLowerCase());

    return matchesOrigin && matchesDest;
  }

  /// Default train data (fallback)
  String _getDefaultTrainData() {
    return json.encode({
      'version': '1.0.0',
      'last_updated': '2024-06-05',
      'trains': [
        {
          'train_number': '18464',
          'train_name': 'Visakha Express',
          'origin': 'VSKP',
          'origin_name': 'Visakhapatnam',
          'destination': 'TPTY',
          'destination_name': 'Tirupati',
          'departure_time': '20:30',
          'arrival_time': '06:45',
          'duration_hours': 10.25,
          'runs_on': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          'classes_available': ['SL', '3A', '2A', '1A']
        },
        {
          'train_number': '12804',
          'train_name': 'Simhapuri Express',
          'origin': 'VSKP',
          'origin_name': 'Visakhapatnam',
          'destination': 'TPTY',
          'destination_name': 'Tirupati',
          'departure_time': '17:15',
          'arrival_time': '02:30',
          'duration_hours': 9.25,
          'runs_on': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          'classes_available': ['SL', '3A', '2A']
        },
        {
          'train_number': '12759',
          'train_name': 'Charminar Express',
          'origin': 'HYB',
          'origin_name': 'Hyderabad',
          'destination': 'VSKP',
          'destination_name': 'Visakhapatnam',
          'departure_time': '18:55',
          'arrival_time': '06:30',
          'duration_hours': 11.58,
          'runs_on': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          'classes_available': ['SL', '3A', '2A', '1A']
        },
        {
          'train_number': '12760',
          'train_name': 'Charminar Express',
          'origin': 'VSKP',
          'origin_name': 'Visakhapatnam',
          'destination': 'HYB',
          'destination_name': 'Hyderabad',
          'departure_time': '17:30',
          'arrival_time': '05:15',
          'duration_hours': 11.75,
          'runs_on': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          'classes_available': ['SL', '3A', '2A', '1A']
        }
      ]
    });
  }
}

// Made with Bob
