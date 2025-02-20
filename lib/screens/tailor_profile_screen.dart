// screens/tailor_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_screen.dart';

class TailorProfileScreen extends StatelessWidget {
  final String tailorId;

  const TailorProfileScreen({super.key, required this.tailorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tailor Profile')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('tailors').doc(tailorId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.data!.exists) {
            return const Center(child: Text('Tailor not found'));
          }
          final tailorData = snapshot.data!.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${tailorData['name']}', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Location: ${tailorData['location']}'),
                const SizedBox(height: 8),
                Text('Services: ${tailorData['services'].join(", ")}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(tailorName: 'Tailor Name'),
                      ),
                    );
                  },
                  child: const Text('Book Now'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}