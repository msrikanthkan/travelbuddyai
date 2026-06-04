import 'package:flutter/material.dart';

class FamilyRoadTripFormScreen extends StatefulWidget {
  const FamilyRoadTripFormScreen({super.key});

  @override
  State<FamilyRoadTripFormScreen> createState() => _FamilyRoadTripFormScreenState();
}

class _FamilyRoadTripFormScreenState extends State<FamilyRoadTripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeController = TextEditingController();
  final _distanceController = TextEditingController();
  final _childrenCountController = TextEditingController(text: '2');
  bool _needRestrooms = true;
  bool _needPlayAreas = true;
  bool _needGoodFood = true;

  @override
  void dispose() {
    _routeController.dispose();
    _distanceController.dispose();
    _childrenCountController.dispose();
    super.dispose();
  }

  void _generatePlan() {
    final distance = double.tryParse(_distanceController.text) ?? 0;
    final childrenCount = int.tryParse(_childrenCountController.text) ?? 2;

    final stopFrequency = (distance / 100).ceil();
    final suggestions = <String>[];

    if (_needRestrooms) {
      suggestions.add('🚻 Stop every 100 km for clean restroom breaks');
    }
    if (_needPlayAreas) {
      suggestions.add('🎪 Look for roadside play areas or small parks');
    }
    if (_needGoodFood) {
      suggestions.add('🍽️ Quality restaurants near highway (avoid street food for kids)');
    }

    final message = '''
Family Road Trip Plan for ${_routeController.text}

Distance: ${distance.toStringAsFixed(0)} km
Children: $childrenCount

Suggested stops: $stopFrequency

${suggestions.join('\n')}

💡 Tip: Pack snacks, water, and entertainment for kids.
''';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Your Road Trip Plan'),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Road Trip Planner'),
        backgroundColor: const Color(0xFF00C853),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _routeController,
                decoration: const InputDecoration(labelText: 'Route (e.g., Vizag to Tirupati)'),
                validator: (value) => value == null || value.isEmpty ? 'Enter route' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total distance (km)'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter distance';
                  if (double.tryParse(value) == null) return 'Enter valid distance';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _childrenCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Number of children'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter count';
                  if (int.tryParse(value) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text('Need clean restrooms'),
                value: _needRestrooms,
                onChanged: (value) {
                  setState(() => _needRestrooms = value ?? false);
                },
              ),
              CheckboxListTile(
                title: const Text('Kids play areas'),
                value: _needPlayAreas,
                onChanged: (value) {
                  setState(() => _needPlayAreas = value ?? false);
                },
              ),
              CheckboxListTile(
                title: const Text('Good restaurants'),
                value: _needGoodFood,
                onChanged: (value) {
                  setState(() => _needGoodFood = value ?? false);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _generatePlan();
                  }
                },
                child: const Text('Generate Plan', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
