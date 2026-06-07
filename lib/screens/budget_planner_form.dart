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
import 'budget_summary_screen.dart';

class BudgetPlannerForm extends StatefulWidget {
  const BudgetPlannerForm({super.key});

  @override
  State<BudgetPlannerForm> createState() => _BudgetPlannerFormState();
}

class _BudgetPlannerFormState extends State<BudgetPlannerForm> {
  final _formKey = GlobalKey<FormState>();
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
    _originController.dispose();
    _destinationController.dispose();
    _distanceController.dispose();
    _daysController.dispose();
    _adultsController.dispose();
    _kidsController.dispose();
    super.dispose();
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
      });
      return;
    }

    setState(() {
      _isSearchingDestination = true;
      _destinationSearchError = null;
    });

    try {
      final service = PlacesService();
      final suggestions = await service.searchPlaceSuggestions(query);
      if (!mounted) return;
      if (_lastDestinationQueryTime != now) return;

      setState(() {
        _destinationSuggestions = suggestions;
      });
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (value) {
                                _searchDestinationSuggestions(value);
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Enter destination' : null,
                            ),
                            if (_destinationSuggestions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                                ),
                                child: Column(
                                  children: _destinationSuggestions.map((suggestion) {
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _destinationController.text = suggestion;
                                          _destinationSuggestions = [];
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF7F00FF)),
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
}
