import 'package:flutter/material.dart';
import '../models/saved_trip_model.dart';
import '../services/saved_trips_service.dart';
import '../services/share_service.dart';
import 'my_trips_screen.dart';
import 'detailed_itinerary_screen.dart';

class TripPlannerScreen4 extends StatelessWidget {
  final String occasion;
  final int budget;
  final String destination;
  final String travelType;
  final String? trainClass;
  final int adults;
  final int children;
  final int infants;
  final int tripDays;
  final DateTime? startDate;
  final DateTime? endDate;

  const TripPlannerScreen4({
    super.key,
    required this.occasion,
    required this.budget,
    required this.destination,
    required this.travelType,
    this.trainClass,
    required this.adults,
    required this.children,
    required this.infants,
    required this.tripDays,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final totalTravelers = adults + children + infants;
    final perPersonBudget = (budget / totalTravelers).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trip Summary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7F00FF),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await ShareService.shareTripSummary(
                destination: destination,
                occasion: occasion,
                budget: budget,
                travelType: travelType,
                trainClass: trainClass,
                adults: adults,
                children: children,
                infants: infants,
                tripDays: tripDays,
                startDate: startDate,
                endDate: endDate,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Success Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7F00FF), Color(0xFFB400D9)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Trip Plan Ready!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your ${_formatOccasion(occasion)} trip is all set',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  Row(
                    children: [
                      _buildStepIndicator(1, true),
                      _buildStepLine(true),
                      _buildStepIndicator(2, true),
                      _buildStepLine(true),
                      _buildStepIndicator(3, true),
                      _buildStepLine(true),
                      _buildStepIndicator(4, true),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Destination Card
                  if (destination.isNotEmpty) ...[
                    _buildSectionCard(
                      icon: Icons.location_on,
                      title: 'Destination',
                      color: const Color(0xFFFF5722),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Text(
                              _formatOccasion(occasion),
                              style: const TextStyle(
                                color: Color(0xFFFF5722),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Budget Card
                  _buildSectionCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Budget Details',
                    color: const Color(0xFF4CAF50),
                    child: Column(
                      children: [
                        _buildDetailRow('Total Budget', '₹$budget', isBold: true),
                        const Divider(height: 20),
                        _buildDetailRow('Per Person', '₹$perPersonBudget'),
                        _buildDetailRow('Trip Duration', '$tripDays ${tripDays == 1 ? 'Day' : 'Days'}'),
                        if (startDate != null && endDate != null) ...[
                          _buildDetailRow(
                            'Travel Dates',
                            '${startDate!.day}/${startDate!.month}/${startDate!.year} - ${endDate!.day}/${endDate!.month}/${endDate!.year}',
                          ),
                        ],
                        _buildDetailRow('Per Day (Total)', '₹${(budget / tripDays).toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Travel Details Card
                  _buildSectionCard(
                    icon: Icons.directions,
                    title: 'Travel Details',
                    color: const Color(0xFF2196F3),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Travel Mode',
                          _formatTravelType(travelType),
                          isBold: true,
                        ),
                        if (trainClass != null) ...[
                          const Divider(height: 20),
                          _buildDetailRow('Train Class', _formatTrainClass(trainClass!)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Travelers Card
                  _buildSectionCard(
                    icon: Icons.people,
                    title: 'Travelers',
                    color: const Color(0xFF9C27B0),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Total Travelers',
                          '$totalTravelers ${totalTravelers == 1 ? 'Person' : 'People'}',
                          isBold: true,
                        ),
                        const Divider(height: 20),
                        if (adults > 0) _buildDetailRow('Adults', '$adults', icon: '👨'),
                        if (children > 0) _buildDetailRow('Children', '$children', icon: '👦'),
                        if (infants > 0) _buildDetailRow('Infants', '$infants', icon: '👶'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Tips Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: Color(0xFF2196F3)),
                            SizedBox(width: 8),
                            Text(
                              'Quick Tips',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTipItem('Book accommodations in advance for better deals'),
                        _buildTipItem('Check weather forecast before packing'),
                        _buildTipItem('Keep emergency contacts handy'),
                        _buildTipItem('Carry necessary medications and first-aid'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Go back to home
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(Icons.home),
                          label: const Text('Home'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7F00FF),
                            side: const BorderSide(color: Color(0xFF7F00FF)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _saveTripDialog(context),
                          icon: const Icon(Icons.save),
                          label: const Text('Save Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7F00FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailedItineraryScreen(
                              destination: destination,
                              occasion: occasion,
                              tripDays: tripDays,
                              budget: budget,
                              totalTravelers: adults + children + infants,
                              startDate: startDate,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('View Detailed Itinerary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF7F00FF) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? const Color(0xFF7F00FF) : Colors.grey[300],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, String? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? Colors.black87 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF2196F3)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatOccasion(String occasion) {
    return occasion[0].toUpperCase() + occasion.substring(1);
  }

  String _formatTravelType(String travelType) {
    return travelType[0].toUpperCase() + travelType.substring(1);
  }

  String _formatTrainClass(String trainClass) {
    final Map<String, String> classNames = {
      'sleeper': 'Sleeper Class',
      'ac3tier': 'AC 3-Tier',
      'ac2tier': 'AC 2-Tier',
      'ac1st': 'AC 1st Class',
    };
    return classNames[trainClass] ?? trainClass;
  }

  void _saveTripDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(
      text: destination.isNotEmpty ? '$destination Trip' : 'My Trip',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Trip Name',
                hintText: 'e.g., Goa Summer Vacation',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'This trip will be saved on your device and can be accessed anytime from "My Trips".',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final tripName = nameController.text.trim();
              if (tripName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a trip name')),
                );
                return;
              }

              // Create SavedTrip object
              final savedTrip = SavedTrip(
                id: SavedTripsService.generateTripId(),
                name: tripName,
                destination: destination,
                occasion: occasion,
                budget: budget,
                travelType: travelType,
                trainClass: trainClass,
                adults: adults,
                children: children,
                infants: infants,
                tripDays: tripDays,
                startDate: startDate,
                endDate: endDate,
                createdAt: DateTime.now(),
              );

              // Save trip
              final success = await SavedTripsService.saveTrip(savedTrip);
              
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Trip saved'),
                        ],
                      ),
                      backgroundColor: Color(0xFF4CAF50),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                      margin: EdgeInsets.only(
                        bottom: 80,
                        left: 16,
                        right: 16,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save trip. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F00FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Made with Bob
