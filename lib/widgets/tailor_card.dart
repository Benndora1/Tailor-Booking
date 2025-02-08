// widgets/tailor_card.dart
import 'package:flutter/material.dart';
import '../screens/booking_screen.dart';

class TailorCard extends StatelessWidget {
  final String name;
  final String location;
  final List<String> services;

  const TailorCard({
    super.key,
    required this.name,
    required this.location,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: $location'),
            const SizedBox(height: 4),
            Text('Services: ${services.join(", ")}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // Navigate to booking screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingScreen(tailorName: name),
              ),
            );
          },
          child: const Text('Book Now'),
        ),
      ),
    );
  }
}