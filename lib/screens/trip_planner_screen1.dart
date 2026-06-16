import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../services/destinations_loader_service.dart';
import '../services/destination_insights_service.dart';
import '../services/places_service.dart';
import 'trip_planner_screen2.dart';

class TripPlannerScreen1 extends StatefulWidget {
  const TripPlannerScreen1({super.key});

  @override
  State<TripPlannerScreen1> createState() => _TripPlannerScreen1State();
}

class _TripPlannerScreen1State extends State<TripPlannerScreen1> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  final _destinationController = TextEditingController();

  String _selectedOccasion = 'casual';
  bool _hasDestinationInMind = false;
  bool _isLoadingSuggestions = false;
  bool _isLoadingInsights = false;
  bool _isSearchingDestination = false;
  List<Destination> _suggestedDestinations = [];
  int _displayedDestinationsCount = 5;
  List<DestinationInsight> _destinationInsights = [];
  List<String> _destinationSuggestions = [];
  Destination? _selectedDestination;
  final DestinationInsightsService _insightsService = DestinationInsightsService();
  DateTime? _lastDestinationQueryTime;

  final List<Map<String, dynamic>> _occasions = [
    {'value': 'casual', 'label': '🏖️ Casual Trip', 'icon': Icons.beach_access},
    {'value': 'wedding', 'label': '💒 Wedding', 'icon': Icons.favorite},
    {'value': 'devotional', 'label': '🙏 Devotional', 'icon': Icons.temple_hindu},
    {'value': 'adventure', 'label': '🏔️ Adventure', 'icon': Icons.terrain},
    {'value': 'birthday', 'label': '🎂 Birthday', 'icon': Icons.cake},
    {'value': 'cultural', 'label': '🎭 Cultural', 'icon': Icons.museum},
    {'value': 'honeymoon', 'label': '💑 Honeymoon', 'icon': Icons.favorite_border},
  ];

  @override
  void dispose() {
    _budgetController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadDestinationSuggestions() async {
    if (_budgetController.text.isEmpty) return;

    setState(() {
      _isLoadingSuggestions = true;
      _displayedDestinationsCount = 5;
    });

    try {
      final budget = int.parse(_budgetController.text);
      final destinations = await DestinationsLoaderService.getDestinationsByBudget(
        occasionType: _selectedOccasion,
        budgetAmount: budget,
      );

      setState(() {
        _suggestedDestinations = destinations;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suggestions: $e')),
        );
      }
    }
  }

  void _showMoreDestinations() {
    setState(() {
      _displayedDestinationsCount += 5;
    });
  }

  void _selectDestination(Destination destination) async {
    setState(() {
      _destinationController.text = destination.name;
      _hasDestinationInMind = true;
      _selectedDestination = destination;
      _isLoadingInsights = true;
    });
    
    // Load insights for selected destination
    await _loadDestinationInsights(destination.name);
  }

  Future<void> _searchDestination(String query) async {
    if (query.length < 2) {
      setState(() {
        _destinationSuggestions = [];
      });
      return;
    }

    final now = DateTime.now();
    setState(() {
      _lastDestinationQueryTime = now;
      _isSearchingDestination = true;
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

  Future<void> _loadDestinationInsights(String destination) async {
    try {
      final insights = await _insightsService.getDestinationInsights(destination);
      setState(() {
        _destinationInsights = insights;
        _isLoadingInsights = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingInsights = false;
      });
      print('Error loading insights: $e');
    }
  }

  void _proceedToNextScreen() {
    if (_formKey.currentState!.validate()) {
      final budget = int.parse(_budgetController.text);
      final destination = _hasDestinationInMind ? _destinationController.text : '';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripPlannerScreen2(
            occasion: _selectedOccasion,
            budget: budget,
            destination: destination,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedDestinations = _suggestedDestinations.take(_displayedDestinationsCount).toList();
    final hasMoreDestinations = _displayedDestinationsCount < _suggestedDestinations.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plan Your Trip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7F00FF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Row(
                children: [
                  _buildStepIndicator(1, true),
                  _buildStepLine(false),
                  _buildStepIndicator(2, false),
                  _buildStepLine(false),
                  _buildStepIndicator(3, false),
                  _buildStepLine(false),
                  _buildStepIndicator(4, false),
                ],
              ),
              const SizedBox(height: 24),

              // Occasion Selection
              const Text(
                'Select Occasion',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _occasions.map((occasion) {
                  final isSelected = _selectedOccasion == occasion['value'];
                  return ChoiceChip(
                    label: Text(occasion['label'] as String),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedOccasion = occasion['value'] as String;
                        _suggestedDestinations.clear();
                      });
                      if (_budgetController.text.isNotEmpty) {
                        _loadDestinationSuggestions();
                      }
                    },
                    selectedColor: const Color(0xFF7F00FF),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Budget Input
              const Text(
                'Enter Your Budget',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Budget (₹)',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g., 20000',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your budget';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.isNotEmpty && int.tryParse(value) != null) {
                    _loadDestinationSuggestions();
                  }
                },
              ),
              const SizedBox(height: 24),

              // Destination in Mind Question
              const Text(
                'Do you have a destination in mind?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasDestinationInMind = true;
                        });
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Yes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasDestinationInMind
                            ? const Color(0xFF7F00FF)
                            : Colors.grey[300],
                        foregroundColor: _hasDestinationInMind ? Colors.white : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasDestinationInMind = false;
                          _destinationController.clear();
                        });
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('No'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_hasDestinationInMind
                            ? const Color(0xFF7F00FF)
                            : Colors.grey[300],
                        foregroundColor: !_hasDestinationInMind ? Colors.white : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Destination Input (if Yes)
              if (_hasDestinationInMind) ...[
                TextFormField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: 'Destination',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: _isSearchingDestination
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'e.g., Goa, Manali',
                  ),
                  validator: (value) {
                    if (_hasDestinationInMind && (value == null || value.isEmpty)) {
                      return 'Please enter a destination';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _searchDestination(value);
                  },
                ),
                
                // Autocomplete suggestions
                if (_destinationSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _destinationSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _destinationSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, size: 20),
                          title: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            setState(() {
                              _destinationController.text = suggestion;
                              _destinationSuggestions = [];
                            });
                            _loadDestinationInsights(suggestion);
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                
                // Quick Insights for selected destination
                if (_selectedDestination != null) ...[
                  const Divider(height: 32),
                  Row(
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00B4DB),
                        ),
                      ),
                      const Spacer(),
                      if (_isLoadingInsights)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_destinationInsights.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _destinationInsights.length > 6 ? 6 : _destinationInsights.length,
                      itemBuilder: (context, index) {
                        final insight = _destinationInsights[index];
                        return _buildInsightCard(insight);
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ],

              // Destination Suggestions (if No)
              if (!_hasDestinationInMind && _budgetController.text.isNotEmpty) ...[
                const Divider(height: 32),
                Row(
                  children: [
                    const Text(
                      'Suggested Destinations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (_isLoadingSuggestions)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_suggestedDestinations.isEmpty && !_isLoadingSuggestions)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No destinations found for your budget and occasion. Try adjusting your budget.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (displayedDestinations.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedDestinations.length,
                    itemBuilder: (context, index) {
                      final destination = displayedDestinations[index];
                      return _buildDestinationCard(destination);
                    },
                  ),

                if (hasMoreDestinations) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _showMoreDestinations,
                      icon: const Icon(Icons.expand_more),
                      label: Text(
                        'Show More (${_suggestedDestinations.length - _displayedDestinationsCount} more)',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7F00FF),
                        side: const BorderSide(color: Color(0xFF7F00FF)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // Next Button
              SizedBox(
                width: double.infinity,
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
                        'Next: Travel Type',
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

  Widget _buildDestinationCard(Destination destination) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _selectDestination(destination),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7F00FF), Color(0xFFB400D9)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_city, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.state,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          destination.rating.toString(),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          destination.formattedCost,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7F00FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(DestinationInsight insight) {
    // Modern color schemes for different insight types
    final colorSchemes = {
      'weather': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      'hotels': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      'temperature': [const Color(0xFFfa709a), const Color(0xFFfee140)],
      'tour_package': [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      'distance': [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      'popular_times': [const Color(0xFFfa709a), const Color(0xFFfee140)],
      'transport': [const Color(0xFF30cfd0), const Color(0xFF330867)],
      'food': [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
    };

    final colors = colorSchemes[insight.type] ?? [const Color(0xFF667EEA), const Color(0xFF764BA2)];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Gradient background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      insight.icon ?? '📍',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const Spacer(),
                  // Subtitle
                  Text(
                    insight.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Value
                  if (insight.value != null)
                    Text(
                      insight.value!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Made with Bob
