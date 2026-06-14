import 'package:flutter/material.dart';
import '../models/saved_trip_model.dart';
import '../services/saved_trips_service.dart';
import 'trip_planner_screen4.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SavedTrip> _allTrips = [];
  List<SavedTrip> _upcomingTrips = [];
  List<SavedTrip> _pastTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    
    final all = await SavedTripsService.getAllTrips();
    final upcoming = await SavedTripsService.getUpcomingTrips();
    final past = await SavedTripsService.getPastTrips();
    
    setState(() {
      _allTrips = all;
      _upcomingTrips = upcoming;
      _pastTrips = past;
      _isLoading = false;
    });
  }

  Future<void> _deleteTrip(SavedTrip trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Are you sure you want to delete "${trip.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await SavedTripsService.deleteTrip(trip.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip deleted successfully')),
        );
        _loadTrips();
      }
    }
  }

  void _viewTripDetails(SavedTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripPlannerScreen4(
          occasion: trip.occasion,
          budget: trip.budget,
          destination: trip.destination,
          travelType: trip.travelType,
          trainClass: trip.trainClass,
          adults: trip.adults,
          children: trip.children,
          infants: trip.infants,
          tripDays: trip.tripDays,
          startDate: trip.startDate,
          endDate: trip.endDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Trips',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7F00FF),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'All (${_allTrips.length})'),
            Tab(text: 'Upcoming (${_upcomingTrips.length})'),
            Tab(text: 'Past (${_pastTrips.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTripsList(_allTrips, 'No trips saved yet'),
                _buildTripsList(_upcomingTrips, 'No upcoming trips'),
                _buildTripsList(_pastTrips, 'No past trips'),
              ],
            ),
    );
  }

  Widget _buildTripsList(List<SavedTrip> trips, String emptyMessage) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.luggage, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start planning your next adventure!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(trip);
        },
      ),
    );
  }

  Widget _buildTripCard(SavedTrip trip) {
    final occasionEmojis = {
      'casual': '🏖️',
      'wedding': '💒',
      'devotional': '🙏',
      'adventure': '🏔️',
      'birthday': '🎂',
      'cultural': '🎭',
      'honeymoon': '💑',
    };

    final travelEmojis = {
      'road': '🚗',
      'train': '🚂',
      'flight': '✈️',
      'bus': '🚌',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _viewTripDetails(trip),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F00FF), Color(0xFFB400D9)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              trip.destination,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () => _deleteTrip(trip),
                  ),
                ],
              ),
            ),
            
            // Trip details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          '${occasionEmojis[trip.occasion] ?? '🎯'} ${_formatOccasion(trip.occasion)}',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          '${travelEmojis[trip.travelType] ?? '🚀'} ${_formatTravelType(trip.travelType)}',
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailItem(Icons.people, '${trip.totalTravelers} travelers'),
                      _buildDetailItem(Icons.calendar_today, '${trip.tripDays} days'),
                      _buildDetailItem(Icons.currency_rupee, trip.formattedBudget),
                    ],
                  ),
                  if (trip.startDate != null && trip.endDate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, color: Color(0xFF2196F3), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              trip.dateRange,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }

  String _formatOccasion(String occasion) {
    return occasion[0].toUpperCase() + occasion.substring(1);
  }

  String _formatTravelType(String travelType) {
    return travelType[0].toUpperCase() + travelType.substring(1);
  }
}

// Made with Bob
