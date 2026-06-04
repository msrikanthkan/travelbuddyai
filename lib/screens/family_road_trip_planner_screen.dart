import 'package:flutter/material.dart';

import 'family_road_trip_form_screen.dart';

class FamilyRoadTripPlannerScreen extends StatelessWidget {
  const FamilyRoadTripPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Road Trip Planner'),
        backgroundColor: const Color(0xFF00C853),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Family-friendly stops for your road trip.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('• Clean restrooms along the route', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text('• Kids play areas near highways', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text('• Good restaurants and petrol pumps', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Card(
              color: Color(0xFF00C853),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Route suggestion: stop every 2 hours for snacks and rest. Save a list of family-friendly places to visit.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FamilyRoadTripFormScreen()),
                );
              },
              child: const Text('Plan Your Family Trip', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
