import 'package:flutter/material.dart';

import '../services/ideas_service.dart';
import 'bargain_assistant_screen.dart';
import 'budget_planner_form.dart';
import 'family_road_trip_planner_screen.dart';
import 'feature_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _buttonColors = [
    Color(0xFF7F00FF),
    Color(0xFF00B4DB),
    Color(0xFFFF7F50),
    Color(0xFF00C853),
    Color(0xFFD500F9),
  ];

  void _openFeatureDetail(BuildContext context, String id, String title, List<String> points) {
    if (id == '1') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BudgetPlannerForm()),
      );
      return;
    }
    if (id == '2') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BargainAssistantScreen()),
      );
      return;
    }
    if (id == '3') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FamilyRoadTripPlannerScreen()),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeatureDetailScreen(title: title, points: points),
      ),
    );
  }

  IconData _getIconForId(String id) {
    switch (id) {
      case '1':
        return Icons.attach_money;
      case '2':
        return Icons.local_taxi;
      case '3':
        return Icons.family_restroom;
      case '4':
        return Icons.warning_amber;
      case '5':
        return Icons.route;
      case '6':
        return Icons.security;
      case '7':
        return Icons.translate;
      case '8':
        return Icons.restaurant;
      case '9':
        return Icons.directions_car;
      case '10':
        return Icons.local_hospital;
      default:
        return Icons.trip_origin;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TravelBuddyAI'),
        backgroundColor: const Color(0xFF7F00FF),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: travelIdeas.length,
        itemBuilder: (context, index) {
          final idea = travelIdeas[index];
          final id = idea['id'] as String;
          final points = (idea['points'] as List<String>);
          final buttonColor = _buttonColors[index % _buttonColors.length];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openFeatureDetail(context, id, idea['title'] as String, points),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: buttonColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForId(id),
                        color: buttonColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            idea['title'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              points.join(' • '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: buttonColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Explore',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: buttonColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
