import 'package:flutter/material.dart';

import '../models/models.dart';

class BudgetSummaryScreen extends StatelessWidget {
  final Budget budget;
  final String destination;
  final int days;
  final int familySize;
  final String hotelCategory;

  const BudgetSummaryScreen({
    super.key,
    required this.budget,
    required this.destination,
    required this.days,
    required this.familySize,
    required this.hotelCategory,
  });

  @override
  Widget build(BuildContext context) {
    final breakdown = budget.toJson();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Summary'),
        backgroundColor: const Color(0xFF7F00FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip: ${destination.isEmpty ? 'Unnamed trip' : destination}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Days: $days • Family size: $familySize', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Hotel class: ${hotelCategory.capitalize()}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            Text(
              'Total estimated cost: ₹${budget.totalCost.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildSummaryRow('Fuel', budget.fuelCost),
                  _buildSummaryRow('Hotel', budget.hotelCost),
                  _buildSummaryRow('Food', budget.foodCost),
                  _buildSummaryRow('Tolls', budget.tollCharges),
                  _buildSummaryRow('Attractions', budget.attractionCost),
                  _buildSummaryRow('Misc', budget.miscellaneousCost),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F00FF),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Back to Home', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text('₹${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return substring(0, 1).toUpperCase() + substring(1);
  }
}
