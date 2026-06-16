import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/itinerary_day_model.dart';
import '../services/itinerary_generator_service.dart';
import '../services/share_service.dart';

class DetailedItineraryScreen extends StatefulWidget {
  final String destination;
  final String occasion;
  final int tripDays;
  final int budget;
  final int totalTravelers;
  final DateTime? startDate;

  const DetailedItineraryScreen({
    super.key,
    required this.destination,
    required this.occasion,
    required this.tripDays,
    required this.budget,
    required this.totalTravelers,
    this.startDate,
  });

  @override
  State<DetailedItineraryScreen> createState() => _DetailedItineraryScreenState();
}

class _DetailedItineraryScreenState extends State<DetailedItineraryScreen> {
  late Future<List<ItineraryDay>> _itineraryFuture;
  int _selectedDayIndex = 0;
  int _visibleHotelsCount = 3; // Show 3 hotels initially

  @override
  void initState() {
    super.initState();
    _itineraryFuture = ItineraryGeneratorService.generateItinerary(
      destination: widget.destination,
      occasion: widget.occasion,
      tripDays: widget.tripDays,
      budget: widget.budget,
      totalTravelers: widget.totalTravelers,
    );
  }

  void _loadMoreHotels() {
    setState(() {
      _visibleHotelsCount += 5; // Load 5 more hotels
    });
  }

  void _showLessHotels() {
    setState(() {
      _visibleHotelsCount = 3; // Reset to initial 3
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ItineraryDay>>(
      future: _itineraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Detailed Itinerary',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF7F00FF),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7F00FF)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading real hotel data...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Detailed Itinerary',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF7F00FF),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading itinerary: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        final itinerary = snapshot.data!;
        final selectedDay = itinerary[_selectedDayIndex];
        final totalCost = itinerary.fold<double>(0, (sum, day) => sum + day.estimatedCost);

        return _buildItineraryContent(context, itinerary, selectedDay, totalCost);
      },
    );
  }

  Widget _buildItineraryContent(
    BuildContext context,
    List<ItineraryDay> itinerary,
    ItineraryDay selectedDay,
    double totalCost,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detailed Itinerary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7F00FF),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share),
            onSelected: (value) async {
              if (value == 'full') {
                await ShareService.shareDetailedItinerary(
                  destination: widget.destination,
                  occasion: widget.occasion,
                  tripDays: widget.tripDays,
                  budget: widget.budget,
                  totalTravelers: widget.totalTravelers,
                  itinerary: itinerary,
                  startDate: widget.startDate,
                );
              } else if (value == 'day') {
                await ShareService.shareDayItinerary(
                  destination: widget.destination,
                  day: itinerary[_selectedDayIndex],
                  date: widget.startDate?.add(Duration(days: _selectedDayIndex)),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'full',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month, size: 20),
                    SizedBox(width: 12),
                    Text('Share Full Itinerary'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'day',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 12),
                    Text('Share Current Day'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Trip Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7F00FF), Color(0xFFB400D9)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.destination,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildHeaderInfo(Icons.calendar_today, '${widget.tripDays} Days'),
                    const SizedBox(width: 16),
                    _buildHeaderInfo(Icons.people, '${widget.totalTravelers} Travelers'),
                    const SizedBox(width: 16),
                    _buildHeaderInfo(Icons.currency_rupee, '₹${totalCost.toStringAsFixed(0)}'),
                  ],
                ),
              ],
            ),
          ),

          // Day Selector
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: itinerary.length,
              itemBuilder: (context, index) {
                final day = itinerary[index];
                final isSelected = index == _selectedDayIndex;
                final date = widget.startDate?.add(Duration(days: index));
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = index),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF7F00FF), Color(0xFFB400D9)],
                            )
                          : null,
                      color: isSelected ? null : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF7F00FF) : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Day ${day.dayNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (date != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Day Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Title
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
                          'Day ${selectedDay.dayNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedDay.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Est. Cost: ${selectedDay.formattedCost}',
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

                  // Activities
                  const Text(
                    'Activities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...selectedDay.activities.map((activity) => _buildActivityCard(activity)),

                  const SizedBox(height: 24),

                  // Meals
                  const Text(
                    'Meals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...selectedDay.meals.map((meal) => _buildMealCard(meal)),

                  const SizedBox(height: 24),

                  // Accommodation Options
                  if (selectedDay.availableAccommodations.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Accommodation Options',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${selectedDay.availableAccommodations.length} hotels',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Show visible hotels
                    ...selectedDay.availableAccommodations
                        .take(_visibleHotelsCount)
                        .map((accommodation) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildAccommodationCard(accommodation),
                            )),
                    
                    // Load More / Show Less buttons
                    if (selectedDay.availableAccommodations.length > 3) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: _visibleHotelsCount < selectedDay.availableAccommodations.length
                            ? OutlinedButton.icon(
                                onPressed: _loadMoreHotels,
                                icon: const Icon(Icons.expand_more),
                                label: Text(
                                  'Load More (${selectedDay.availableAccommodations.length - _visibleHotelsCount} more)',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF7F00FF),
                                  side: const BorderSide(color: Color(0xFF7F00FF)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: _showLessHotels,
                                icon: const Icon(Icons.expand_less),
                                label: const Text('Show Less'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF7F00FF),
                                  side: const BorderSide(color: Color(0xFF7F00FF)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                      ),
                    ],
                  ] else if (selectedDay.accommodation != null) ...[
                    // Fallback: show single accommodation if availableAccommodations is empty
                    const Text(
                      'Accommodation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildAccommodationCard(selectedDay.accommodation!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7F00FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                activity.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: activity.cost > 0 ? Colors.green[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity.formattedCost,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: activity.cost > 0 ? Colors.green[700] : Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.time} • ${activity.duration}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  if (activity.location != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          activity.location!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
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

  Widget _buildMealCard(Meal meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                meal.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meal.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        meal.formattedCost,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${meal.type.toUpperCase()} • ${meal.time}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  if (meal.restaurant != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.restaurant, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          meal.restaurant!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
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

  Widget _buildAccommodationCard(Accommodation accommodation) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: accommodation.bookingUrl != null
            ? () => _launchBookingUrl(accommodation.bookingUrl!)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hotel,
                  size: 32,
                  color: Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            accommodation.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (accommodation.bookingUrl != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7F00FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Book Now',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7F00FF),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.open_in_new,
                                  size: 12,
                                  color: Color(0xFF7F00FF),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accommodation.type,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < accommodation.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          accommodation.rating.toString(),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (accommodation.address != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              accommodation.address!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    accommodation.formattedCost,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7F00FF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchBookingUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open booking website'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening booking website: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Made with Bob
