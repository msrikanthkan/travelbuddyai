import 'package:flutter/material.dart';
import 'trip_planner_screen3.dart';

class TripPlannerScreen2 extends StatefulWidget {
  final String occasion;
  final int budget;
  final String destination;

  const TripPlannerScreen2({
    super.key,
    required this.occasion,
    required this.budget,
    required this.destination,
  });

  @override
  State<TripPlannerScreen2> createState() => _TripPlannerScreen2State();
}

class _TripPlannerScreen2State extends State<TripPlannerScreen2> {
  String? _selectedTravelType;
  String? _selectedTrainClass;

  final List<Map<String, dynamic>> _travelTypes = [
    {
      'value': 'road',
      'label': 'Road Trip',
      'icon': Icons.directions_car,
      'emoji': '🚗',
      'description': 'Flexible and scenic journey',
      'color': Color(0xFF4CAF50),
    },
    {
      'value': 'train',
      'label': 'Train',
      'icon': Icons.train,
      'emoji': '🚂',
      'description': 'Comfortable and economical',
      'color': Color(0xFF2196F3),
    },
    {
      'value': 'flight',
      'label': 'Flight',
      'icon': Icons.flight,
      'emoji': '✈️',
      'description': 'Fast and convenient',
      'color': Color(0xFFFF9800),
    },
    {
      'value': 'bus',
      'label': 'Bus',
      'icon': Icons.directions_bus,
      'emoji': '🚌',
      'description': 'Budget-friendly option',
      'color': Color(0xFF9C27B0),
    },
  ];

  final List<Map<String, String>> _trainClasses = [
    {'value': 'sleeper', 'label': 'Sleeper Class', 'emoji': '🛏️'},
    {'value': 'ac3tier', 'label': 'AC 3-Tier', 'emoji': '❄️'},
    {'value': 'ac2tier', 'label': 'AC 2-Tier', 'emoji': '❄️❄️'},
    {'value': 'ac1st', 'label': 'AC 1st Class', 'emoji': '⭐'},
  ];

  void _proceedToNextScreen() {
    if (_selectedTravelType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a travel type')),
      );
      return;
    }

    if (_selectedTravelType == 'train' && _selectedTrainClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select train class')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripPlannerScreen3(
          occasion: widget.occasion,
          budget: widget.budget,
          destination: widget.destination,
          travelType: _selectedTravelType!,
          trainClass: _selectedTrainClass,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Travel Type',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7F00FF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
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
                _buildStepLine(false),
                _buildStepIndicator(3, false),
                _buildStepLine(false),
                _buildStepIndicator(4, false),
              ],
            ),
            const SizedBox(height: 24),

            // Trip Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F00FF), Color(0xFFB400D9)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(Icons.event, 'Occasion', _formatOccasion(widget.occasion)),
                  _buildSummaryRow(Icons.currency_rupee, 'Budget', '₹${widget.budget}'),
                  if (widget.destination.isNotEmpty)
                    _buildSummaryRow(Icons.location_on, 'Destination', widget.destination),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Travel Type Selection
            const Text(
              'How would you like to travel?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Travel Type Cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _travelTypes.length,
              itemBuilder: (context, index) {
                final travelType = _travelTypes[index];
                final isSelected = _selectedTravelType == travelType['value'];
                return _buildTravelTypeCard(travelType, isSelected);
              },
            ),
            const SizedBox(height: 24),

            // Train Class Selection (if train is selected)
            if (_selectedTravelType == 'train') ...[
              const Divider(height: 32),
              const Text(
                'Select Train Class',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _trainClasses.length,
                itemBuilder: (context, index) {
                  final trainClass = _trainClasses[index];
                  final isSelected = _selectedTrainClass == trainClass['value'];
                  return _buildTrainClassCard(trainClass, isSelected);
                },
              ),
              const SizedBox(height: 24),
            ],

            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
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
                  child: ElevatedButton(
                    onPressed: _proceedToNextScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F00FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next: Travelers',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              ],
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

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelTypeCard(Map<String, dynamic> travelType, bool isSelected) {
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? travelType['color'] as Color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTravelType = travelType['value'] as String;
            if (_selectedTravelType != 'train') {
              _selectedTrainClass = null;
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                travelType['emoji'] as String,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(
                travelType['label'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? travelType['color'] as Color : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                travelType['description'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainClassCard(Map<String, String> trainClass, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTrainClass = trainClass['value'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                trainClass['emoji']!,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  trainClass['label']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF2196F3) : Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2196F3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatOccasion(String occasion) {
    return occasion[0].toUpperCase() + occasion.substring(1);
  }
}

// Made with Bob
