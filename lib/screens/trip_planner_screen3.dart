import 'package:flutter/material.dart';
import 'trip_planner_screen4.dart';

class TripPlannerScreen3 extends StatefulWidget {
  final String occasion;
  final int budget;
  final String destination;
  final String travelType;
  final String? trainClass;

  const TripPlannerScreen3({
    super.key,
    required this.occasion,
    required this.budget,
    required this.destination,
    required this.travelType,
    this.trainClass,
  });

  @override
  State<TripPlannerScreen3> createState() => _TripPlannerScreen3State();
}

class _TripPlannerScreen3State extends State<TripPlannerScreen3> {
  int _adults = 2;
  int _children = 0;
  int _infants = 0;
  int _tripDays = 3;
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7F00FF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Auto-calculate end date based on trip days
        _endDate = picked.add(Duration(days: _tripDays - 1));
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date first')),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(Duration(days: _tripDays - 1)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7F00FF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        // Update trip days based on date range
        _tripDays = _endDate!.difference(_startDate!).inDays + 1;
      });
    }
  }

  void _proceedToNextScreen() {
    if (_adults == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one adult is required')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripPlannerScreen4(
          occasion: widget.occasion,
          budget: widget.budget,
          destination: widget.destination,
          travelType: widget.travelType,
          trainClass: widget.trainClass,
          adults: _adults,
          children: _children,
          infants: _infants,
          tripDays: _tripDays,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalTravelers = _adults + _children + _infants;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Number of Travelers',
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
                _buildStepLine(true),
                _buildStepIndicator(3, true),
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
                  _buildSummaryRow(Icons.directions, 'Travel', _formatTravelType(widget.travelType)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Total Travelers Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFF2196F3), size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Travelers',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '$totalTravelers ${totalTravelers == 1 ? 'Person' : 'People'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Travelers Selection
            const Text(
              'Select Number of Travelers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Adults
            _buildTravelerCounter(
              icon: Icons.person,
              emoji: '👨',
              label: 'Adults',
              subtitle: 'Age 12+',
              count: _adults,
              onIncrement: () => setState(() => _adults++),
              onDecrement: () {
                if (_adults > 0) setState(() => _adults--);
              },
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 12),

            // Children
            _buildTravelerCounter(
              icon: Icons.child_care,
              emoji: '👦',
              label: 'Children',
              subtitle: 'Age 2-11',
              count: _children,
              onIncrement: () => setState(() => _children++),
              onDecrement: () {
                if (_children > 0) setState(() => _children--);
              },
              color: const Color(0xFF2196F3),
            ),
            const SizedBox(height: 12),

            // Infants
            _buildTravelerCounter(
              icon: Icons.baby_changing_station,
              emoji: '👶',
              label: 'Infants',
              subtitle: 'Under 2',
              count: _infants,
              onIncrement: () => setState(() => _infants++),
              onDecrement: () {
                if (_infants > 0) setState(() => _infants--);
              },
              color: const Color(0xFFFF9800),
            ),
            const SizedBox(height: 24),

            const Divider(height: 32),

            // Travel Dates
            const Text(
              'Travel Dates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Color(0xFF2196F3), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _startDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                : 'Select Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _startDate != null ? const Color(0xFF2196F3) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event, color: Color(0xFF4CAF50), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'Select Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _endDate != null ? const Color(0xFF4CAF50) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Divider(height: 32),

            // Trip Duration
            const Text(
              'Trip Duration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF7F00FF)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Number of Days',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$_tripDays ${_tripDays == 1 ? 'Day' : 'Days'}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7F00FF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_tripDays > 1) setState(() => _tripDays--);
                            },
                            icon: const Icon(Icons.remove_circle),
                            color: const Color(0xFF7F00FF),
                            iconSize: 32,
                          ),
                          IconButton(
                            onPressed: () => setState(() => _tripDays++),
                            icon: const Icon(Icons.add_circle),
                            color: const Color(0xFF7F00FF),
                            iconSize: 32,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _tripDays.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    activeColor: const Color(0xFF7F00FF),
                    label: '$_tripDays days',
                    onChanged: (value) {
                      setState(() => _tripDays = value.toInt());
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Per Person Budget Info
            if (totalTravelers > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Budget per person',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          Text(
                            '₹${(widget.budget / totalTravelers).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

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
                          'View Summary',
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelerCounter({
    required IconData icon,
    required String emoji,
    required String label,
    required String subtitle,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: onDecrement,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: color,
                  iconSize: 28,
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add_circle),
                  color: color,
                  iconSize: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatOccasion(String occasion) {
    return occasion[0].toUpperCase() + occasion.substring(1);
  }

  String _formatTravelType(String travelType) {
    final formatted = travelType[0].toUpperCase() + travelType.substring(1);
    if (widget.trainClass != null) {
      return '$formatted (${widget.trainClass})';
    }
    return formatted;
  }
}

// Made with Bob
