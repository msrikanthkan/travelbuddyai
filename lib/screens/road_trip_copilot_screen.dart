import 'dart:async';

import 'package:flutter/material.dart';

import '../models/route_model.dart';
import '../models/vehicle_profile_model.dart';
import '../services/places_service.dart';
import '../services/road_trip_service.dart';
import 'route_details_screen.dart';

class RoadTripCopilotScreen extends StatefulWidget {
  const RoadTripCopilotScreen({super.key});

  @override
  State<RoadTripCopilotScreen> createState() => _RoadTripCopilotScreenState();
}

class _RoadTripCopilotScreenState extends State<RoadTripCopilotScreen> {
  static const _purple = Color(0xFF7F00FF);

  final _roadTripService = RoadTripService();
  final _placesService = PlacesService();

  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();

  RouteType _selectedType = RouteType.fastest;
  final VehicleProfile _selectedVehicle = VehicleProfile.defaultProfile;

  bool _isLoading = false;
  String? _errorMessage;

  // Autocomplete state
  List<String> _originSuggestions = [];
  List<String> _destSuggestions = [];
  bool _showOriginSuggestions = false;
  bool _showDestSuggestions = false;

  // Debounce timers to prevent stale results from fast typing
  Timer? _originDebounce;
  Timer? _destDebounce;

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    _originDebounce?.cancel();
    _destDebounce?.cancel();
    super.dispose();
  }

  void _onOriginChanged(String value) {
    _originDebounce?.cancel();
    if (value.length < 3) {
      setState(() => _showOriginSuggestions = false);
      return;
    }
    _originDebounce = Timer(const Duration(milliseconds: 400), () async {
      // Guard: value may have changed since the timer fired
      if (_originCtrl.text.trim() != value.trim()) return;
      final suggestions = await _placesService.searchPlaceSuggestions(value);
      if (mounted && _originCtrl.text.trim() == value.trim()) {
        setState(() {
          _originSuggestions = suggestions.take(5).toList();
          _showOriginSuggestions = _originSuggestions.isNotEmpty;
        });
      }
    });
  }

  void _onDestChanged(String value) {
    _destDebounce?.cancel();
    if (value.length < 3) {
      setState(() => _showDestSuggestions = false);
      return;
    }
    _destDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (_destCtrl.text.trim() != value.trim()) return;
      final suggestions = await _placesService.searchPlaceSuggestions(value);
      if (mounted && _destCtrl.text.trim() == value.trim()) {
        setState(() {
          _destSuggestions = suggestions.take(5).toList();
          _showDestSuggestions = _destSuggestions.isNotEmpty;
        });
      }
    });
  }

  Future<void> _planRoute() async {
    final origin = _originCtrl.text.trim();
    final dest = _destCtrl.text.trim();

    if (origin.isEmpty || dest.isEmpty) {
      setState(() => _errorMessage = 'Please enter both origin and destination.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showOriginSuggestions = false;
      _showDestSuggestions = false;
    });

    final route = await _roadTripService.planRoute(
      origin,
      dest,
      type: _selectedType,
      vehicle: _selectedVehicle,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (route == null) {
      setState(() => _errorMessage =
          'Could not calculate route. Please check the locations and try again.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteDetailsScreen(
          route: route,
          vehicle: _selectedVehicle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Road Trip Co-Pilot'),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => setState(() {
          _showOriginSuggestions = false;
          _showDestSuggestions = false;
        }),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildLocationFields(),
              const SizedBox(height: 20),
              _buildVehicleCard(),
              const SizedBox(height: 20),
              _buildRouteTypeSelector(),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                _buildErrorBanner(),
                const SizedBox(height: 16),
              ],
              _buildPlanButton(),
              const SizedBox(height: 20),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.directions_car, color: _purple, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Plan Your Road Trip',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Get fuel cost, toll estimates, and best route options.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildLocationFields() {
    return Column(
      children: [
        _buildAutocompleteField(
          label: 'From',
          hint: 'e.g. Mumbai',
          icon: Icons.trip_origin,
          iconColor: Colors.green,
          controller: _originCtrl,
          suggestions: _originSuggestions,
          showSuggestions: _showOriginSuggestions,
          onChanged: _onOriginChanged,
          onSuggestionTap: (s) {
            _originCtrl.text = s;
            setState(() => _showOriginSuggestions = false);
          },
        ),
        const SizedBox(height: 12),
        _buildAutocompleteField(
          label: 'To',
          hint: 'e.g. Pune',
          icon: Icons.place,
          iconColor: Colors.red,
          controller: _destCtrl,
          suggestions: _destSuggestions,
          showSuggestions: _showDestSuggestions,
          onChanged: _onDestChanged,
          onSuggestionTap: (s) {
            _destCtrl.text = s;
            setState(() => _showDestSuggestions = false);
          },
        ),
      ],
    );
  }

  Widget _buildAutocompleteField({
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required List<String> suggestions,
    required bool showSuggestions,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSuggestionTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: iconColor, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _purple),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
        if (showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (_, _x) =>
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (_, i) {
                final s = suggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined,
                      size: 18, color: Colors.grey),
                  title: Text(s,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  onTap: () => onSuggestionTap(s),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0A8FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car_filled, color: _purple, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehicle',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  _selectedVehicle.displayName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_selectedVehicle.averageMileageKmpl} kmpl · '
                  '${_selectedVehicle.fuelTankCapacityLiters.toStringAsFixed(0)}L tank',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          // Placeholder for vehicle selection – future story
          const Icon(Icons.chevron_right, color: Colors.black38),
        ],
      ),
    );
  }

  Widget _buildRouteTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Route Type',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Row(
          children: RouteType.values.map((type) {
            final selected = _selectedType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _purple : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _routeTypeEmoji(type),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _routeTypeShortLabel(type),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 13, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _planRoute,
        style: ElevatedButton.styleFrom(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _purple.withValues(alpha: 0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.route, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Plan My Route',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (Icons.local_gas_station, 'Fuel\nStations', false),
      (Icons.toll, 'Toll\nInfo', false),
      (Icons.restaurant, 'Food\nStops', false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  onPressed: null, // MVP – enabled in later stories
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Column(
                    children: [
                      Icon(a.$1, size: 22, color: Colors.black38),
                      const SizedBox(height: 6),
                      Text(
                        a.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _routeTypeEmoji(RouteType type) {
    switch (type) {
      case RouteType.fastest:
        return '⚡';
      case RouteType.shortest:
        return '📏';
      case RouteType.scenic:
        return '🌄';
      case RouteType.fuelEfficient:
        return '⛽';
    }
  }

  String _routeTypeShortLabel(RouteType type) {
    switch (type) {
      case RouteType.fastest:
        return 'Fastest';
      case RouteType.shortest:
        return 'Shortest';
      case RouteType.scenic:
        return 'Scenic';
      case RouteType.fuelEfficient:
        return 'Fuel\nEfficient';
    }
  }
}

// Made with Bob
