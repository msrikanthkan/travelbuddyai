import 'package:flutter/material.dart';

import 'bargain_assistant_form_screen.dart';

class BargainAssistantScreen extends StatelessWidget {
  const BargainAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Bargain Assistant'),
        backgroundColor: const Color(0xFF00B4DB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get local rate estimates and negotiation tips.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('• Local taxi fare estimate for nearby routes', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text('• Auto fare estimate in your destination', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text('• Smart negotiation phrases to lower prices', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Card(
              color: Color(0xFF00B4DB),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Expected fare for airport to hotel: ₹350-₹450\nIf driver asks more, say: "Please keep it close to the local rate."',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4DB),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BargainAssistantFormScreen()),
                );
              },
              child: const Text('Start Bargain Assistant', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
