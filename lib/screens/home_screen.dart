import 'package:flutter/material.dart';

import '../services/ideas_service.dart';
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

  void _openFeatureDetail(BuildContext context, String title, List<String> points) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeatureDetailScreen(title: title, points: points),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TravelBuddyAI'),
        backgroundColor: const Color(0xFF7F00FF),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: travelIdeas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final idea = travelIdeas[index];
          final points = (idea['points'] as List<String>);
          final buttonColor = _buttonColors[index % _buttonColors.length];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idea['title'] as String,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: points
                        .map((point) => ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor.withOpacity(0.95),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _openFeatureDetail(context, idea['title'] as String, points),
                              child: Text(
                                point,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
