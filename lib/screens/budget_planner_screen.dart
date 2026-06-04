import 'package:flutter/material.dart';

import 'budget_planner_form.dart';

class BudgetPlannerScreen extends StatelessWidget {
  const BudgetPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Travel Budget Planner'),
        backgroundColor: const Color(0xFF7F00FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan your family trip budget quickly.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter your destination, number of days, family size, and hotel class. We will estimate fuel, food, hotel, tolls, and attraction costs.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F00FF),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BudgetPlannerForm()),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Start Budget Planner', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
